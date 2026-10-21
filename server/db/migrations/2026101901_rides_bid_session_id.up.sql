ALTER TABLE public.rides
    ADD COLUMN bid_session_id integer;

ALTER TABLE public.rides
    ADD CONSTRAINT rides_bid_session_fk
    FOREIGN KEY (bid_session_id) REFERENCES public.bid_sessions (id) ON DELETE RESTRICT;

CREATE UNIQUE INDEX rides_bid_session_id_idx
    ON public.rides (bid_session_id)
    WHERE bid_session_id IS NOT NULL;
