# Transformation Workbench

## What this is
The working realisation of the Intelligence Layer blueprint into an interactive workbench.

## Blueprint reference
The blueprint (design intent, narrative structure, design system) lives at:
- Local: ~/Intelligence Layer/index.html
- Live: https://abh1nan9an.github.io/transformation-workbench/
When uncertain about design intent, always read the blueprint first.

## Build inputs (read these before any work)
All specs live in /docs:
1. pandora_transformation_workbench_claude_code_prompt.md — master build prompt
2. pandora_transformation_workbench_v0_build_spec.md — full product spec
3. pandora_transformation_workbench_schema.sql — Postgres/Supabase schema
4. pandora_workbench_design_tokens.css — design token CSS
5. Pandora — Universal Design System.pdf — visual design system reference

## Design system
Pandora Universal Design System:
- Typography: Cormorant Garamond (headings) + Source Sans 3 (body)
- Palette: Warm charcoal #2D2926, powder pink #E8B4BC, soft cream #FAF6F1
- Interactions: Progressive disclosure, slide-in panels, connected highlighting

## Stack
Next.js, TypeScript, Supabase, TanStack Query, React Hook Form + Zod, shadcn/ui restyled to Pandora tokens

## Six surfaces
1. Landscape Overview
2. Initiative Workspace
3. Decision Studio
4. Dependency Map
5. Readiness Radar
6. Investigation & Reconciliation Hub
