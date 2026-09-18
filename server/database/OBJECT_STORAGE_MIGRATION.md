# Architectural Roadmap: Object Storage Migration

This document outlines the planned phased migration from inline relational binary storage to dedicated cloud/distributed object storage (S3 / MinIO / Google Cloud Storage) for driver verification documents and private avatars.

---

## 1. Current Architecture (Single-Process / Local Mode)

* **Storage Location**: PostgreSQL `private_objects` table (`content BYTEA`).
* **Metadata Location**: `driver_documents` table (`storage_key`, `checksum_sha256`, `size_bytes`, `status`).
* **Access Boundary**: Mediated strictly by backend services; no direct browser/client access.
* **Limitations at Scale**:
  - Binary payloads (up to 10MB per KYC document) inflate PostgreSQL write-ahead logs (WAL).
  - Database backup snapshots become excessively large.
  - Read queries for large documents evict hot relational rows from the PostgreSQL buffer pool (`shared_buffers`).

---

## 2. Target Scaled Architecture (S3 / MinIO Object Storage)

```
┌─────────────────┐       1. Request Upload URL        ┌─────────────────────────┐
│  Mobile Client  ├───────────────────────────────────►│  Backend API Gateway   │
│ (Passenger/     │                                    │  (Validates KYC Scope)  │
│  Driver App)    │◄───────────────────────────────────┤                         │
└────────┬────────┘       2. Pre-signed PUT URL        └───────────┬─────────────┘
         │                                                         │
         │ 3. Direct Binary Upload (S3/MinIO)                      │ 4. Persist
         ▼                                                         │    Metadata
┌─────────────────────────┐                                        ▼
│  S3 / MinIO Bucket      │                              ┌───────────────────┐
│ (Encrypted at Rest,     │◄─────────────────────────────┤  PostgreSQL 16    │
│  Private Bucket Access) │   Verify Checksum on Review  │ (Metadata Only,   │
└─────────────────────────┘                              │  Zero BYTEA Blobs)│
                                                         └───────────────────┘
```

---

## 3. Phased Migration Plan

### Phase A: Adapter Seam Preservation
- The outbound port `ObjectStore` interface in `internal/platform/storage/object_store.go` remains the single contract.
- Introduce an `s3` adapter implementing `ObjectStore` alongside the current `postgres` adapter.

### Phase B: Schema Transition
1. Introduce bucket URI / external key column to `private_objects` (or `driver_documents`).
2. Dual-write or direct upload: New document uploads stream to S3/MinIO; historical objects read from PostgreSQL fallback.
3. Background worker syncs historical binary rows to object storage.

### Phase C: Dropping Binary Blobs
- Execute an additive database migration to drop the `content BYTEA` column from `private_objects`.
- Reclaim table disk space via `VACUUM FULL`.
