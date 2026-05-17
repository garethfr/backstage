# Product Requirements Document: Backstage

**Version:** 1.0  
**BMAD Phase:** PM Agent Output → ready for Architect Agent  
**Date:** May 2026  
**Gem name:** `backstage` (`rails-backstage` in reserve)  
**Licence:** MIT

---

## 1. Overview

Backstage is a mountable Rails 8 engine that provides a lightweight, configurable admin interface for Rails applications. It is configured via a two-tier system: a YAML manifest for model registration and dashboard definition, and optional per-resource Ruby config files for advanced field handling, associations, custom actions, and sidebar links.

Backstage is designed to be dropped into any Rails 8 app with minimal setup, to work cleanly across multiple projects without modification, and to be open-sourced for use by the wider Rails community.

---

## 2. Goals

- **G1:** Enable a working admin interface for any Rails 8 app with a single YAML file and no Ruby configuration.
- **G2:** Support progressive enhancement — the more config you write, the more powerful the admin becomes, but defaults are always sensible.
- **G3:** Stay dependency-light — no Devise, no Active Storage, no Action Text, no Node pipeline.
- **G4:** Follow Rails 8 conventions throughout — Hotwire, Turbo, Stimulus, import maps.
- **G5:** Expose a stable, well-defined public API (YAML keys + Ruby DSL) suitable for open-source versioning.

---

## 3. Non-Goals (v1)

- Multi-operator admin with role-based access control
- Inline creation of associated records within a parent record's edit form (new records must be created via their own model's index page)
- CSV / data export
- Audit log / activity history
- API or JSON endpoints
- i18n / translated UI labels
- Drag-and-drop record reordering
- Support for Rails versions below 8.0

---

## 4. User Stories

### Authentication & Access

**US-01**
As a developer, I want to configure which method Backstage uses to check admin access, so that I can integrate with any authentication system my app uses.

*Acceptance criteria:*
- `admin_user_method` key in `config/backstage.yml` sets the method called on `current_user` (default: `is_admin?`)
- If the method returns false or `current_user` is nil, the request redirects to a configurable path (default: `/`)
- No Devise dependency in the gem

---

### Model Registration

**US-02**
As a developer, I want to list models in a YAML file and immediately get index and show/edit pages for each, so that I don't need to write boilerplate for every resource.

*Acceptance criteria:*
- Adding a model name to `config/backstage.yml` under `models:` makes it available in the admin
- Index page renders all records with auto-discovered columns
- Show/edit page renders all columns as appropriate form inputs
- Auto-discovery covers: string, integer, text, boolean, date, datetime, decimal column types
- No Ruby config file required for any of the above

**US-03**
As a developer, I want Backstage to ignore internal Rails columns by default, so that my forms aren't cluttered with `created_at`, `updated_at`, `id` fields.

*Acceptance criteria:*
- `id`, `created_at`, `updated_at` are excluded from edit forms by default
- `id`, `created_at`, `updated_at` are displayed read-only at the bottom of the edit page
- Exclusion list is configurable per resource in the Ruby config file

---

### Field Configuration

**US-04**
As a developer, I want to declare which fields appear on the index list and in what order, so that I can prioritise the most relevant columns.

*Acceptance criteria:*
- `fields :name, :status, :created_at` in the resource config controls index column order and visibility
- Fields not listed are excluded from the index (but still available on show/edit)

**US-05**
As a developer, I want to override how a specific field is displayed or edited, so that I can handle special cases without losing auto-discovery for everything else.

*Acceptance criteria:*
- `field :body, partial: "backstage/fields/my_partial"` renders a custom partial for that field
- `field :published_at, format: "%d/%m/%Y"` applies strftime formatting for display
- `field :status, as: :enum` renders a select dropdown populated from the ActiveRecord enum values
- `field :url, as: :image_url` renders an `<img>` tag on show/index, with the URL as src
- Unoverridden fields continue to use auto-discovered defaults

**US-06**
As a developer, I want enum fields to be automatically detected and rendered as select dropdowns on edit forms, so that I don't have to manually configure every enum field.

*Acceptance criteria:*
- Fields backed by `ActiveRecord` enums are auto-detected and rendered as `<select>` on edit forms
- The enum values are used to populate the select options
- On index pages, enum columns display the human-readable value
- Enum filter links (one per value) appear above the index table when the field is an enum

---

### Association Management

**US-07**
As a developer, I want `has_many` associations rendered as a multi-select on edit forms, so that I can add or remove associated records without custom code.

*Acceptance criteria:*
- `has_many :cuisines` in the resource config renders a multi-select of existing Cuisine records on the Resto edit form
- Saving the form updates the association (add/remove)
- No inline creation of new associated records — select from existing only
- The multi-select label uses the associated model's primary display column (auto-detected or configurable)

**US-08**
As a developer, I want `belongs_to` and `has_one` associations rendered as single-select dropdowns on edit forms.

*Acceptance criteria:*
- `belongs_to :cuisine` renders a `<select>` of existing Cuisine records
- Saving updates the foreign key
- A blank option is included for nullable associations

**US-09**
As a developer, I want `has_many` associations that represent images to render as an inline thumbnail grid on the show page, with a link to each record's admin page.

*Acceptance criteria:*
- `has_many :photos, as: :thumbnails` renders a grid of `<img>` tags on the parent show page
- Each thumbnail links to the Photo admin show page
- The image src column is configurable (default: `:url`)
- Thumbnail size is fixed (configurable via CSS custom property)

---

### Sidebar Links

**US-10**
As a developer, I want to configure a sidebar on each resource's show/edit page with contextual links, so that I can quickly navigate to related external pages or tools.

*Acceptance criteria:*
- `sidebar do |record| ... end` block in the resource config renders a right-column panel on show/edit pages
- `link "Label", url` renders a plain link
- `link "Label", proc { |r| "https://..." }` renders a dynamic link computed from the record
- Sidebar is absent if not configured (no empty panel rendered)

---

### Dashboards

**US-11**
As a developer, I want to define named dashboards in the YAML config that display records matching a scope, so that I can quickly review records requiring attention.

*Acceptance criteria:*
- Dashboards defined in `config/backstage.yml` under `dashboards:` are accessible at `/admin/dashboards/:name`
- Each dashboard renders a table of records matching the configured scope (e.g. `{ status: unverified }`)
- Dashboard title is configurable
- Each row displays the resource's configured index fields

**US-12**
As a developer, I want dashboard rows to have configurable per-row action links (e.g. "Validate", "Remove"), so that I can take moderation actions directly from the dashboard.

*Acceptance criteria:*
- `actions :validate, :remove` in the resource Ruby config generates per-row action buttons on any dashboard showing that resource
- Each action sends a `POST` request to `/admin/:resource/:id/:action_name`
- The host app implements the action logic by defining a method in a controller concern or by mounting a custom controller — the gem provides the routing and a base action handler that can be overridden
- Actions render a Turbo Stream response updating the row (or removing it) on success
- A confirmation prompt is shown for destructive actions (configurable per action)

---

### Admin Home Page

**US-13**
As an admin, I want the root admin page to show an overview of dashboards and model links with record counts, so that I can see the state of the site at a glance.

*Acceptance criteria:*
- `/admin` renders a home page (not a redirect to a model index)
- Each configured dashboard is listed with its title and current record count
- Each registered model is listed with a link to its index page and total record count
- Counts are computed at page load (no caching in v1)

---

### Index Pages

**US-14**
As an admin, I want each model's index page to be paginated, so that large tables don't become unwieldy.

*Acceptance criteria:*
- Index pages display a configurable number of records per page (default: 25)
- Page navigation links appear at the bottom of the table
- Current page is reflected in the URL (`?page=2`) for bookmarkability
- No external pagination gem required — simple offset/limit implementation

**US-15**
As an admin, I want to search for records by the primary name column, so that I can find a specific record quickly.

*Acceptance criteria:*
- A search input appears above the index table
- Searching filters records by case-insensitive partial match on the primary display column
- The primary display column is auto-detected (first of: `:name`, `:title`, `:email`, `:id`) or configurable per resource
- Search and pagination compose correctly (search resets to page 1)

**US-16**
As an admin, I want index columns to be sortable, so that I can order records by any column.

*Acceptance criteria:*
- Clicking a column header sorts by that column ascending; clicking again sorts descending
- Sort state is reflected in the URL (`?sort=name&dir=asc`)
- Default sort is by `id desc` (most recent first)

---

### Edit Pages

**US-17**
As an admin, I want index row links to go directly to a record's edit page, so that I can update content without an extra click through a read-only view.

*Acceptance criteria:*
- Each row on the index page links directly to `/admin/:resource/:id/edit`
- The edit page renders all configured fields as form inputs
- Associated records (has_many) are listed on the edit page with links to their own edit pages
- Sidebar (if configured) renders in the right column
- `created_at`, `updated_at`, `id` are displayed read-only at the bottom of the form, not editable
- Saving a valid form redirects to the index page with a success notice
- Validation errors render inline on the form without a full page reload (Turbo)
- The form uses Rails standard form_with helper

**US-18**
As an admin, I want to create new records from the index page, so that I can add content directly from the admin.

*Acceptance criteria:*
- A "New [Resource]" button appears on each model's index page
- `/admin/:resource/new` renders a blank edit form
- Saving redirects to the new record's edit page with a success notice

**US-19**
As an admin, I want to delete a record from its edit page, so that I can remove unwanted content.

*Acceptance criteria:*
- A "Delete" button appears on the edit page
- Clicking triggers a confirmation dialog before submitting
- Deletion sends `DELETE /admin/:resource/:id`
- On success, redirects to the index page with a notice

---

### Bookmarklet Support

**US-21**
As an admin, I want admin URLs to follow a predictable pattern, so that I can write a browser bookmarklet to jump from any public page to its corresponding admin record.

*Acceptance criteria:*
- All resource edit URLs follow the pattern `/admin/:model_plural/:id/edit`
- The mount path (`/admin`) is configurable in `routes.rb`
- Model names in URLs are the Rails default plural, underscored form (e.g. `blog_posts`)
- Documentation includes a reference bookmarklet implementation

---

### Installation & Setup

**US-22**
As a developer, I want to install and configure Backstage in under 10 minutes, so that I can get an admin interface running without reading lengthy documentation.

*Acceptance criteria:*
- `gem 'backstage'` in the Gemfile is the only gem dependency change
- `rails generate backstage:install` creates `config/backstage.yml` with commented examples and mounts the engine in `routes.rb`
- A minimal `config/backstage.yml` with one model entry produces a working admin
- The install generator prints next steps to the terminal

---

## 5. Functional Requirements

### FR-1: Configuration Loading
- `config/backstage.yml` is loaded at app boot
- `config/backstage/*.rb` files are auto-loaded (one per resource, filename matches model name underscored)
- Configuration errors (unknown model, invalid YAML) raise a descriptive error at boot time, not at request time

### FR-2: Auto-Discovery
- Backstage reflects on `ActiveRecord::Base` column definitions to determine field types
- Column type mapping: `string/text → text_field`, `integer/decimal → number_field`, `boolean → check_box`, `date → date_field`, `datetime → datetime_field`
- Enum fields detected via `model.defined_enums`
- Association types detected via `model.reflect_on_all_associations`

### FR-3: URL Structure
```
GET    /admin                          → home#index
GET    /admin/:resource                → resource#index
GET    /admin/:resource/new            → resource#new
POST   /admin/:resource                → resource#create
GET    /admin/:resource/:id/edit       → resource#edit
PATCH  /admin/:resource/:id            → resource#update
DELETE /admin/:resource/:id            → resource#destroy
POST   /admin/:resource/:id/:action    → resource#custom_action
GET    /admin/dashboards/:name         → dashboards#show
```

### FR-4: Authentication Filter
- A `before_action` in `Backstage::ApplicationController` calls the configured admin check method
- Redirect path on failure is configurable (default: `main_app.root_path`)
- The filter is inherited by all Backstage controllers

### FR-5: Styling
- Pico CSS is vendored in the gem (not CDN-loaded) to work in offline/air-gapped environments
- Backstage layouts use a minimal two-column structure (main content + sidebar)
- All Backstage HTML elements use semantic tags compatible with Pico CSS defaults
- Host apps can override styles by adding CSS after Backstage's stylesheet in their asset pipeline

### FR-6: Turbo Integration
- Forms use `data-turbo="true"` by default
- Validation errors are returned as Turbo Stream responses rendering inline error messages
- Custom action responses return Turbo Stream updates to the relevant table row
- Page-based pagination uses standard `<a>` links (full page navigation, no Turbo Frames needed)

### FR-7: Custom Actions
- Routing: `POST /admin/:resource/:id/:action_name`
- The gem generates routes for all declared actions at boot
- Base handler in `Backstage::ResourceController` calls a method named `backstage_action_:name` on the host app's `ApplicationController` if defined, otherwise raises `NotImplementedError` with a helpful message
- Response must be a Turbo Stream or redirect

### FR-8: Dummy App
- `test/dummy` contains a minimal Rails 8 app with two sample models (e.g. `Article`, `Tag`) demonstrating all major features
- The dummy app is used for all Minitest + Capybara system tests

---

## 6. Non-Functional Requirements

### NFR-1: Dependency budget
Runtime dependencies: zero (Pico CSS vendored, no gem dependencies beyond Rails itself).
Development dependencies: `minitest`, `capybara`, `selenium-webdriver`.

### NFR-2: Performance
- Index pages with 10,000 records must paginate and load in under 500ms on a standard VPS
- No N+1 queries on index pages — association counts use `counter_cache` or a single `GROUP BY` query

### NFR-3: Security
- All forms use Rails CSRF protection (`authenticity_token`)
- Admin check runs on every request, not just on login
- No eval of user-supplied YAML values

### NFR-4: Compatibility
- Rails 8.0+
- Ruby 3.2+
- Tested against SQLite, PostgreSQL, MySQL/MariaDB

### NFR-5: Versioning
- Follows semantic versioning (SemVer)
- YAML keys and Ruby DSL method signatures are the public API — changes require a major version bump
- Changelog maintained in `CHANGELOG.md`

---

## 7. Configuration Reference (v1 public API)

### `config/backstage.yml`

| Key | Type | Default | Description |
|---|---|---|---|
| `admin_user_method` | string | `is_admin?` | Method called on `current_user` to verify admin access |
| `redirect_on_failure` | string | `/` | Path to redirect to when access is denied |
| `per_page` | integer | `25` | Records per page on index pages |
| `models` | list | `[]` | Model class names to register |
| `dashboards` | list | `[]` | Named dashboard definitions |
| `dashboards[].name` | string | required | URL slug for the dashboard |
| `dashboards[].model` | string | required | Model class name |
| `dashboards[].scope` | hash | required | ActiveRecord where conditions |
| `dashboards[].title` | string | name.humanize | Display title |
| `dashboards[].actions` | list | `[]` | Action names available per row |

### `config/backstage/:resource.rb` DSL

| Method | Description |
|---|---|
| `fields *cols` | Set index column list and order |
| `field :name, **opts` | Override a single field's display/edit behaviour |
| `field :name, as: :enum` | Render as enum select |
| `field :name, as: :image_url` | Render as image thumbnail |
| `field :name, partial: "path"` | Render via custom partial |
| `field :name, format: "%d/%m/%Y"` | Apply strftime format |
| `field :name, readonly: true` | Display only, not editable |
| `has_many :assoc` | Render as multi-select on edit form |
| `has_many :assoc, as: :thumbnails` | Render as thumbnail grid on show |
| `belongs_to :assoc` | Render as single-select dropdown |
| `has_one :assoc` | Render as single-select dropdown |
| `display_column :col` | Set primary display/search column |
| `sidebar do \|r\| ... end` | Configure sidebar links |
| `link "Label", url_or_proc` | Add a sidebar link |
| `actions *names` | Declare custom per-row actions |
| `exclude *cols` | Exclude columns from all views |

---

## 8. Milestones

### Milestone 1 — Core Engine (MVP)
- Gem skeleton with mountable engine structure
- Install generator (`rails generate backstage:install`)
- YAML config loading and validation
- Auto-discovery of columns and field types
- Index, show, new, edit, create, update, destroy for registered models
- Page-based pagination
- Basic search on primary display column
- Pico CSS vendored and applied
- Authentication filter with configurable method
- Admin home page with model links and counts
- Dummy app with two models
- Minitest suite covering all CRUD actions

### Milestone 2 — Field & Association Configuration
- Per-resource Ruby config file loading
- `fields`, `field`, `exclude`, `display_column` DSL
- Enum auto-detection and select rendering
- Enum filter links on index pages
- `has_many` multi-select
- `belongs_to` / `has_one` single-select dropdown
- `has_many as: :thumbnails` grid on show page
- Sortable index columns
- Capybara system tests for all field types and associations

### Milestone 3 — Dashboards, Sidebars & Custom Actions
- Dashboard routing and views
- Dashboard record counts on home page
- Sidebar DSL and two-column layout
- Custom action routing (`POST /admin/:resource/:id/:action`)
- Turbo Stream response handling for custom actions
- Confirmation prompt for destructive actions
- System tests for dashboards and custom actions

### Milestone 4 — Open Source Readiness
- README with installation guide and full configuration reference
- Reference bookmarklet implementation documented
- CHANGELOG.md
- MIT licence file
- RubyGems publish workflow (GitHub Actions)
- Dummy app demonstrating all features
- Contributing guide

---

## 9. Architectural Decisions Log (resolved for Architect Agent)

1. **Custom action override mechanism:** Hybrid subclassing (Option C). Standard CRUD always handled by `Backstage::ResourceController`. Custom actions looked up in a host-app subclass (`Backstage::PhotosController < Backstage::ResourceController`) if it exists, falling back to `NotImplementedError`. Host app only creates a subclass file when custom behaviour is needed — zero-config case remains zero-config.

2. **Multi-select implementation:** Stimulus-enhanced searchable checkbox list, built into the gem. No external JS library. ~50 lines of Stimulus JS bundled with the engine. Native `<select multiple>` not used.

3. **Form save responses:** Redirect on successful create/update (v1). Turbo Stream responses deferred to v2. Validation errors returned as Turbo Stream inline updates (no full page reload on error).

4. **Config file location:** File-per-resource — `config/backstage.yml` for the manifest, `config/backstage/:resource.rb` for per-resource Ruby config. No single monolithic initializer.

5. **Pico CSS delivery:** Vendored as a static file inside the engine (`app/assets/stylesheets/backstage/pico.css`), served via Propshaft, referenced with `stylesheet_link_tag` in the engine layout. Import maps are JS-only; CSS is not delivered via import maps. Stimulus controllers vendored in the engine and registered via the host app's import map.
