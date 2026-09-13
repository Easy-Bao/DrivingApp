DO $migration$
BEGIN
    IF EXISTS (SELECT 1 FROM bids LIMIT 1) THEN
        RAISE EXCEPTION 'legacy bids migration found rows that must be migrated first';
    END IF;
END
$migration$;

DROP TABLE IF EXISTS bids;
