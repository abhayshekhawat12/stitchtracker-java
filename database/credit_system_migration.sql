-- =====================================================================
-- StitchTrack Credit System Migration (large-item 3-credit rules)
-- Run AFTER base schema AND subscription_migration.sql
-- Safe to re-run: uses IF NOT EXISTS / ALTER IGNORE patterns
-- =====================================================================

USE stitchtrack_java;

-- ----------------------------------------------------------------
-- 1. laundry_items: add credit_rate and credits_consumed columns
-- ----------------------------------------------------------------
ALTER TABLE laundry_items
  ADD COLUMN IF NOT EXISTS credit_rate      INT NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS credits_consumed INT NOT NULL DEFAULT 0;

-- Back-fill existing rows: Blanket and Bedsheet get rate=3
UPDATE laundry_items SET credit_rate=3, credits_consumed=item_count*3
  WHERE LOWER(category) IN ('blanket','bedsheet','quilt','razai','comforter','duvet')
    AND credit_rate=1;

-- All other items: credits_consumed = item_count (already 1 per item)
UPDATE laundry_items SET credits_consumed=item_count
  WHERE LOWER(category) NOT IN ('blanket','bedsheet','quilt','razai','comforter','duvet')
    AND credits_consumed=0 AND item_count>0;

-- ----------------------------------------------------------------
-- 2. laundry_orders: add total_credits column
--    Stores the total credits deducted for the whole order.
-- ----------------------------------------------------------------
ALTER TABLE laundry_orders
  ADD COLUMN IF NOT EXISTS total_credits INT NOT NULL DEFAULT 0;

-- Back-fill existing orders from their items
UPDATE laundry_orders o
  SET total_credits = (
    SELECT COALESCE(SUM(credits_consumed),0)
    FROM laundry_items i WHERE i.order_id = o.id
  )
  WHERE total_credits = 0;

-- ----------------------------------------------------------------
-- Note on quota restoration:
--   The LaundryDAO now uses total_credits (not total_items) to
--   restore membership_used on reject/cancel.
--   For pre-existing orders (credit_rate not stored), the
--   restoration falls back to total_items.
-- ----------------------------------------------------------------
