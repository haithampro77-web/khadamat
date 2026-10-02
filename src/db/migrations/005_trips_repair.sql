-- V57 repair: make the motorbike category visible on existing databases.
-- 004_trips.sql originally used the literal string 'id' as parent_id.
-- This migration is idempotent and repairs both fresh and already-migrated databases.

INSERT OR IGNORE INTO categories(
  id,parent_id,slug,name_i18n,icon,keywords,sort_order,is_active,created_at,updated_at
)
SELECT
  'cat-motorbike-trips', id, 'motorbike-trips',
  '{"ar":"المشاوير والتوصيل بالدباب","en":"Motorbike trips & delivery"}',
  '🛵',
  '["دباب","مشوار","توصيل","مندوب","شراء","صيدلية"]',
  90,1,datetime('now'),datetime('now')
FROM categories WHERE slug='transport';

UPDATE categories
SET parent_id=(SELECT id FROM categories WHERE slug='transport'),
    is_active=1,
    updated_at=datetime('now')
WHERE slug='motorbike-trips'
  AND EXISTS (SELECT 1 FROM categories WHERE slug='transport');

-- If a previous partial seed created these services under another category,
-- move them to the canonical motorbike category without changing their content.
UPDATE services
SET category_id='cat-motorbike-trips', updated_at=datetime('now')
WHERE slug IN (
  'motorbike-passenger-trip','motorbike-item-delivery','motorbike-buy-item',
  'motorbike-buy-medicine','motorbike-restaurant-pickup','motorbike-document-delivery',
  'motorbike-technician-pickup','motorbike-store-shopping','motorbike-small-load',
  'motorbike-home-pickup','motorbike-other'
)
AND EXISTS (SELECT 1 FROM categories WHERE id='cat-motorbike-trips');

INSERT OR IGNORE INTO services(id,category_id,slug,name_i18n,icon,keywords,pricing_type,base_price,form_schema,cancellation_policy_id,default_priority,sort_order,is_active,created_at,updated_at)
SELECT 'svc-mb-passenger','cat-motorbike-trips','motorbike-passenger-trip','{"ar":"مشوار شخص","en":"Passenger trip"}','🧍','["مشوار شخص","راكب","دباب"]','FIXED',0,'[]','default','NORMAL',1,1,datetime('now'),datetime('now')
WHERE EXISTS (SELECT 1 FROM categories WHERE id='cat-motorbike-trips');
INSERT OR IGNORE INTO services(id,category_id,slug,name_i18n,icon,keywords,pricing_type,base_price,form_schema,cancellation_policy_id,default_priority,sort_order,is_active,created_at,updated_at)
SELECT 'svc-mb-item','cat-motorbike-trips','motorbike-item-delivery','{"ar":"توصيل طلب أو غرض","en":"Item delivery"}','📦','["توصيل","غرض","طلب"]','FIXED',0,'[]','default','NORMAL',2,1,datetime('now'),datetime('now') WHERE EXISTS (SELECT 1 FROM categories WHERE id='cat-motorbike-trips');
INSERT OR IGNORE INTO services(id,category_id,slug,name_i18n,icon,keywords,pricing_type,base_price,form_schema,cancellation_policy_id,default_priority,sort_order,is_active,created_at,updated_at)
SELECT 'svc-mb-buy','cat-motorbike-trips','motorbike-buy-item','{"ar":"شراء وإحضار غرض","en":"Buy and bring an item"}','🛒','["شراء","إحضار","غرض"]','FIXED',0,'[]','default','NORMAL',3,1,datetime('now'),datetime('now') WHERE EXISTS (SELECT 1 FROM categories WHERE id='cat-motorbike-trips');
INSERT OR IGNORE INTO services(id,category_id,slug,name_i18n,icon,keywords,pricing_type,base_price,form_schema,cancellation_policy_id,default_priority,sort_order,is_active,created_at,updated_at)
SELECT 'svc-mb-med','cat-motorbike-trips','motorbike-buy-medicine','{"ar":"شراء دواء من الصيدلية","en":"Buy medicine from pharmacy"}','💊','["دواء","صيدلية","شراء دواء"]','FIXED',0,'[]','default','NORMAL',4,1,datetime('now'),datetime('now') WHERE EXISTS (SELECT 1 FROM categories WHERE id='cat-motorbike-trips');
INSERT OR IGNORE INTO services(id,category_id,slug,name_i18n,icon,keywords,pricing_type,base_price,form_schema,cancellation_policy_id,default_priority,sort_order,is_active,created_at,updated_at)
SELECT 'svc-mb-rest','cat-motorbike-trips','motorbike-restaurant-pickup','{"ar":"استلام طلب من مطعم","en":"Restaurant pickup"}','🍔','["مطعم","استلام طلب","توصيل طعام"]','FIXED',0,'[]','default','NORMAL',5,1,datetime('now'),datetime('now') WHERE EXISTS (SELECT 1 FROM categories WHERE id='cat-motorbike-trips');
INSERT OR IGNORE INTO services(id,category_id,slug,name_i18n,icon,keywords,pricing_type,base_price,form_schema,cancellation_policy_id,default_priority,sort_order,is_active,created_at,updated_at)
SELECT 'svc-mb-doc','cat-motorbike-trips','motorbike-document-delivery','{"ar":"استلام وتسليم مستندات","en":"Document pickup and delivery"}','📄','["مستندات","أوراق","وثائق"]','FIXED',0,'[]','default','NORMAL',6,1,datetime('now'),datetime('now') WHERE EXISTS (SELECT 1 FROM categories WHERE id='cat-motorbike-trips');
INSERT OR IGNORE INTO services(id,category_id,slug,name_i18n,icon,keywords,pricing_type,base_price,form_schema,cancellation_policy_id,default_priority,sort_order,is_active,created_at,updated_at)
SELECT 'svc-mb-tech','cat-motorbike-trips','motorbike-technician-pickup','{"ar":"إحضار فني أو عامل","en":"Bring a technician or worker"}','🔧','["فني","عامل","إحضار"]','FIXED',0,'[]','default','NORMAL',7,1,datetime('now'),datetime('now') WHERE EXISTS (SELECT 1 FROM categories WHERE id='cat-motorbike-trips');
INSERT OR IGNORE INTO services(id,category_id,slug,name_i18n,icon,keywords,pricing_type,base_price,form_schema,cancellation_policy_id,default_priority,sort_order,is_active,created_at,updated_at)
SELECT 'svc-mb-shop','cat-motorbike-trips','motorbike-store-shopping','{"ar":"شراء أغراض من متجر","en":"Shop for items"}','🛍️','["متجر","شراء أغراض","مشتريات"]','FIXED',0,'[]','default','NORMAL',8,1,datetime('now'),datetime('now') WHERE EXISTS (SELECT 1 FROM categories WHERE id='cat-motorbike-trips');
INSERT OR IGNORE INTO services(id,category_id,slug,name_i18n,icon,keywords,pricing_type,base_price,form_schema,cancellation_policy_id,default_priority,sort_order,is_active,created_at,updated_at)
SELECT 'svc-mb-small','cat-motorbike-trips','motorbike-small-load','{"ar":"نقل أغراض صغيرة","en":"Small-item transport"}','📦','["أغراض صغيرة","حمولة صغيرة","نقل"]','FIXED',0,'[]','default','NORMAL',9,1,datetime('now'),datetime('now') WHERE EXISTS (SELECT 1 FROM categories WHERE id='cat-motorbike-trips');
INSERT OR IGNORE INTO services(id,category_id,slug,name_i18n,icon,keywords,pricing_type,base_price,form_schema,cancellation_policy_id,default_priority,sort_order,is_active,created_at,updated_at)
SELECT 'svc-mb-home','cat-motorbike-trips','motorbike-home-pickup','{"ar":"استلام أو توصيل شيء من/إلى المنزل","en":"Home pickup or delivery"}','🏠','["منزل","استلام","توصيل"]','FIXED',0,'[]','default','NORMAL',10,1,datetime('now'),datetime('now') WHERE EXISTS (SELECT 1 FROM categories WHERE id='cat-motorbike-trips');
INSERT OR IGNORE INTO services(id,category_id,slug,name_i18n,icon,keywords,pricing_type,base_price,form_schema,cancellation_policy_id,default_priority,sort_order,is_active,created_at,updated_at)
SELECT 'svc-mb-other','cat-motorbike-trips','motorbike-other','{"ar":"أخرى","en":"Other"}','➕','["أخرى","طلب خاص","خدمة أخرى"]','FIXED',0,'[{"key":"other_description","type":"textarea","label":{"ar":"ما الخدمة التي تحتاجها؟","en":"What do you need?"},"required":true,"maxLength":1000}]','default','NORMAL',11,1,datetime('now'),datetime('now') WHERE EXISTS (SELECT 1 FROM categories WHERE id='cat-motorbike-trips');
