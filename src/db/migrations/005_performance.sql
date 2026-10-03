-- Performance indexes for high-concurrency MVP workloads.
CREATE INDEX IF NOT EXISTS ix_orders_customer_status_created ON orders(customer_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS ix_orders_provider_status_created ON orders(provider_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS ix_orders_assignment_queue ON orders(status, provider_id, service_id, area_id, created_at DESC);
CREATE INDEX IF NOT EXISTS ix_service_providers_matching ON service_providers(verification_status, is_online, id);
CREATE INDEX IF NOT EXISTS ix_provider_services_match ON provider_services(service_id, is_active, provider_id);
CREATE INDEX IF NOT EXISTS ix_provider_areas_match ON provider_service_areas(area_id, provider_id);
CREATE INDEX IF NOT EXISTS ix_trip_orders_updated ON trip_orders(updated_at DESC);
