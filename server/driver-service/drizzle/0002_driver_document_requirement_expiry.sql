ALTER TABLE "driver_document_requirements"
ADD COLUMN IF NOT EXISTS "requires_expiry" boolean DEFAULT false NOT NULL;
