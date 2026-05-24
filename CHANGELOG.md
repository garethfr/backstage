# Changelog

All notable changes to this project will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.10] — 2026-05-25

### Fixed

- Dashboard pages now use the same windowed pagination (5 pages around current + first/last links) as resource index pages; pagination logic extracted into a shared `backstage/shared/_pagination` partial
- Sidebar no longer renders on index, dashboard, or new-record pages; proc-based sidebar links were crashing with `NoMethodError` when `@record` was nil — sidebar is now guarded with `record&.persisted?`

## [0.1.9] — 2026-05-24

### Fixed

- `belongs_to` and `field` no longer append to `index_fields` when `fields(...)` has already been called explicitly; previously calling `c.fields :name, :address` then `c.field :col, as: :tristate_boolean` would silently add the new field back onto the index list

## [0.1.8] — 2026-05-23

### Fixed

- `record_params` now uses `model_name.param_key` instead of `params[:resource].singularize` to derive the form parameter key, fixing `ActionController::ParameterMissing` when the resource URL uses a singular-capitalised name (e.g. `/admin/Resto/:id`)

## [0.1.7] — 2026-05-19

### Changed

- Pagination now shows a windowed range of 5 pages centred on the current page, plus permanent first and last page links, instead of listing every page number
- Page links are spaced apart to prevent them running together

## [0.1.6] — 2026-05-19

### Added

- `belongs_to` associations now render as a linked display name on the index page (e.g. "Alice" linking to the related record's edit page) instead of the raw foreign key integer

### Fixed

- `AutoDiscovery#build` now assigns independent arrays to `index_fields` and `edit_fields`; previously they shared the same object, causing edits to one to silently affect the other

## [0.1.5] — 2026-05-19

### Fixed

- `Backstage.resource` no longer raises if called before `load_configuration!` has run (guards against nil registry)

## [0.1.4] — 2026-05-19

### Fixed

- Engine no longer crashes during boot when no database connection is available (`ActiveRecord::ConnectionNotEstablished`, `ActiveRecord::NoDatabaseError`); logs a warning instead

## [0.1.3] — 2026-05-19

### Fixed

- CSS grid layout: nav and main now have explicit grid positions so they render side-by-side correctly
- Pico CSS override: nav list forced to vertical (`flex-direction: column`) instead of horizontal
- Engine layout: page title is now dynamic (`AppName — Backstage Admin`) instead of the static "Backstage"
- Engine layout: header home link uses `backstage.root_path` (engine-namespaced route) instead of bare `root_path`

## [0.1.2] — 2026-05-19

### Added

- `backstage:install` generator now creates `config/initializers/backstage.rb` with a stub `current_user` implementation and inline examples for Devise, session, and Current attributes
- `backstage:install` generator copies a Claude Code guided-setup skill to `.claude/skills/backstage-install/SKILL.md`

### Fixed

- Boot no longer crashes when a registered model's database table does not exist; the model is skipped with a warning instead

## [0.1.0] — 2026-05-18

### Added

- Mountable Rails 8 engine with a single dynamic `ResourcesController` handling all CRUD
- YAML-based model registration (`config/backstage.yml`) with auto-discovery of column types
- Per-resource Ruby DSL (`config/backstage/*.rb`) for field overrides, associations, sidebars, and custom actions
- Field types: `string`, `integer`, `text`, `boolean`, `date`, `datetime`, `enum`, `belongs_to`, `has_many`, `thumbnails`, `image_url`
- Searchable, sortable, paginated index tables with enum filter tabs
- Named dashboards with custom model scopes
- Sidebar links with static URLs or dynamic proc-based URL generation
- Custom action routing: POST `/admin/:resource/:id/:action_name` dispatches to host-app controller subclass
- Turbo Stream responses for destroy and custom actions (`respond_with_row_removed`, `respond_with_success`)
- Confirm dialog for destructive delete actions (vanilla JS, no Stimulus dependency)
- Searchable checkbox multi-select for `has_many` associations (vanilla JS)
- Pico CSS vendored for zero-config styling
- `backstage:install` generator to create config template and mount the engine
- 139 tests (unit, integration, system) against Rails 8 + SQLite3
