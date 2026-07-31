# EasyRide ticket records

This directory records substantial implementation work that needs to remain
understandable across development sessions. It does not contain credentials,
secret values, test-account details, or personal identity data.

## Record types

- **Reconstructed ticket**: a later, evidence-based decomposition of code that
  was originally delivered in a broader change.
- **Active ticket**: work currently being implemented or verified.
- **Planned ticket**: agreed work that has not started.

A reconstructed ticket improves traceability, but it does not rewrite Git
history or claim that the original work was actually committed in that order.

## Implementation maturity

- **In progress**: work is currently changing.
- **Foundation present**: the main structure exists, but meaningful workflow
  implementation is still missing.
- **Partial prototype**: some real behavior exists, but known requirements,
  contracts, or failure handling are missing.
- **Substantial prototype**: the main intended workflow is represented in code,
  but it has not met complete acceptance criteria.
- **Accepted**: every stated requirement and acceptance criterion has passed.
- **Blocked**: a named product decision or external dependency prevents useful
  progress.

The presence of a file, route, screen, migration, or test does not by itself
make a ticket implemented.

## Verification level

- **Not run**: no relevant check has been recorded.
- **Focused checks**: isolated unit, type, build, or helper checks exist.
- **Integration checked**: the relevant real services and disposable database
  have been exercised together.
- **End-to-end accepted**: the complete user workflow passed on the intended
  clients and services.

Implementation maturity and verification are separate. Verification can expose
new implementation work; it is not a promise that the remaining task is merely
running tests. Authentication, money, assignment, migration, and cross-service
tickets require negative, retry, concurrency, and integration checks before
they can be accepted.

## Required ticket content

Each substantial ticket records:

1. Goal and user-visible outcome.
2. Dependencies.
3. Included scope and non-goals.
4. Concrete repository evidence.
5. Acceptance criteria.
6. Verification already performed.
7. Remaining gaps or decisions.

Future branches, commits, and pull requests should mention the applicable
ticket ID. A ticket may span multiple services when one business invariant
requires an atomic cross-service workflow, but unrelated work belongs in a
different ticket.

## Registers

- [Admin prototype ticket register](admin-prototype.md)
