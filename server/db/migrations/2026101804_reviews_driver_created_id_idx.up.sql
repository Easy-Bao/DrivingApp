CREATE INDEX IF NOT EXISTS reviews_driver_created_id_idx
    ON public.reviews (driver_id, created_at DESC, id DESC);
