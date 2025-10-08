-- Remove duplicate activities from activities table
-- Keep only one record per unique title
-- This script must be run as a single transaction in Supabase SQL editor

DO $$
DECLARE
    v_deleted_count INTEGER;
    v_updated_sv_count INTEGER;
    v_updated_acl_count INTEGER;
BEGIN
    -- Create temp table with IDs to keep (oldest per title)
    CREATE TEMP TABLE activities_to_keep AS
    SELECT DISTINCT ON (title)
        id as keeper_id,
        title
    FROM activities
    ORDER BY title, created_at ASC;

    -- Create temp table with IDs to delete
    CREATE TEMP TABLE activities_to_delete AS
    SELECT a.id as delete_id, a.title, atk.keeper_id
    FROM activities a
    JOIN activities_to_keep atk ON a.title = atk.title
    WHERE a.id != atk.keeper_id;

    -- Show what will be deleted
    RAISE NOTICE 'Found % duplicate activities to delete', (SELECT COUNT(*) FROM activities_to_delete);

    -- Update foreign key references in scheduled_visits
    UPDATE scheduled_visits sv
    SET activity_id = atd.keeper_id
    FROM activities_to_delete atd
    WHERE sv.activity_id = atd.delete_id;

    GET DIAGNOSTICS v_updated_sv_count = ROW_COUNT;
    RAISE NOTICE 'Updated % scheduled_visits references', v_updated_sv_count;

    -- Update foreign key references in activity_category_links
    UPDATE activity_category_links acl
    SET activity_id = atd.keeper_id
    FROM activities_to_delete atd
    WHERE acl.activity_id = atd.delete_id;

    GET DIAGNOSTICS v_updated_acl_count = ROW_COUNT;
    RAISE NOTICE 'Updated % activity_category_links references', v_updated_acl_count;

    -- Delete duplicate activities
    DELETE FROM activities
    WHERE id IN (SELECT delete_id FROM activities_to_delete);

    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    RAISE NOTICE 'Deleted % duplicate activities', v_deleted_count;

    -- Clean up temp tables
    DROP TABLE IF EXISTS activities_to_keep;
    DROP TABLE IF EXISTS activities_to_delete;

    RAISE NOTICE 'Cleanup complete!';
END $$;

-- Verify - should show no duplicates
SELECT
    title,
    COUNT(*) as count
FROM activities
GROUP BY title
HAVING COUNT(*) > 1;

-- Show final count
SELECT COUNT(*) as total_activities FROM activities;
