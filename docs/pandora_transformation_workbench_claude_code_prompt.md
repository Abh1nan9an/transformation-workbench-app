# Claude Code Build Prompt — Pandora Transformation Workbench v0

You are building a real internal portal called **Pandora Transformation Workbench**.

Read these files first and treat them as hard inputs:
1. `pandora_transformation_workbench_v0_build_spec.md`
2. `pandora_transformation_workbench_schema.sql`
3. `pandora_workbench_design_tokens.css`

## Important posture
Do **not** collapse this into a generic CRUD admin panel.
Do **not** build a narrow website layout.
Do **not** ignore placeholder objects and future depth.

This must feel like a **premium Pandora internal platform**:
- warm,
- restrained,
- spacious,
- full-width,
- desktop-first,
- object-backed,
- evidence-aware.

## Product truths you must preserve
- There are exactly **six product surfaces**:
  1. Landscape Overview
  2. Initiative Workspace
  3. Decision Studio
  4. Dependency Map
  5. Readiness Radar
  6. Investigation & Reconciliation Hub
- **Initiative** is the canonical root object.
- The system must support real authentication and permissions.
- The workflow is **draft → workshop → reconcile**.
- Evidence, provenance, and audit are first-class.
- The schema must preserve placeholders even if UI depth is thin in v0.
- Default target is **1920×1080**.

## Recommended stack
- Next.js
- TypeScript
- Supabase
- Postgres
- TanStack Query
- React Hook Form + Zod
- shadcn/ui primitives restyled to Pandora tokens
- React Flow or Cytoscape for graph views

## Build order
1. Create application shell with full-width layout and Pandora tokens
2. Implement auth and role-aware navigation
3. Implement the six surfaces as real routes
4. Implement initiative CRUD and seeded Aurora data
5. Implement decisions, dependencies, readiness signals, investigations, workshops, claims, evidence
6. Implement cross-linking and provenance display
7. Implement audit log and saved views
8. Harden empty states, loading states, and role-based restrictions

## UX rules
- Use warm cream cards with powder pink borders
- Use serif headings and humanist sans body
- Use generous spacing
- Use subdued motion only
- Use a right context drawer for detail where useful
- Avoid dense dashboard clutter
- Equal cards must have equal styling
- Use pink as an accent, never as a loud fill

## Seed expectations
Create seeded content for:
- Aurora
- Orbit
- Hero
- Compass
- MCOO

With:
- shared domains
- example decisions
- example dependencies
- example readiness signals
- example investigations

## Engineering output expectation
Produce:
- app shell
- routes
- schema migrations
- seed script
- reusable components
- role-aware guards
- placeholder hooks for later AI ingestion

If a feature is too deep for v0, leave the route, object support, and placeholder structure in place rather than deleting it.