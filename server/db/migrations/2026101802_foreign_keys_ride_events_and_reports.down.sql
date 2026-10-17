ALTER TABLE public.ride_reports
    DROP CONSTRAINT IF EXISTS ride_reports_reported_user_id_fkey,
    DROP CONSTRAINT IF EXISTS ride_reports_reporter_id_fkey,
    DROP CONSTRAINT IF EXISTS ride_reports_ride_id_fkey;

ALTER TABLE public.ride_events
    DROP CONSTRAINT IF EXISTS ride_events_actor_id_fkey,
    DROP CONSTRAINT IF EXISTS ride_events_ride_id_fkey;

ALTER TABLE public.rides
    DROP CONSTRAINT IF EXISTS rides_cancelled_by_fkey;
