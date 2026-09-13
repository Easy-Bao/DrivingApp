DO $migration$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM driver_profiles AS profiles
        LEFT JOIN driver_wallet_accounts AS accounts
            ON accounts.driver_id = profiles.user_id
        WHERE accounts.driver_id IS NULL
           OR profiles.wallet_balance_centavos <> accounts.balance_centavos
    ) THEN
        RAISE EXCEPTION 'driver wallet authority migration found unreconciled balances';
    END IF;
END
$migration$;

ALTER TABLE driver_profiles
    DROP COLUMN IF EXISTS wallet_balance_centavos;
