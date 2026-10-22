CREATE TABLE booking_references (
    reference text PRIMARY KEY,
    CONSTRAINT booking_references_format_check CHECK (reference ~ '^7016[0-9]{11}$')
);

-- Reserving in one namespace prevents independent ride and request creation
-- from allocating the same public reference, including under concurrency.
CREATE FUNCTION allocate_booking_reference() RETURNS text
LANGUAGE plpgsql VOLATILE AS $$
DECLARE
    candidate text;
    allocated text;
BEGIN
    LOOP
        candidate := '7016' || lpad(floor(random() * 100000000000)::bigint::text, 11, '0');
        INSERT INTO booking_references (reference) VALUES (candidate)
        ON CONFLICT DO NOTHING
        RETURNING reference INTO allocated;
        IF FOUND THEN
            RETURN allocated;
        END IF;
    END LOOP;
END;
$$;

ALTER TABLE bid_sessions
    ADD COLUMN booking_reference text NOT NULL DEFAULT allocate_booking_reference(),
    ADD CONSTRAINT bid_sessions_booking_reference_key UNIQUE (booking_reference),
    ADD CONSTRAINT bid_sessions_id_booking_reference_key UNIQUE (id, booking_reference),
    ADD CONSTRAINT bid_sessions_booking_reference_fkey
        FOREIGN KEY (booking_reference) REFERENCES booking_references (reference);

ALTER TABLE rides ADD COLUMN booking_reference text;
UPDATE rides AS ride
SET booking_reference = COALESCE(
    (SELECT session.booking_reference FROM bid_sessions AS session WHERE session.id = ride.bid_session_id),
    allocate_booking_reference()
);
ALTER TABLE rides
    ALTER COLUMN booking_reference SET NOT NULL,
    ALTER COLUMN booking_reference SET DEFAULT allocate_booking_reference(),
    ADD CONSTRAINT rides_booking_reference_key UNIQUE (booking_reference),
    ADD CONSTRAINT rides_booking_reference_fkey
        FOREIGN KEY (booking_reference) REFERENCES booking_references (reference),
    ADD CONSTRAINT rides_session_booking_reference_fkey
        FOREIGN KEY (bid_session_id, booking_reference) REFERENCES bid_sessions (id, booking_reference);
