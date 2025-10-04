# Development Principles for GUIDAL

## Database-First Approach

**NEVER hardcode data in JavaScript when it could best be added to the database, even if a minor schema extension is necessary.**

### Why?
- **Maintainability**: Database changes don't require code deployment
- **Consistency**: Single source of truth for data
- **Scalability**: Easier to manage as data grows
- **Flexibility**: Non-developers can update data via database UI
- **Best Practice**: Separation of data from logic

### Examples

❌ **Bad - Hardcoded in JavaScript:**
```javascript
const imageMappings = {
  'Workshop Name': 'images/workshop.png',
  'Another Workshop': 'images/another.png'
}
```

✅ **Good - Stored in Database:**
```sql
ALTER TABLE scheduled_visits
ADD COLUMN featured_image TEXT;

UPDATE scheduled_visits
SET featured_image = 'images/workshop.png'
WHERE title = 'Workshop Name';
```

### When to Use Database vs. Code

**Use Database for:**
- Content (titles, descriptions, images)
- Configuration (prices, limits, settings)
- Relationships between entities
- Data that changes over time
- Data that non-developers need to update

**Use Code for:**
- Business logic
- Data transformations
- UI behavior
- Validation rules
- Constants that truly never change (e.g., colors in a theme)

### GUIDAL-Specific Guidelines

1. **Activities & Events**: All content should be in `activities` or `scheduled_visits` tables
2. **Images**: Use `featured_image` column, not JavaScript mappings
3. **Pricing**: Store in database, not hardcoded
4. **Configuration**: Create config tables if needed (e.g., `site_settings`)
5. **Schema Changes**: Don't be afraid to add columns - it's better than hardcoding

---
*This document serves as a reminder to always consider the database-first approach when adding new features or fixing issues.*
