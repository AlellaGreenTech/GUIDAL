# Troubleshooting Pumpkin Patch Order Not Saving

## Steps to diagnose the issue:

### 1. Check if the database schema was created
Run this query in Supabase SQL Editor:
```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name LIKE 'pumpkin%';
```

**Expected result:** Should show `pumpkin_patch_orders` and `pumpkin_patch_order_items`

**If empty:** You need to run the schema file first!
- Open `/database/pumpkin-patch-orders-schema.sql`
- Copy all the SQL
- Paste into Supabase SQL Editor
- Click "Run"

### 2. Check browser console for errors
1. Open the checkout page: `/events/pumpkin-patch-checkout.html`
2. Open browser DevTools (F12 or right-click → Inspect)
3. Go to the Console tab
4. Try to submit an order
5. Look for red error messages

**Common errors:**
- ❌ "permission denied for table pumpkin_patch_orders" → Schema not created or RLS policies missing
- ❌ "relation pumpkin_patch_orders does not exist" → Tables not created
- ❌ "function generate_pumpkin_order_number() does not exist" → Function not created

### 3. Check sessionStorage for fallback data
In the browser console, run:
```javascript
console.log('Order ID:', sessionStorage.getItem('pumpkin_order_id'));
console.log('Order Number:', sessionStorage.getItem('pumpkin_order_number'));
console.log('Order Details:', sessionStorage.getItem('pumpkin_order_details'));
```

This will show if the order was saved locally as a fallback.

### 4. Test database connection
Run this in Supabase SQL Editor:
```sql
-- Try to insert a test order manually
INSERT INTO public.pumpkin_patch_orders (
  order_number,
  first_name,
  last_name,
  email,
  total_amount
) VALUES (
  'PP-TEST-001',
  'Test',
  'User',
  'test@example.com',
  25.00
) RETURNING *;
```

**If this works:** The database is fine, issue is with the JavaScript
**If this fails:** Database schema wasn't created properly

### 5. Verify Supabase client is initialized
In browser console:
```javascript
console.log('Supabase client:', window.supabaseClient);
```

Should show an object, not `undefined`.

### 6. Check network requests
In browser DevTools:
1. Go to Network tab
2. Try to submit an order
3. Look for requests to Supabase
4. Check if any failed (shown in red)
5. Click on failed requests to see error details

## Most Likely Issue:

**The schema file hasn't been run yet in Supabase.**

### Quick Fix:
1. Go to your Supabase Dashboard
2. Click on "SQL Editor"
3. Open `/database/pumpkin-patch-orders-schema.sql` from this project
4. Copy ALL the SQL code
5. Paste into Supabase SQL Editor
6. Click "Run" button
7. Wait for success message
8. Try submitting an order again

## Alternative: Test without database

The code has a fallback that saves to sessionStorage if the database isn't ready.

To retrieve orders from sessionStorage, run this in the browser console:
```javascript
const orderDetails = sessionStorage.getItem('pumpkin_order_details');
if (orderDetails) {
  console.log(JSON.parse(orderDetails));
} else {
  console.log('No order found in sessionStorage');
}
```
