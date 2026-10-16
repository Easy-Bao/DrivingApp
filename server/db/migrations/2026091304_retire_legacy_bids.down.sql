DO $migration$
BEGIN
    RAISE EXCEPTION 'legacy bids retirement is irreversible because the old table and its data were removed';
END
$migration$;
