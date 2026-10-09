DO $migration$
BEGIN
    RAISE EXCEPTION 'cannot restore private_objects.content after the PostgreSQL object copies were removed';
END
$migration$;
