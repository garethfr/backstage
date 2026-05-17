# Project Brief: Backstage

**Type:** Ruby gem — mountable Rails engine  
**BMAD Phase:** Analyst Output → ready for PM Agent  
**Date:** May 2026  
**Author:** Analyst Agent (BMAD)

---

## 1. Problem Statement

Rails developers maintaining multiple internal projects need a lightweight, configurable admin interface they can drop into any Rails 8 app without inheriting the legacy dependencies, opinionated UI frameworks, or configuration ceremony of existing solutions (ActiveAdmin, RailsAdmin, Administrate).

The primary user is a solo developer or small team who needs to perform routine content administration — reviewing, editing, moderating and linking records — without building a bespoke admin from scratch for each project.

---

## 2. Vision

Backstage is a mountable Rails engine providing a clean, Hotwire-native admin interface configurable via a lightweight two-tier system: a YAML manifest for model registration, and optional per-resource Ruby config files for advanced field handling, associations, custom actions, and dashboards.

It is designed to be open-sourced, reusable across diverse Rails applications, and opinionated about Rails 8 conventions while remaining unopinionated about the host application's domain models.

---

## 3. Target Users

**Primary user (v1):** Solo Rails developer maintaining several projects, acting as the sole admin. Internal tool, not customer-facing.

**Secondary users (post-v1 / open source):** Small Rails teams needing a lightweight admin without the overhead of ActiveAdmin or Administrate.

**End-users managed via the admin:** The host application's registered users (e.g. commenters, restaurant owners) — managed as records, not as admin operators.

---

## 4. Core Use Cases

### UC-1: Register models for administration
A developer lists models in a YAML manifest. The gem auto-discovers columns from the ActiveRecord schema and renders sensible default index and edit views with no further configuration.

### UC-2: Override field behaviour per resource
When a field has special display or edit requirements (custom partial, date format, enum select, rich text, image thumbnail), the developer creates a per-resource Ruby config file declaring only the overrides needed. All other fields fall back to auto-discovery.

### UC-3: Manage associations
- `has_many` associations: rendered as a multi-select on edit forms; records can be added or removed.
- `belongs_to` / `has_one` associations: rendered as a single-select dropdown.
- `has_many` with thumbnail (e.g. photos): rendered as an inline thumbnail grid with links to individual admin records.

### UC-4: Custom dashboards
Named dashboard pages group records by a configurable scope (e.g. `status: :unverified`). Each dashboard can display a table of matching records with configurable per-row action links (e.g. "Validate", "Remove"). The admin home page links to configured dashboards and to each model's list page.

### UC-5: Sidebar links per resource
Each resource's show/edit page renders a configurable right-column sidebar with contextual links. Links may be static (e.g. "View on site") or dynamic (computed from the record, e.g. a Google Maps URL including the record's address, or a Google search URL including the record's name).

### UC-6: Admin home page
The root admin page is a curated overview — not a plain model list. It contains:
- Links to named dashboards (e.g. "New Restos", "Unverified Photos")
- Links to each registered model's index page
- Optionally: summary counts per dashboard scope

### UC-7: Bookmarklet-compatible URL scheme
Admin URLs follow a predictable RESTful pattern (`/admin/:model_plural/:id`) so that a JavaScript bookmarklet on the public-facing site can parse the current URL and navigate directly to the corresponding admin record.

### UC-8: Authentication via host app
The gem does not implement authentication. It calls a configurable method (default: `current_user.is_admin?`) on the host app's controller context. If it returns false or raises, the request is redirected. The method name is configurable in the gem's initializer.

### UC-9: User record management
Admin can view, search and edit user records registered in the YAML manifest. From related records (e.g. a comment), the admin page links to the associated user's admin record.

### UC-10: Enum field handling
Fields backed by ActiveRecord enums are automatically rendered as select dropdowns on edit forms. On index pages, enum values can be used as filters (scoped links or a filter dropdown).

---

## 5. Configuration Design

### Tier 1 — YAML manifest (required)
```yaml
# config/backstage.yml

admin_user_method: is_admin?   # optional, default shown

models:
  - Resto
  - Cuisine
  - Photo
  - Comment
  - User

dashboards:
  - name: new_restos
    model: Resto
    scope: { status: new }
    title: "New Restaurants"
  - name: unverified_photos
    model: Photo
    scope: { status: unverified }
    title: "Photos à vérifier"
```

### Tier 2 — Ruby config files (optional, per resource)
```ruby
# config/backstage/photo.rb
Backstage.resource :photo do
  fields :title, :status, :url
  field :status, as: :enum
  field :url, partial: "backstage/fields/external_image_thumbnail"

  belongs_to :resto

  sidebar do |record|
    link "View on site", record.public_url
    link "Search on Google", "https://google.com/search?q=#{CGI.escape(record.title)}"
  end

  actions :validate, :remove   # custom per-row actions on dashboards
end
```

---

## 6. Technical Constraints

- **Rails 8+** only — no support for older versions
- **Hotwire / Turbo / Stimulus** — all interactivity via standard Rails 8 stack
- **Import maps** — no Node.js / Webpack / Bun pipeline
- **No Active Storage dependency** — thumbnail display via custom partial, host app provides image URLs
- **No Action Text dependency**
- **No Devise dependency** — auth-agnostic, interface contract only
- **Minimal gem dependencies** — core gem should have as few runtime dependencies as possible
- **Mountable engine** — mounted at `/admin` by default, path configurable

---

## 7. Out of Scope (v1)

- Multi-admin / role-based access within the admin (it's just you)
- Inline record creation for associations (select existing only)
- CSV export
- Activity / audit log
- API / JSON endpoints
- i18n (labels in English by default; internationalisation considered in design but not implemented)
- Drag-and-drop reordering of has_many records

---

## 8. Open Source Considerations

- Configuration API (YAML keys, Ruby DSL methods) must be treated as a **public interface** — breaking changes require a major version bump
- Default views should be clean and unstyled enough to be usable without customisation
- Extension points (custom partials, custom actions, custom field types) should be documented as first-class features
- The gem should ship with a minimal test host app (dummy Rails app) in `spec/dummy`
- Licence: MIT

---

## 9. Success Criteria

- Can be added to a new Rails 8 app, configured with a 10-line YAML file, and provide a working admin interface for 3 models with zero Ruby config files
- Custom dashboards (named scopes + per-row actions) work without modifying the gem
- A bookmarklet can be written in under 10 lines of JS that correctly navigates from a public page to the corresponding admin record
- The gem has no runtime dependencies that conflict with a stock Rails 8 app
- A second Rails app can use the same gem with a completely different model set and YAML config, with no changes to the gem

---

## 10. Decisions Log (resolved for PM Agent)

1. **Gem name:** `backstage`; `rails-backstage` held in reserve if Spotify name conflict arises.
2. **Pagination:** Simple page-based pagination.
3. **Search on index pages:** Basic filter on primary name column per model index page.
4. **Default styling:** Pico CSS — classless, no build step, easily overridden by host app.
5. **Custom action implementation:** REST-ish controller actions on the resource (e.g. `POST /admin/photos/:id/validate`), Turbo-compatible.
6. **Test coverage:** Minitest + Capybara system specs in a spec/dummy Rails app.
