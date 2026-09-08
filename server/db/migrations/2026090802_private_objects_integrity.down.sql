DO $migration$
BEGIN
    RAISE EXCEPTION 'private_objects integrity modernization is irreversible because it may widen stored values and replaces the serial sequence with an identity sequence';
END
$migration$;
