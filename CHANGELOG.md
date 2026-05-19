# Changelog

All notable changes to this project will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
