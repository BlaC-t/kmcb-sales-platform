# Project agent guidance

## Current phase

This repository is in design review. Do not implement business code until `docs/sales-platform/design.md` is approved and the blocking questions in `docs/15-open-questions.md` have owners/answers.

## Non-negotiable boundaries

- Algorithm candidates are not formal engineering designs.
- Sales selection creates an engineering revision; it never mutates the candidate.
- Only an approved revision can create an immutable sales release package.
- Published requirements, equipment specs, cases, rules and releases are not edited in place.
- AI/OCR output writes to staging and requires human review before publication.
- Electron Renderer never connects to MySQL or receives unrestricted Node/Electron APIs. Only the central Node API may access the dedicated schema on server 121.
- Do not invent mineral-processing rules, equipment limits or BMS integration contracts.

## Design validation

```text
node scripts/check-docs.mjs
```

The MySQL DDL targets MySQL 8.0.16+ and must be tested against an empty temporary instance matching server 121 before implementation. Never run design DDL directly on 121 without an approved migration and backup/change window.

## Source of truth

- Architecture decision: `docs/sales-platform/design.md`
- Database: `database/001_initial_schema.sql`
- REST API: `contracts/openapi.yaml`
- Events: `contracts/events.asyncapi.yaml`
- Product scope and acceptance: `docs/01-product-requirements.md` and `docs/12-test-and-acceptance.md`
