-- Migration: Adds password_hash column to passengers table.
ALTER TABLE passengers ADD COLUMN password_hash VARCHAR(255) NOT NULL DEFAULT '';
