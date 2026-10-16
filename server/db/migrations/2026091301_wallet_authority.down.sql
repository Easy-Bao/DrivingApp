DO $migration$
BEGIN
    RAISE EXCEPTION 'driver wallet authority migration is irreversible because the legacy profile balance was removed';
END
$migration$;
