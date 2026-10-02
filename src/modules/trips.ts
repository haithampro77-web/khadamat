import { s, parse } from '../core/validate.js';
import { E } from '../core/errors.js';
import { uuid } from '../core/security.js';
import { haversineKm, iso, round } from '../core/util.js';
import { auth, roles } from './auth.middleware.js';
import { locationSchema, type LocationInput } from './locations.js';
import type { App } from '../app.js';
import type { Ctx, Router } from '../core/http.js';
import type { OrderRow } from '../types/domain.js';

const TRIP_SLUGS = new Set([
  'motorbike-passenger-trip','motorbike-item-delivery','motorbike-buy-item','motorbike-buy-medicine',
  'motorbike-restaurant-pickup','motorbike-document-delivery','motorbike-technician-pickup',
  'motorbike-store-shopping','motorbike-small-load','motorbike-home-pickup','motorbike-other'
]);
const estimateSchema = s.obj({ origin: locationSchema, destination: locationSchema });
const pointSchema = s.obj({ lat:s.num({min:-90,max:90}), lng:s.num({min:-180,max:180}), accuracy:s.num({min:0,max:100000,optional:true}) });

function isTripService(app: App, serviceId: string): boolean {
  const svc=app.catalog.all().byService.get(serviceId); return !!svc && TRIP_SLUGS.has(svc.slug);
}
function rate(app: App, serviceId: string) {
  const svc=app.catalog.all().byService.get(serviceId);
  const base=app.settings.get<number>('trips.base_price');
  const perKm=app.settings.get<number>('trips.price_per_km');
  return { base: svc?.base_price && svc.base_price > 0 ? svc.base_price : base, perKm };
}
function calc(app: App, serviceId: string, a: LocationInput, b: LocationInput) {
  const distance=round(haversineKm(a.lat,a.lng,b.lat,b.lng),2);
  const r=rate(app,serviceId); const price=round(Math.max(app.settings.get<number>('trips.minimum_price'), r.base + distance*r.perKm),2);
  return { distanceKm:distance, basePrice:r.base, pricePerKm:r.perKm, estimatedPrice:price, currency:app.settings.get<string>('platform.currency') };
}
function tripOut(app: App, t:any, ctx:Ctx) {
  const o=app.db.get<OrderRow>('SELECT * FROM orders WHERE id=?',t.order_id);
  const origin=app.db.get<any>('SELECT * FROM locations WHERE id=?',t.origin_location_id)!;
  const dest=app.db.get<any>('SELECT * FROM locations WHERE id=?',t.destination_location_id)!;
  return { id:t.id, orderId:t.order_id, status:t.status, origin:app.locations.serialize(origin,ctx.locale), destination:app.locations.serialize(dest,ctx.locale), estimatedDistanceKm:t.estimated_distance_km, actualDistanceKm:t.actual_distance_km, estimatedPrice:t.estimated_price, finalPrice:t.final_price, basePrice:t.pricing_base, pricePerKm:t.pricing_per_km, currency:o?.currency||app.settings.get<string>('platform.currency'), startedAt:t.started_at, endedAt:t.ended_at, pointCount:app.db.get<{n:number}>('SELECT COUNT(*) n FROM trip_points WHERE trip_id=?',t.id)!.n };
}

export function isMotorbikeTripService(app: App, serviceId: string) { return isTripService(app, serviceId); }
export function createTripForOrder(app: App, order: OrderRow, origin: LocationInput, destination: LocationInput) {
  if(!isTripService(app,order.service_id)) return null;
  const c=calc(app,order.service_id,origin,destination); const originRow=app.db.get<any>('SELECT * FROM locations WHERE id=?',order.location_id)!;
  const destRow=app.locations.create(destination,{requireArea:false}); const id=uuid(); const now=iso(app.clock.now());
  app.db.run(`INSERT INTO trips(id,order_id,origin_location_id,destination_location_id,pricing_base,pricing_per_km,estimated_distance_km,estimated_price,created_at,updated_at) VALUES (?,?,?,?,?,?,?,?,?,?)`,id,order.id,originRow.id,destRow.id,c.basePrice,c.pricePerKm,c.distanceKm,c.estimatedPrice,now,now);
  app.db.run('UPDATE orders SET price_snapshot=?, agreed_price=? WHERE id=?',c.estimatedPrice,c.estimatedPrice,order.id);
  return app.db.get<any>('SELECT * FROM trips WHERE id=?',id)!;
}

export function registerTripRoutes(app: App, r: Router) {
  const { db, orders } = app;
  r.post('/trips/estimate', auth, roles('CUSTOMER'), (ctx:Ctx)=>{
    const b=parse<any>(s.obj({serviceId:s.str({min:1,max:64}),origin:locationSchema,destination:locationSchema}),ctx.body);
    if(!isTripService(app,b.serviceId)) throw E.unprocessable('الخدمة ليست من خدمات المشاوير بالدباب','NOT_TRIP_SERVICE');
    return calc(app,b.serviceId,b.origin,b.destination);
  });
  r.get('/orders/:id/trip', auth, (ctx:Ctx)=>{
    const o=orders.getOwned(ctx.params['id']!,ctx); const t=db.get<any>('SELECT * FROM trips WHERE order_id=?',o.id); if(!t) throw E.notFound('لا توجد رحلة مرتبطة بهذا الطلب'); return {trip:tripOut(app,t,ctx)};
  });
  r.post('/provider/orders/:id/trip/start', auth, roles('PROVIDER'), (ctx:Ctx)=>{
    const o=db.get<OrderRow>('SELECT * FROM orders WHERE id=? AND provider_id=?',ctx.params['id'],ctx.user!.providerId); if(!o) throw E.notFound('الطلب غير موجود');
    if(!isTripService(app,o.service_id)) throw E.unprocessable('هذا الطلب ليس مشوارًا','NOT_TRIP');
    const t=db.get<any>('SELECT * FROM trips WHERE order_id=?',o.id); if(!t) throw E.notFound('بيانات الرحلة غير موجودة');
    if(o.status!=='ON_THE_WAY') throw E.unprocessable('ابدأ الرحلة بعد الوصول إلى حالة «في الطريق»','INVALID_TRIP_START');
    const updated=orders.applyTransition(o,'IN_PROGRESS','PROVIDER',ctx);
    const now=iso(app.clock.now()); db.run("UPDATE trips SET status='STARTED',started_at=?,updated_at=? WHERE id=?",now,now,t.id);
    app.notifications.notify(o.customer_id,'SERVICE_STARTED',{code:o.code},{orderId:o.id});
    return {order:orders.serialize(updated,ctx),trip:tripOut(app,db.get<any>('SELECT * FROM trips WHERE id=?',t.id),ctx)};
  });
  r.post('/provider/orders/:id/trip/points', auth, roles('PROVIDER'), (ctx:Ctx)=>{
    const b=parse<any>(pointSchema,ctx.body); const o=db.get<OrderRow>('SELECT * FROM orders WHERE id=? AND provider_id=?',ctx.params['id'],ctx.user!.providerId); if(!o) throw E.notFound('الطلب غير موجود');
    if(!isTripService(app,o.service_id)||o.status!=='IN_PROGRESS') throw E.unprocessable('تسجيل الموقع متاح أثناء الرحلة فقط','TRIP_NOT_ACTIVE');
    const t=db.get<any>('SELECT * FROM trips WHERE order_id=?',o.id); if(!t||t.status!=='STARTED') throw E.unprocessable('الرحلة غير مفعلة','TRIP_NOT_STARTED');
    db.run('INSERT INTO trip_points(trip_id,lat,lng,accuracy_m,recorded_at) VALUES (?,?,?,?,?)',t.id,b.lat,b.lng,b.accuracy??null,iso(app.clock.now()));
    return {ok:true};
  });
  r.post('/provider/orders/:id/trip/finish', auth, roles('PROVIDER'), (ctx:Ctx)=>{
    const o=db.get<OrderRow>('SELECT * FROM orders WHERE id=? AND provider_id=?',ctx.params['id'],ctx.user!.providerId); if(!o) throw E.notFound('الطلب غير موجود');
    const t=db.get<any>('SELECT * FROM trips WHERE order_id=?',o.id); if(!t) throw E.notFound('بيانات الرحلة غير موجودة');
    if(o.status!=='IN_PROGRESS'||t.status!=='STARTED') throw E.unprocessable('لا يمكن إنهاء الرحلة الآن','INVALID_TRIP_FINISH');
    const dest=db.get<any>('SELECT * FROM locations WHERE id=?',t.destination_location_id)!; const origin=db.get<any>('SELECT * FROM locations WHERE id=?',t.origin_location_id)!; const points=db.all<any>('SELECT lat,lng FROM trip_points WHERE trip_id=? ORDER BY id',t.id);
    let actual=0; let prev=points[0]; for(const p of points.slice(1)){actual+=haversineKm(prev.lat,prev.lng,p.lat,p.lng);prev=p}
    if(!points.length) actual=t.estimated_distance_km; actual=round(Math.max(actual,haversineKm(origin.lat,origin.lng,dest.lat,dest.lng)),2);
    const finalPrice=round(Math.max(app.settings.get<number>('trips.minimum_price'),t.pricing_base+actual*t.pricing_per_km),2); const now=iso(app.clock.now());
    const updated=orders.applyTransition(o,'COMPLETED','PROVIDER',ctx,{metadata:{tripDistanceKm:actual,tripFinalPrice:finalPrice}});
    db.run("UPDATE trips SET status='COMPLETED',actual_distance_km=?,final_price=?,ended_at=?,updated_at=? WHERE id=?",actual,finalPrice,now,now,t.id);
    db.run('UPDATE orders SET price_snapshot=?, agreed_price=?, updated_at=? WHERE id=?',finalPrice,finalPrice,now,o.id);
    app.payment.onCompleted(updated); app.notifications.notify(o.customer_id,'ORDER_COMPLETED',{code:o.code},{orderId:o.id});
    return {order:orders.serialize(db.get<OrderRow>('SELECT * FROM orders WHERE id=?',o.id)!,ctx),trip:tripOut(app,db.get<any>('SELECT * FROM trips WHERE id=?',t.id),ctx)};
  });
}
