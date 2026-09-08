DO $migration$
BEGIN
    RAISE EXCEPTION 'the native schema baseline is irreversible because it adopts existing application data';
END
$migration$;
