CREATE INDEX IF NOT EXISTS rides_passenger_created_id_desc_idx
    ON rides (passenger_id, created_at DESC, id DESC);

CREATE INDEX IF NOT EXISTS rides_driver_created_id_desc_idx
    ON rides (driver_id, created_at DESC, id DESC)
    WHERE driver_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS rides_passenger_completed_id_desc_idx
    ON rides (passenger_id, id DESC)
    WHERE status = 'completed';

CREATE INDEX IF NOT EXISTS notifications_user_id_id_desc_idx
    ON notifications (user_id, id DESC);

CREATE INDEX IF NOT EXISTS notifications_user_unread_idx
    ON notifications (user_id)
    WHERE is_read = false;

CREATE INDEX IF NOT EXISTS bid_offers_driver_pending_id_idx
    ON bid_offers (driver_id, id)
    WHERE status = 'pending';
