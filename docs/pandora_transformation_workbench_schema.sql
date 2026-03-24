-- Pandora Transformation Workbench — schema scaffold
-- v0 relational backbone with preserved placeholders
-- Target: PostgreSQL / Supabase

create extension if not exists "pgcrypto";

-- -------------------------------------------------------------------
-- Enums
-- -------------------------------------------------------------------

do $$ begin
    create type visibility_level as enum ('internal', 'restricted', 'external_placeholder');
exception when duplicate_object then null; end $$;

do $$ begin
    create type initiative_status as enum ('draft', 'workshop_ready', 'in_workshop', 'reconciled', 'active', 'parked', 'archived');
exception when duplicate_object then null; end $$;

do $$ begin
    create type decision_status as enum ('candidate', 'framed', 'in_review', 'confirmed', 'disputed', 'superseded', 'archived');
exception when duplicate_object then null; end $$;

do $$ begin
    create type dependency_status as enum ('hypothesised', 'observed', 'validated', 'disputed', 'retired');
exception when duplicate_object then null; end $$;

do $$ begin
    create type readiness_band as enum ('unknown', 'low', 'medium', 'high', 'blocked');
exception when duplicate_object then null; end $$;

do $$ begin
    create type investigation_status as enum ('queued', 'triaged', 'in_progress', 'blocked', 'answered', 'closed', 'archived');
exception when duplicate_object then null; end $$;

do $$ begin
    create type claim_validation_state as enum ('extracted', 'proposed', 'validated', 'disputed', 'rejected', 'archived');
exception when duplicate_object then null; end $$;

do $$ begin
    create type workshop_status as enum ('planned', 'in_progress', 'completed', 'reconciled', 'archived');
exception when duplicate_object then null; end $$;

do $$ begin
    create type membership_role as enum ('workspace_admin', 'programme_lead', 'initiative_owner', 'workstream_lead', 'contributor', 'reviewer', 'viewer', 'external_partner');
exception when duplicate_object then null; end $$;

do $$ begin
    create type surface_name as enum ('landscape_overview', 'initiative_workspace', 'decision_studio', 'dependency_map', 'readiness_radar', 'investigation_reconciliation_hub');
exception when duplicate_object then null; end $$;

do $$ begin
    create type source_type as enum ('deck', 'document', 'transcript', 'tracker', 'note', 'image', 'spreadsheet', 'link', 'other');
exception when duplicate_object then null; end $$;

do $$ begin
    create type entity_type as enum (
        'initiative', 'domain', 'capability', 'system', 'decision', 'dependency',
        'readiness_signal', 'investigation', 'workshop', 'workshop_pass',
        'claim', 'evidence_source', 'evidence_excerpt', 'journey_template',
        'scenario', 'metric', 'milestone'
    );
exception when duplicate_object then null; end $$;

-- -------------------------------------------------------------------
-- Core workspace and people
-- -------------------------------------------------------------------

create table if not exists workspaces (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    slug text not null unique,
    status text not null default 'active',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists users (
    id uuid primary key,
    email text unique,
    display_name text,
    avatar_url text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists teams (
    id uuid primary key default gen_random_uuid(),
    workspace_id uuid not null references workspaces(id) on delete cascade,
    name text not null,
    slug text not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique(workspace_id, slug)
);

create table if not exists workspace_memberships (
    id uuid primary key default gen_random_uuid(),
    workspace_id uuid not null references workspaces(id) on delete cascade,
    user_id uuid not null references users(id) on delete cascade,
    role membership_role not null,
    visibility visibility_level not null default 'internal',
    created_at timestamptz not null default now(),
    unique(workspace_id, user_id, role)
);

create table if not exists team_memberships (
    id uuid primary key default gen_random_uuid(),
    team_id uuid not null references teams(id) on delete cascade,
    user_id uuid not null references users(id) on delete cascade,
    created_at timestamptz not null default now(),
    unique(team_id, user_id)
);

-- -------------------------------------------------------------------
-- Core entities
-- -------------------------------------------------------------------

create table if not exists initiatives (
    id uuid primary key default gen_random_uuid(),
    workspace_id uuid not null references workspaces(id) on delete cascade,
    slug text not null,
    name text not null,
    short_name text,
    description text,
    objective text,
    programme text,
    priority integer,
    status initiative_status not null default 'draft',
    visibility visibility_level not null default 'internal',
    owner_user_id uuid references users(id),
    sponsor_user_id uuid references users(id),
    business_value_summary text,
    scope_summary text,
    known_unknowns jsonb not null default '[]'::jsonb,
    metadata jsonb not null default '{}'::jsonb,
    created_by uuid references users(id),
    updated_by uuid references users(id),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    archived_at timestamptz,
    unique(workspace_id, slug)
);

create table if not exists domains (
    id uuid primary key default gen_random_uuid(),
    workspace_id uuid not null references workspaces(id) on delete cascade,
    name text not null,
    description text,
    domain_type text,
    status text not null default 'active',
    metadata jsonb not null default '{}'::jsonb,
    created_by uuid references users(id),
    updated_by uuid references users(id),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique(workspace_id, name)
);

create table if not exists capabilities (
    id uuid primary key default gen_random_uuid(),
    workspace_id uuid not null references workspaces(id) on delete cascade,
    name text not null,
    description text,
    capability_type text,
    parent_capability_id uuid references capabilities(id),
    status text not null default 'active',
    metadata jsonb not null default '{}'::jsonb,
    created_by uuid references users(id),
    updated_by uuid references users(id),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique(workspace_id, name)
);

create table if not exists systems (
    id uuid primary key default gen_random_uuid(),
    workspace_id uuid not null references workspaces(id) on delete cascade,
    name text not null,
    description text,
    system_type text,
    vendor text,
    lifecycle text,
    criticality text,
    status text not null default 'active',
    metadata jsonb not null default '{}'::jsonb,
    created_by uuid references users(id),
    updated_by uuid references users(id),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique(workspace_id, name)
);

create table if not exists decisions (
    id uuid primary key default gen_random_uuid(),
    workspace_id uuid not null references workspaces(id) on delete cascade,
    initiative_id uuid references initiatives(id) on delete set null,
    title text not null,
    statement text not null,
    decision_type text,
    status decision_status not null default 'candidate',
    owner_user_id uuid references users(id),
    due_date date,
    confidence smallint check (confidence between 0 and 100),
    rationale text,
    implications_summary text,
    created_by uuid references users(id),
    updated_by uuid references users(id),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists decision_options (
    id uuid primary key default gen_random_uuid(),
    decision_id uuid not null references decisions(id) on delete cascade,
    label text not null,
    description text,
    pros text,
    cons text,
    estimated_complexity text,
    estimated_risk text,
    recommended_flag boolean not null default false,
    status text not null default 'active',
    sort_order integer not null default 0,
    created_at timestamptz not null default now()
);

create table if not exists dependencies (
    id uuid primary key default gen_random_uuid(),
    workspace_id uuid not null references workspaces(id) on delete cascade,
    source_entity_type entity_type not null,
    source_entity_id uuid not null,
    target_entity_type entity_type not null,
    target_entity_id uuid not null,
    dependency_type text not null,
    direction text not null default 'source_to_target',
    severity text,
    confidence smallint check (confidence between 0 and 100),
    status dependency_status not null default 'hypothesised',
    rationale text,
    discovered_in_workshop_pass_id uuid,
    created_by uuid references users(id),
    updated_by uuid references users(id),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists readiness_signals (
    id uuid primary key default gen_random_uuid(),
    workspace_id uuid not null references workspaces(id) on delete cascade,
    assessed_entity_type entity_type not null,
    assessed_entity_id uuid not null,
    dimension text not null,
    score_numeric numeric(5,2),
    score_band readiness_band not null default 'unknown',
    confidence smallint check (confidence between 0 and 100),
    status text not null default 'captured',
    rationale text,
    owner_user_id uuid references users(id),
    captured_from_workshop_pass_id uuid,
    reviewed_at timestamptz,
    stale_after_at timestamptz,
    metadata jsonb not null default '{}'::jsonb,
    created_by uuid references users(id),
    updated_by uuid references users(id),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists investigations (
    id uuid primary key default gen_random_uuid(),
    workspace_id uuid not null references workspaces(id) on delete cascade,
    initiative_id uuid references initiatives(id) on delete set null,
    title text not null,
    question text not null,
    category text,
    priority text,
    status investigation_status not null default 'queued',
    owner_user_id uuid references users(id),
    due_date date,
    blocking_flag boolean not null default false,
    resolution_summary text,
    created_from_entity_type entity_type,
    created_from_entity_id uuid,
    created_from_workshop_pass_id uuid,
    created_by uuid references users(id),
    updated_by uuid references users(id),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists workshops (
    id uuid primary key default gen_random_uuid(),
    workspace_id uuid not null references workspaces(id) on delete cascade,
    initiative_id uuid not null references initiatives(id) on delete cascade,
    title text not null,
    workshop_type text,
    scheduled_at timestamptz,
    started_at timestamptz,
    completed_at timestamptz,
    status workshop_status not null default 'planned',
    facilitator_user_id uuid references users(id),
    notes text,
    created_by uuid references users(id),
    updated_by uuid references users(id),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists workshop_passes (
    id uuid primary key default gen_random_uuid(),
    workshop_id uuid not null references workshops(id) on delete cascade,
    pass_type text not null,
    sequence_number integer not null default 1,
    title text not null,
    objective text,
    status text not null default 'planned',
    summary text,
    started_at timestamptz,
    completed_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique(workshop_id, sequence_number)
);

create table if not exists claims (
    id uuid primary key default gen_random_uuid(),
    workspace_id uuid not null references workspaces(id) on delete cascade,
    initiative_id uuid references initiatives(id) on delete set null,
    title text not null,
    statement text not null,
    claim_type text,
    confidence smallint check (confidence between 0 and 100),
    validation_state claim_validation_state not null default 'extracted',
    owner_user_id uuid references users(id),
    created_from_source_id uuid,
    created_from_workshop_pass_id uuid,
    created_by uuid references users(id),
    updated_by uuid references users(id),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists evidence_sources (
    id uuid primary key default gen_random_uuid(),
    workspace_id uuid not null references workspaces(id) on delete cascade,
    initiative_id uuid references initiatives(id) on delete set null,
    title text not null,
    source_type source_type not null,
    storage_path text,
    source_url text,
    mime_type text,
    uploaded_by_user_id uuid references users(id),
    uploaded_at timestamptz not null default now(),
    ingestion_status text not null default 'uploaded',
    extraction_status text not null default 'not_started',
    checksum text,
    metadata jsonb not null default '{}'::jsonb
);

create table if not exists evidence_excerpts (
    id uuid primary key default gen_random_uuid(),
    evidence_source_id uuid not null references evidence_sources(id) on delete cascade,
    excerpt_text text not null,
    page_ref text,
    slide_ref text,
    timestamp_ref text,
    locator_json jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now()
);

-- -------------------------------------------------------------------
-- Explicit relation tables
-- -------------------------------------------------------------------

create table if not exists initiative_domains (
    initiative_id uuid not null references initiatives(id) on delete cascade,
    domain_id uuid not null references domains(id) on delete cascade,
    relation_type text not null default 'touches',
    confidence smallint check (confidence between 0 and 100),
    created_at timestamptz not null default now(),
    primary key (initiative_id, domain_id, relation_type)
);

create table if not exists initiative_capabilities (
    initiative_id uuid not null references initiatives(id) on delete cascade,
    capability_id uuid not null references capabilities(id) on delete cascade,
    relation_type text not null default 'touches',
    confidence smallint check (confidence between 0 and 100),
    created_at timestamptz not null default now(),
    primary key (initiative_id, capability_id, relation_type)
);

create table if not exists initiative_systems (
    initiative_id uuid not null references initiatives(id) on delete cascade,
    system_id uuid not null references systems(id) on delete cascade,
    relation_type text not null default 'uses',
    confidence smallint check (confidence between 0 and 100),
    created_at timestamptz not null default now(),
    primary key (initiative_id, system_id, relation_type)
);

create table if not exists initiative_adjacent_initiatives (
    initiative_id uuid not null references initiatives(id) on delete cascade,
    adjacent_initiative_id uuid not null references initiatives(id) on delete cascade,
    relation_type text not null default 'adjacent_to',
    created_at timestamptz not null default now(),
    primary key (initiative_id, adjacent_initiative_id, relation_type)
);

create table if not exists decision_impacts (
    id uuid primary key default gen_random_uuid(),
    decision_id uuid not null references decisions(id) on delete cascade,
    impacted_entity_type entity_type not null,
    impacted_entity_id uuid not null,
    impact_type text not null default 'affects',
    severity text,
    created_at timestamptz not null default now()
);

create table if not exists investigation_entities (
    id uuid primary key default gen_random_uuid(),
    investigation_id uuid not null references investigations(id) on delete cascade,
    entity_type entity_type not null,
    entity_id uuid not null,
    relation_type text not null default 'concerns',
    created_at timestamptz not null default now()
);

create table if not exists claim_entities (
    id uuid primary key default gen_random_uuid(),
    claim_id uuid not null references claims(id) on delete cascade,
    entity_type entity_type not null,
    entity_id uuid not null,
    relation_type text not null default 'about',
    created_at timestamptz not null default now()
);

create table if not exists claim_evidence (
    id uuid primary key default gen_random_uuid(),
    claim_id uuid not null references claims(id) on delete cascade,
    evidence_excerpt_id uuid references evidence_excerpts(id) on delete set null,
    evidence_source_id uuid references evidence_sources(id) on delete set null,
    relation_type text not null default 'supported_by',
    created_at timestamptz not null default now()
);

-- -------------------------------------------------------------------
-- Generic graph and collaboration
-- -------------------------------------------------------------------

create table if not exists entity_links (
    id uuid primary key default gen_random_uuid(),
    workspace_id uuid not null references workspaces(id) on delete cascade,
    source_entity_type entity_type not null,
    source_entity_id uuid not null,
    target_entity_type entity_type not null,
    target_entity_id uuid not null,
    link_type text not null,
    confidence smallint check (confidence between 0 and 100),
    metadata jsonb not null default '{}'::jsonb,
    created_by uuid references users(id),
    created_at timestamptz not null default now()
);

create table if not exists comments (
    id uuid primary key default gen_random_uuid(),
    workspace_id uuid not null references workspaces(id) on delete cascade,
    entity_type entity_type not null,
    entity_id uuid not null,
    parent_comment_id uuid references comments(id) on delete cascade,
    body text not null,
    created_by uuid references users(id),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists attachments (
    id uuid primary key default gen_random_uuid(),
    workspace_id uuid not null references workspaces(id) on delete cascade,
    entity_type entity_type not null,
    entity_id uuid not null,
    title text not null,
    storage_path text not null,
    mime_type text,
    uploaded_by uuid references users(id),
    created_at timestamptz not null default now()
);

create table if not exists tags (
    id uuid primary key default gen_random_uuid(),
    workspace_id uuid not null references workspaces(id) on delete cascade,
    name text not null,
    color_token text,
    created_at timestamptz not null default now(),
    unique(workspace_id, name)
);

create table if not exists entity_tags (
    tag_id uuid not null references tags(id) on delete cascade,
    entity_type entity_type not null,
    entity_id uuid not null,
    created_at timestamptz not null default now(),
    primary key (tag_id, entity_type, entity_id)
);

create table if not exists saved_views (
    id uuid primary key default gen_random_uuid(),
    workspace_id uuid not null references workspaces(id) on delete cascade,
    created_by uuid references users(id),
    title text not null,
    surface surface_name not null,
    filters jsonb not null default '{}'::jsonb,
    layout_state jsonb not null default '{}'::jsonb,
    is_shared boolean not null default false,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists audit_events (
    id uuid primary key default gen_random_uuid(),
    workspace_id uuid not null references workspaces(id) on delete cascade,
    actor_user_id uuid references users(id),
    entity_type entity_type not null,
    entity_id uuid not null,
    action text not null,
    before_json jsonb,
    after_json jsonb,
    metadata jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now()
);

-- -------------------------------------------------------------------
-- Placeholders preserved for future activation
-- -------------------------------------------------------------------

create table if not exists notifications (
    id uuid primary key default gen_random_uuid(),
    workspace_id uuid not null references workspaces(id) on delete cascade,
    user_id uuid references users(id),
    title text not null,
    body text,
    status text not null default 'unread',
    created_at timestamptz not null default now()
);

create table if not exists tasks (
    id uuid primary key default gen_random_uuid(),
    workspace_id uuid not null references workspaces(id) on delete cascade,
    title text not null,
    description text,
    status text not null default 'queued',
    owner_user_id uuid references users(id),
    due_date date,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists milestones (
    id uuid primary key default gen_random_uuid(),
    workspace_id uuid not null references workspaces(id) on delete cascade,
    initiative_id uuid references initiatives(id) on delete set null,
    title text not null,
    milestone_date date,
    status text not null default 'planned',
    metadata jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now()
);

create table if not exists scenarios (
    id uuid primary key default gen_random_uuid(),
    workspace_id uuid not null references workspaces(id) on delete cascade,
    initiative_id uuid references initiatives(id) on delete set null,
    title text not null,
    description text,
    status text not null default 'draft',
    metadata jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now()
);

create table if not exists metrics (
    id uuid primary key default gen_random_uuid(),
    workspace_id uuid not null references workspaces(id) on delete cascade,
    initiative_id uuid references initiatives(id) on delete set null,
    name text not null,
    metric_type text,
    value_numeric numeric(12,2),
    value_text text,
    observed_at timestamptz,
    metadata jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now()
);

-- -------------------------------------------------------------------
-- Helpful indexes
-- -------------------------------------------------------------------

create index if not exists idx_initiatives_workspace on initiatives(workspace_id, status);
create index if not exists idx_decisions_workspace on decisions(workspace_id, status);
create index if not exists idx_dependencies_workspace on dependencies(workspace_id, status);
create index if not exists idx_readiness_workspace on readiness_signals(workspace_id, score_band);
create index if not exists idx_investigations_workspace on investigations(workspace_id, status);
create index if not exists idx_claims_workspace on claims(workspace_id, validation_state);
create index if not exists idx_entity_links_workspace on entity_links(workspace_id, link_type);
create index if not exists idx_saved_views_surface on saved_views(workspace_id, surface);

-- -------------------------------------------------------------------
-- Minimal seed comments
-- -------------------------------------------------------------------
-- Seed at least one workspace and the Aurora initiative pack during bootstrapping.
-- Then add Orbit, Hero, Compass, and MCOO as adjacent initiatives plus shared domains.