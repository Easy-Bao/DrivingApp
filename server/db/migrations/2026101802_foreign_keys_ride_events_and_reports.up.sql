ALTER TABLE public.rides
    ADD CONSTRAINT rides_cancelled_by_fkey
    FOREIGN KEY (cancelled_by) REFERENCES public.users (id) ON DELETE SET NULL;

ALTER TABLE public.ride_events
    ADD CONSTRAINT ride_events_ride_id_fkey
    FOREIGN KEY (ride_id) REFERENCES public.rides (id) ON DELETE CASCADE,
    ADD CONSTRAINT ride_events_actor_id_fkey
    FOREIGN KEY (actor_id) REFERENCES public.users (id) ON DELETE RESTRICT;

ALTER TABLE public.ride_reports
    ADD CONSTRAINT ride_reports_ride_id_fkey
    FOREIGN KEY (ride_id) REFERENCES public.rides (id) ON DELETE CASCADE,
    ADD CONSTRAINT ride_reports_reporter_id_fkey
    FOREIGN KEY (reporter_id) REFERENCES public.users (id) ON DELETE RESTRICT,
    ADD CONSTRAINT ride_reports_reported_user_id_fkey
    FOREIGN KEY (reported_user_id) REFERENCES public.users (id) ON DELETE RESTRICT;
