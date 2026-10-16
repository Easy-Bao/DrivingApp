CREATE INDEX CONCURRENTLY IF NOT EXISTS driver_document_reviewer_id_idx
    ON driver_documents (reviewed_by)
    WHERE reviewed_by IS NOT NULL;
