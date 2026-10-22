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
