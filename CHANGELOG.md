# Changelog

All notable changes to this project will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.19] — 2026-07-18

### Fixed

- Mobile nav hamburger toggle was unclickable while the nav was open (the open overlay covered the button), so it could never be closed again

## [0.1.18] — 2026-07-18

### Added

- Responsive admin layout: left nav collapses behind a hamburger toggle and overlays the page below 768px; edit-page sidebar reflows below the form on narrow viewports

### Changed

- Test dummy app now uses Propshaft to serve assets (fixes CSS not loading in system tests)

## [0.1.17] — 2026-06-04

### Added

- Flash notice is displayed after a successful create or update

### Fixed

- Edit and new forms now render validation error messages inline when save fails
- Successful update now redirects back to the edit page instead of the index

## [0.1.16] — 2026-06-02

### Fixed

- Nested table now uses a `<template>` element instead of a static new row, so unsaved blank rows are never submitted unintentionally
- New-row template includes readonly fields as plain inputs so new records can be fully populated via the Add button
- Readonly nested fields are now permitted in Strong Parameters, so new records with readonly fields save correctly
- `belongs_to :assoc, readonly: true` now propagates `readonly:` to the generated FK field

## [0.1.15] — 2026-05-27

### Added

- `c.nested :assoc, fields: [...]` DSL renders existing `has_many` records as an inline editable table using `accepts_nested_attributes_for`
- Nested rows include a destroy button (×) and a `_destroy` hidden field; clicking hides the row and marks it for deletion on save
- A blank add row is always rendered at the bottom of the nested table for creating new records
- `image_url` fields on index and dashboard tables now render as `<img>` tags instead of raw URLs
- `belongs_to` fields now render correctly on dashboard tables (was missing)
- Shared `backstage/shared/_cell` partial extracted for consistent field rendering across index and dashboard views

## [0.1.14] — 2026-05-26

### Fixed

- `ActionsController` no longer falls back to `Backstage::ResourcesController` when no custom controller exists — raises `NotImplementedError` instead of silently dispatching inherited CRUD actions
- Custom action dispatch now uses `method_defined?(name, false)` so only actions defined directly on the host subclass are callable; inherited methods (`index`, `create`, `update`, `destroy`, etc.) are blocked
- Gemspec `homepage` corrected to point to the right repository

## [0.1.13] — 2026-05-26

### Added

- `c.nested :assoc, fields: [...]` DSL for `accepts_nested_attributes_for` associations — renders existing nested records as editable rows

### Fixed

- SQL injection: sort column now uses Arel table quoting instead of raw string interpolation
- XSS: `respond_with_success` now HTML-escapes the message argument before rendering
- `new.html.erb` now respects container fields (row/section) — previously rendered a spurious wrapper `<div>` and label around each
- `decimal` and `float` column types now map to `:decimal` instead of `:integer`; a new `_decimal` partial renders them with `step: "any"`
- `section` block now uses `ensure` to reset `@current_target`, preventing a stale target if the block raises
- `find_field` now searches inside container `sub_fields`, preventing duplicate fields when re-specifying a field already moved into a section
- `DashboardConfig` now raises `ArgumentError` at initialisation if `name` or `model` is missing from the YAML hash
- `params.permit!` in `index.html.erb` replaced with explicit param slice
- Edit page no longer renders an empty `class=""` attribute when no sidebar is present
- Removed unused `sidebar_links`, `custom_actions`, and `excluded_columns` attributes from `ResourceConfig`

## [0.1.12] — 2026-05-25

### Added

- `c.row :field1, :field2` groups fields horizontally in a Pico CSS grid on the edit page
- `c.section "Label" [, collapsed: true]` wraps fields in a native `<details>`/`<summary>` collapsible block (no JavaScript required); rows and individual fields can be nested inside sections
- `c.field` called inside a `section` block moves an existing auto-discovered field into the section rather than leaving it at the top level

## [0.1.11] — 2026-05-25

### Fixed

- Pagination window no longer generates links below page 1 or above the last page when there are fewer than 6 total pages; window is clamped to the valid inner range and skipped entirely when `total_pages <= 2`
- Sidebar moved from the layout into the edit view, rendering to the right of the form in a two-column grid; links open in a new tab (`target="_blank"`) and blank URLs (e.g. from a proc returning `""`) are skipped silently

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
