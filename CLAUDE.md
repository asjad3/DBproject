# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**DisasterLink** is a disaster management and relief coordination system. Currently in the database schema design phase — the repo contains only ERD diagrams (DrawIO, PNG, SVG).

## Database Schema

The schema is a relational design with these entity groups:

- **Disaster core**: `DisasterType`, `Disaster`, `DisasterLocation`, `ReliefCamp`
- **Relief operations**: `ReliefProgram`, `ResourceRequirement`, `Product`, `Commitment`, `Fulfillment`
- **Organizations**: `Organization` (with subtypes `GovernmentUnit` / `NonGovOrg`), `OrgCategory`, `ProgramEnrollment`, `FieldTeam`
- **Beneficiaries**: `Beneficiary`, `AidDistribution`
- **Monitoring**: `IncidentReport`, `AuditLog` (trigger-maintained)

Key design patterns used:
- ENUM types for status/severity fields
- Composite keys and weak entities
- Trigger-maintained audit logging
- Inheritance modeled via subtypes on `Organization`

## Planned Stack

No implementation code exists yet. When building out:
- Database: SQL (PostgreSQL preferred given schema complexity)
- DDL scripts should go in a `sql/` or `db/` directory
- Seed/migration files should be versioned
