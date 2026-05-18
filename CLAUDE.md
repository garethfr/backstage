# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Status

This is a **pre-implementation** repository. Currently only design documents exist under `docs/`. Implementation follows the ticket plan in `docs/backstage_architecture.md` (BACK-001 through BACK-042).

## What Backstage Is

A mountable Rails 8 engine gem providing a lightweight, zero-dependency admin interface. Host apps configure it via `config/backstage.yml` (model registration, dashboards) and optional `config/backstage/*.rb` per-resource DSL files. No code generation — one dynamic controller handles all resources via a registry.

## Commands

These commands apply once the gem skeleton (BACK-001) is in place:

```bash
bundle install                          # install dev dependencies
bundle exec rake test                   # run all tests
bundle exec ruby -I test test/path/to/test_file.rb  # run a single test file
bundle exec ruby -I test test/path/to/test_file.rb -n test_method_name  # run one test
bundle exec rake test:system            # Capybara system tests only
standardrb                              # lint (StandardRB, not RuboCop)
```

## Architecture

Three layers, all host-app agnostic — they operate through `Backstage::Registry`, never importing specific models directly.

### 1. Configuration Layer (boot-time)
- `lib/backstage/configuration.rb` — parses `config/backstage.yml` via `YAML.safe_load`
- `lib/backstage/auto_discovery.rb` — reflects on `model.columns` and `model.defined_enums` to build default field lists
- `lib/backstage/registry.rb` — singleton mapping model name strings → `ResourceConfig` instances
- `lib/backstage/resource_config.rb` — DSL evaluator; `fields`, `field`, `has_many`, `belongs_to`, `sidebar`, `actions` etc. mutate this object
- Boot sequence: parse YAML → `AutoDiscovery.build` for each model → load `config/backstage/*.rb` DSL files → register dashboards

### 2. Controller Layer (request-time)
- `Backstage::ApplicationController` — `before_action :verify_admin!` on every request
- `Backstage::ResourcesController` — handles all CRUD for all models via `current_resource_config` lookup
- `Backstage::ActionsController` — custom action dispatch; resolves host-app subclass via `"Backstage::#{model.name.pluralize}Controller".safe_constantize`, falls back to `Backstage::ResourcesController`
- Routes use a single dynamic `:resource` segment; the `:resource` param is validated against the registry (unknown name → 404)

### 3. View Layer (render-time)
- Field rendering dispatches via partial path: `render field.partial_path` where `partial_path` → `"backstage/fields/_#{type}"`
- Field partials live in `app/views/backstage/fields/` — one per type (`_string`, `_enum`, `_has_many`, `_belongs_to`, etc.)
- Host apps can override any engine view or field partial by placing a file at the same path in their own `app/views/`
- Layout at `app/views/layouts/backstage/backstage.html.erb`, referenced as `layout "backstage/backstage"` — host apps can override by placing a file at the same path in their own `app/views/layouts/backstage/`
- Pico CSS vendored in `app/assets/stylesheets/backstage/pico.css` (added in BACK-015)
- Two Stimulus controllers: `multi-select` (searchable checkbox list for `has_many`) and `confirm-action` (destructive action guard)

## Key Design Decisions

- **No per-model code generation** — dynamic routing + registry means adding a model to YAML is all that's needed
- **Single `ResourcesController`** — all CRUD flows through one controller using `current_resource_config`; host apps only subclass when they need custom actions
- **`field.partial_path` dispatch** — extension point for field types; `field :url, partial: "my_app/fields/custom"` works without gem changes
- **`YAML.safe_load`** — never `YAML.load` for config files
- **`permitted_params` built from `edit_fields`** — no `permit!`; mass assignment is restricted to explicitly configured fields
- **Pico CSS vendored** — not CDN-loaded; served via Propshaft

## Testing Approach

- **Unit tests**: `AutoDiscovery`, `ResourceConfig` DSL, `Registry`, `Configuration`
- **Controller tests**: all CRUD actions, custom action dispatch, auth filter behaviour
- **System tests** (`test/system/`): full flows via Capybara against the dummy app
- **Dummy app** (`test/dummy/`): minimal Rails 8 app with `Article` (all field types + enum) and `Tag` (for association tests) models

## Implementation Tickets

Detailed ticket specs are in `docs/backstage_architecture.md` under "10. Implementation Tickets". Milestones:

- **Milestone 1** (BACK-001–017): Gem skeleton, config, auto-discovery, registry, CRUD, Pico CSS, install generator, dummy app
- **Milestone 2** (BACK-018–028): DSL loader, field overrides, enum/belongs_to/has_many partials, Stimulus multi-select, thumbnails, sortable columns
- **Milestone 3** (BACK-029–036): Dashboards, sidebars, custom action routing, Turbo Stream responses, confirm-action Stimulus controller
- **Milestone 4** (BACK-037–042): README, bookmarklet docs, CHANGELOG, GitHub Actions publish workflow, contributing guide
