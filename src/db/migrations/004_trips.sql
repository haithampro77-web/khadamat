CREATE TABLE IF NOT EXISTS trips (
  id TEXT PRIMARY KEY,
  order_id TEXT NOT NULL UNIQUE REFERENCES orders(id) ON DELETE CASCADE,
  origin_location_id TEXT NOT NULL REFERENCES locations(id),
  destination_location_id TEXT NOT NULL REFERENCES locations(id),
  pricing_base REAL NOT NULL DEFAULT 0 CHECK (pricing_base >= 0),
  pricing_per_km REAL NOT NULL DEFAULT 0 CHECK (pricing_per_km >= 0),
  estimated_distance_km REAL NOT NULL DEFAULT 0 CHECK (estimated_distance_km >= 0),
  actual_distance_km REAL,
  estimated_price REAL NOT NULL DEFAULT 0 CHECK (estimated_price >= 0),
  final_price REAL,
  started_at TEXT,
  ended_at TEXT,
  status TEXT NOT NULL DEFAULT 'CREATED' CHECK (status IN ('CREATED','STARTED','COMPLETED','CANCELLED')),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS ix_trips_status ON trips(status, created_at DESC);

CREATE TABLE IF NOT EXISTS trip_points (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  trip_id TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  lat REAL NOT NULL CHECK (lat BETWEEN -90 AND 90),
  lng REAL NOT NULL CHECK (lng BETWEEN -180 AND 180),
  accuracy_m REAL,
  recorded_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS ix_trip_points_trip ON trip_points(trip_id, recorded_at);

INSERT OR IGNORE INTO categories(id,parent_id,slug,name_i18n,icon,keywords,sort_order,is_active,created_at,updated_at)
SELECT 'cat-motorbike-trips',id,'motorbike-trips','{"ar":"المشاوير والتوصيل بالدباب","en":"Motorbike trips & delivery"}','🛵','["دباب","مشوار","توصيل","مندوب","شراء","صيدلية"]',90,1,datetime('now'),datetime('now') FROM categories WHERE slug='transport';
INSERT OR IGNORE INTO services(id,category_id,slug,name_i18n,icon,keywords,pricing_type,base_price,form_schema,cancellation_policy_id,default_priority,sort_order,is_active,created_at,updated_at) SELECT 'svc-mb-passenger','cat-motorbike-trips','motorbike-passenger-trip','{"ar":"مشوار شخص","en":"Passenger trip"}','🧍','["مشوار شخص","راكب","دباب"]','FIXED',0,'[]','default','NORMAL',1,1,datetime('now'),datetime('now') FROM categories WHERE id='cat-motorbike-trips';
INSERT OR IGNORE INTO services(id,category_id,slug,name_i18n,icon,keywords,pricing_type,base_price,form_schema,cancellation_policy_id,default_priority,sort_order,is_active,created_at,updated_at) SELECT 'svc-mb-item','cat-motorbike-trips','motorbike-item-delivery','{"ar":"توصيل طلب أو غرض","en":"Item delivery"}','📦','["توصيل","غرض","طلب"]','FIXED',0,'[]','default','NORMAL',2,1,datetime('now'),datetime('now') FROM categories WHERE id='cat-motorbike-trips';
INSERT OR IGNORE INTO services(id,category_id,slug,name_i18n,icon,keywords,pricing_type,base_price,form_schema,cancellation_policy_id,default_priority,sort_order,is_active,created_at,updated_at) SELECT 'svc-mb-buy','cat-motorbike-trips','motorbike-buy-item','{"ar":"شراء وإحضار غرض","en":"Buy and bring an item"}','🛒','["شراء","إحضار","غرض"]','FIXED',0,'[]','default','NORMAL',3,1,datetime('now'),datetime('now') FROM categories WHERE id='cat-motorbike-trips';
INSERT OR IGNORE INTO services(id,category_id,slug,name_i18n,icon,keywords,pricing_type,base_price,form_schema,cancellation_policy_id,default_priority,sort_order,is_active,created_at,updated_at) SELECT 'svc-mb-med','cat-motorbike-trips','motorbike-buy-medicine','{"ar":"شراء دواء من الصيدلية","en":"Buy medicine from pharmacy"}','💊','["دواء","صيدلية","شراء دواء"]','FIXED',0,'[]','default','NORMAL',4,1,datetime('now'),datetime('now') FROM categories WHERE id='cat-motorbike-trips';
INSERT OR IGNORE INTO services(id,category_id,slug,name_i18n,icon,keywords,pricing_type,base_price,form_schema,cancellation_policy_id,default_priority,sort_order,is_active,created_at,updated_at) SELECT 'svc-mb-rest','cat-motorbike-trips','motorbike-restaurant-pickup','{"ar":"استلام طلب من مطعم","en":"Restaurant pickup"}','🍔','["مطعم","استلام طلب","توصيل طعام"]','FIXED',0,'[]','default','NORMAL',5,1,datetime('now'),datetime('now') FROM categories WHERE id='cat-motorbike-trips';
INSERT OR IGNORE INTO services(id,category_id,slug,name_i18n,icon,keywords,pricing_type,base_price,form_schema,cancellation_policy_id,default_priority,sort_order,is_active,created_at,updated_at) SELECT 'svc-mb-doc','cat-motorbike-trips','motorbike-document-delivery','{"ar":"استلام وتسليم مستندات","en":"Document pickup and delivery"}','📄','["مستندات","أوراق","وثائق"]','FIXED',0,'[]','default','NORMAL',6,1,datetime('now'),datetime('now') FROM categories WHERE id='cat-motorbike-trips';
INSERT OR IGNORE INTO services(id,category_id,slug,name_i18n,icon,keywords,pricing_type,base_price,form_schema,cancellation_policy_id,default_priority,sort_order,is_active,created_at,updated_at) SELECT 'svc-mb-tech','cat-motorbike-trips','motorbike-technician-pickup','{"ar":"إحضار فني أو عامل","en":"Bring a technician or worker"}','🔧','["فني","عامل","إحضار"]','FIXED',0,'[]','default','NORMAL',7,1,datetime('now'),datetime('now') FROM categories WHERE id='cat-motorbike-trips';
INSERT OR IGNORE INTO services(id,category_id,slug,name_i18n,icon,keywords,pricing_type,base_price,form_schema,cancellation_policy_id,default_priority,sort_order,is_active,created_at,updated_at) SELECT 'svc-mb-shop','cat-motorbike-trips','motorbike-store-shopping','{"ar":"شراء أغراض من متجر","en":"Shop for items"}','🛍️','["متجر","شراء أغراض","مشتريات"]','FIXED',0,'[]','default','NORMAL',8,1,datetime('now'),datetime('now') FROM categories WHERE id='cat-motorbike-trips';
INSERT OR IGNORE INTO services(id,category_id,slug,name_i18n,icon,keywords,pricing_type,base_price,form_schema,cancellation_policy_id,default_priority,sort_order,is_active,created_at,updated_at) SELECT 'svc-mb-small','cat-motorbike-trips','motorbike-small-load','{"ar":"نقل أغراض صغيرة","en":"Small-item transport"}','📦','["أغراض صغيرة","حمولة صغيرة","نقل"]','FIXED',0,'[]','default','NORMAL',9,1,datetime('now'),datetime('now') FROM categories WHERE id='cat-motorbike-trips';
INSERT OR IGNORE INTO services(id,category_id,slug,name_i18n,icon,keywords,pricing_type,base_price,form_schema,cancellation_policy_id,default_priority,sort_order,is_active,created_at,updated_at) SELECT 'svc-mb-home','cat-motorbike-trips','motorbike-home-pickup','{"ar":"استلام أو توصيل شيء من/إلى المنزل","en":"Home pickup or delivery"}','🏠','["منزل","استلام","توصيل"]','FIXED',0,'[]','default','NORMAL',10,1,datetime('now'),datetime('now') FROM categories WHERE id='cat-motorbike-trips';
INSERT OR IGNORE INTO services(id,category_id,slug,name_i18n,icon,keywords,pricing_type,base_price,form_schema,cancellation_policy_id,default_priority,sort_order,is_active,created_at,updated_at) SELECT 'svc-mb-other','cat-motorbike-trips','motorbike-other','{"ar":"أخرى","en":"Other"}','➕','["أخرى","طلب خاص","خدمة أخرى"]','FIXED',0,'[{"key":"other_description","type":"textarea","label":{"ar":"ما الخدمة التي تحتاجها؟","en":"What do you need?"},"required":true,"maxLength":1000}]','default','NORMAL',11,1,datetime('now'),datetime('now') FROM categories WHERE id='cat-motorbike-trips';
