DROP INDEX IF EXISTS public.rides_bid_session_id_idx;

ALTER TABLE public.rides
    DROP CONSTRAINT IF EXISTS rides_bid_session_fk;

ALTER TABLE public.rides
    DROP COLUMN IF EXISTS bid_session_id;
