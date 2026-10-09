ALTER TABLE users
    ADD CONSTRAINT users_role_check
    CHECK (role IN ('passenger', 'driver')) NOT VALID;

ALTER TABLE users
    VALIDATE CONSTRAINT users_role_check;
