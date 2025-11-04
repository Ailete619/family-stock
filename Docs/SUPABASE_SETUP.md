# Supabase Sync Setup

This document explains how to set up read-only sync from Supabase for the FamilyStock app.

## Overview

The app now supports pull-to-refresh synchronization from a Supabase backend. This is a read-only implementation that fetches data from Supabase and updates the local SwiftData store.

## Prerequisites

1. A Supabase project with the required tables (see below)
2. Supabase project URL and anon key

## Database Setup

### 1. Create all required tables in Supabase

#### Stock Items Table

```sql
CREATE TABLE stock_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  category TEXT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_archived BOOLEAN NOT NULL DEFAULT FALSE,
  quantity_in_stock DOUBLE PRECISION NOT NULL DEFAULT 0,
  quantity_full_stock DOUBLE PRECISION NOT NULL DEFAULT 0
);

-- Create an index on updated_at for efficient incremental sync
CREATE INDEX idx_stock_items_updated_at ON stock_items(updated_at);

-- Create an index on user_id for efficient filtering
CREATE INDEX idx_stock_items_user_id ON stock_items(user_id);

-- Enable Row Level Security (RLS)
ALTER TABLE stock_items ENABLE ROW LEVEL SECURITY;

-- Create a policy that allows users to read only their own data
CREATE POLICY "Users can read own stock items"
ON stock_items FOR SELECT
USING (auth.uid() = user_id);

-- Create a policy that allows users to insert their own data
CREATE POLICY "Users can insert own stock items"
ON stock_items FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Create a policy that allows users to update their own data
CREATE POLICY "Users can update own stock items"
ON stock_items FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Create a policy that allows users to delete their own data
CREATE POLICY "Users can delete own stock items"
ON stock_items FOR DELETE
USING (auth.uid() = user_id);
```

#### Shopping Entries Table

```sql
CREATE TABLE shopping_entries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  item_id UUID NOT NULL,
  desired_quantity DOUBLE PRECISION NOT NULL DEFAULT 1,
  unit TEXT NOT NULL DEFAULT 'pcs',
  note TEXT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
  is_completed BOOLEAN NOT NULL DEFAULT FALSE
);

-- Create an index on updated_at for efficient incremental sync
CREATE INDEX idx_shopping_entries_updated_at ON shopping_entries(updated_at);

-- Create an index on user_id for efficient filtering
CREATE INDEX idx_shopping_entries_user_id ON shopping_entries(user_id);

-- Enable Row Level Security (RLS)
ALTER TABLE shopping_entries ENABLE ROW LEVEL SECURITY;

-- Create a policy that allows users to read only their own data
CREATE POLICY "Users can read own shopping entries"
ON shopping_entries FOR SELECT
USING (auth.uid() = user_id);

-- Create a policy that allows users to insert their own data
CREATE POLICY "Users can insert own shopping entries"
ON shopping_entries FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Create a policy that allows users to update their own data
CREATE POLICY "Users can update own shopping entries"
ON shopping_entries FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Create a policy that allows users to delete their own data
CREATE POLICY "Users can delete own shopping entries"
ON shopping_entries FOR DELETE
USING (auth.uid() = user_id);
```

#### Receipts Table

```sql
CREATE TABLE receipts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  shop_name TEXT NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  amount DOUBLE PRECISION
);

-- Create an index on timestamp for efficient incremental sync
CREATE INDEX idx_receipts_timestamp ON receipts(timestamp);

-- Create an index on user_id for efficient filtering
CREATE INDEX idx_receipts_user_id ON receipts(user_id);

-- Enable Row Level Security (RLS)
ALTER TABLE receipts ENABLE ROW LEVEL SECURITY;

-- Create a policy that allows users to read only their own data
CREATE POLICY "Users can read own receipts"
ON receipts FOR SELECT
USING (auth.uid() = user_id);

-- Create a policy that allows users to insert their own data
CREATE POLICY "Users can insert own receipts"
ON receipts FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Create a policy that allows users to update their own data
CREATE POLICY "Users can update own receipts"
ON receipts FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Create a policy that allows users to delete their own data
CREATE POLICY "Users can delete own receipts"
ON receipts FOR DELETE
USING (auth.uid() = user_id);
```

#### Receipt Items Table

```sql
CREATE TABLE receipt_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  receipt_id UUID NOT NULL REFERENCES receipts(id) ON DELETE CASCADE,
  item_name TEXT NOT NULL,
  quantity DOUBLE PRECISION NOT NULL
);

-- Create an index on receipt_id for efficient lookups
CREATE INDEX idx_receipt_items_receipt_id ON receipt_items(receipt_id);

-- Enable Row Level Security (RLS)
ALTER TABLE receipt_items ENABLE ROW LEVEL SECURITY;

-- Create a policy that allows users to read items from their own receipts
CREATE POLICY "Users can read own receipt items"
ON receipt_items FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM receipts
    WHERE receipts.id = receipt_items.receipt_id
    AND receipts.user_id = auth.uid()
  )
);

-- Create a policy that allows users to insert items for their own receipts
CREATE POLICY "Users can insert own receipt items"
ON receipt_items FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM receipts
    WHERE receipts.id = receipt_items.receipt_id
    AND receipts.user_id = auth.uid()
  )
);

-- Create a policy that allows users to update items from their own receipts
CREATE POLICY "Users can update own receipt items"
ON receipt_items FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM receipts
    WHERE receipts.id = receipt_items.receipt_id
    AND receipts.user_id = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM receipts
    WHERE receipts.id = receipt_items.receipt_id
    AND receipts.user_id = auth.uid()
  )
);

-- Create a policy that allows users to delete items from their own receipts
CREATE POLICY "Users can delete own receipt items"
ON receipt_items FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM receipts
    WHERE receipts.id = receipt_items.receipt_id
    AND receipts.user_id = auth.uid()
  )
);
```

### 2. Configure Secrets.plist

1. Copy `Secrets.plist.template` to `Secrets.plist`:
   ```bash
   cp FamilyStock/Secrets.plist.template FamilyStock/Secrets.plist
   ```

2. Edit `FamilyStock/Secrets.plist` and replace the placeholders:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>SUPABASE_URL</key>
       <string>https://YOUR-PROJECT-ID.supabase.co/rest/v1/</string>
       <key>SUPABASE_ANON_KEY</key>
       <string>YOUR_ACTUAL_ANON_KEY_HERE</string>
   </dict>
   </plist>
   ```

3. **Important**: `Secrets.plist` is already in `.gitignore` and will NOT be committed to git

### 3. Add Secrets.plist to Xcode

1. Open the FamilyStock project in Xcode
2. Right-click on the `FamilyStock` folder in the project navigator
3. Select "Add Files to FamilyStock..."
4. Select the `Secrets.plist` file
5. Make sure "Copy items if needed" is checked
6. Make sure the FamilyStock target is selected
7. Click "Add"

## Usage

### Pull to Refresh

The app supports pull-to-refresh on all three main tabs:

#### Stock Tab
1. Open the app
2. Navigate to the Stock tab
3. Pull down on the list to trigger a refresh
4. The app will fetch all stock items updated since the last sync from Supabase
5. Local items will be updated or new items will be created

#### Shopping Tab
1. Navigate to the Shopping tab
2. Pull down on the list to trigger a refresh
3. The app will fetch all shopping entries updated since the last sync
4. Local shopping entries will be updated or created

#### Receipts Tab
1. Navigate to the Receipts tab
2. Pull down on the list to trigger a refresh
3. The app will fetch all receipts and their items since the last sync
4. Local receipts will be updated or created

### How It Works

1. **First Sync**: On the first pull, all data from Supabase is fetched
2. **Incremental Sync**: Subsequent pulls only fetch items modified since the last successful sync
3. **Timestamp Tracking**: The last sync timestamp is stored in `UserDefaults` with separate keys:
   - `lastPullItems` - Stock items
   - `lastPullShopping` - Shopping entries
   - `lastPullReceipts` - Receipts
4. **Upsert Logic**: Items are matched by their `id` field. If an item exists locally, it's updated; otherwise, a new item is created

## Architecture

### Network Layer

- **Secrets.swift**: Loads Supabase credentials from Secrets.plist
- **HTTPClient.swift**: Generic HTTP client with JSON decoding
- **DTOs.swift**: Data Transfer Objects for all entities (StockItem, ShoppingEntry, Receipt, ReceiptItem)

#### Repositories
- **ItemRepository.swift**: Protocol for stock items repository
- **SupabaseItemRepository.swift**: Stock items implementation using PostgREST API
- **ShoppingEntryRepository.swift**: Protocol and implementation for shopping entries
- **ReceiptRepository.swift**: Protocol and implementation for receipts and receipt items

#### Mapping
- **StockItem+Mapping.swift**: Maps StockItemDTO to SwiftData StockItem model
- **ShoppingEntry+Mapping.swift**: Maps ShoppingEntryDTO to SwiftData ShoppingEntry model
- **Receipt+Mapping.swift**: Maps ReceiptDTO and ReceiptItemDTO to SwiftData Receipt and ReceiptItem models

#### Sync Service
- **SyncService.swift**: Orchestrates the sync process for all entities
  - `pullItems()` - Sync stock items only
  - `pullShopping()` - Sync shopping entries only
  - `pullReceipts()` - Sync receipts and their items only
  - `pullAll()` - Sync all entities

### Key Files

- `FamilyStock/Network/` - All sync-related code
- `FamilyStock/Stock/StockItem+Mapping.swift` - Stock item DTO mapping
- `FamilyStock/Shopping/ShoppingEntry+Mapping.swift` - Shopping entry DTO mapping
- `FamilyStock/Receipts/Receipt+Mapping.swift` - Receipt and receipt item DTO mapping
- `FamilyStock/Stock/StockListView.swift` - Stock tab with pull-to-refresh
- `FamilyStock/Shopping/ShoppingListView.swift` - Shopping tab with pull-to-refresh
- `FamilyStock/Receipts/ReceiptListView.swift` - Receipts tab with pull-to-refresh

## Troubleshooting

### "Missing or invalid Secrets.plist" error

- Make sure `Secrets.plist` exists in the `FamilyStock` folder
- Verify the file is added to the Xcode project
- Check that the file contains valid XML and correct keys

### Pull-to-refresh does nothing

- Check the console for error messages
- Verify your Supabase URL ends with `/rest/v1/`
- Verify your anon key is correct
- Check that the `stock_items` table exists and has the correct schema

### Items not appearing after sync

- Check that the table has data
- Verify RLS policies allow read access
- Check console for sync errors
- Verify the `is_archived` field is set correctly (false for visible items)

## Future Enhancements

This is a read-only implementation. Future work could include:

- Push sync (uploading local changes to Supabase)
- Conflict resolution
- Real-time sync using Supabase Realtime
- Shopping list and receipts sync
- Better error handling and user feedback
