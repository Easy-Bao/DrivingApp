ALTER TABLE rides DROP CONSTRAINT rides_session_booking_reference_fkey;
ALTER TABLE rides DROP COLUMN booking_reference;
ALTER TABLE bid_sessions DROP COLUMN booking_reference;
DROP FUNCTION allocate_booking_reference();
DROP TABLE booking_references;
