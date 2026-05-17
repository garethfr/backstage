# Backstage — System Architecture

**Version:** 1.0  
**BMAD Phase:** Architect Agent Output → ready for implementation  
**Date:** May 2026

---

## 1. Architectural Overview

Backstage is a **mountable Rails engine** — a self-contained Rails application packaged as a gem, mounted inside a host Rails app at a configurable path (default: `/admin`).

The engine follows a **three-layer architecture**:

1. **Configuration layer** — loads and validates YAML + Ruby config files at boot, builds an in-memory registry of resources
2. **Controller layer** — handles HTTP requests, delegates to the registry for resource metadata, calls host-app subclasses for custom actions
3. **View layer** — renders index/edit/dashboard views using the resource registry to determine fields, associations, and layout

All three layers are designed to be **host-app agnostic** — they know nothing about the specific models in use until runtime, operating entirely through the ActiveRecord reflection API and the resource registry.

---

## 2. Directory Structure

```
backstage/
├── app/
│   ├── assets/
│   │   ├── stylesheets/
│   │   │   └── backstage/
│   │   │       └── pico.css              # vendored Pico CSS
│   │   │       └── backstage.css         # engine overrides / layout CSS
│   │   └── javascripts/
│   │       └── backstage/
│   │           └── multi_select_controller.js   # Stimulus: searchable checkbox
│   │           └── confirm_action_controller.js # Stimulus: destructive action confirm
│   ├── controllers/
│   │   └── backstage/
│   │       ├── application_controller.rb  # auth filter, shared helpers
│   │       ├── home_controller.rb         # GET /admin
│   │       ├── resources_controller.rb    # index, new, edit, create, update, destroy
│   │       ├── dashboards_controller.rb   # GET /admin/dashboards/:name
│   │       └── actions_controller.rb      # POST /admin/:resource/:id/:action
│   ├── helpers/
│   │   └── backstage/
│   │       └── application_helper.rb     # view helpers (field rendering, sidebar)
│   └── views/
│       └── backstage/
│           ├── layouts/
│           │   └── backstage.html.erb     # engine layout (Pico CSS, nav, sidebar slot)
│           ├── home/
│           │   └── index.html.erb         # admin home page
│           ├── resources/
│           │   ├── index.html.erb         # model index (table, search, pagination)
│           │   ├── edit.html.erb          # edit/new form wrapper
│           │   └── _form.html.erb         # shared form partial
│           ├── dashboards/
│           │   └── show.html.erb          # named dashboard view
│           └── fields/
│               ├── _string.html.erb       # default string field
│               ├── _integer.html.erb
│               ├── _boolean.html.erb
│               ├── _date.html.erb
│               ├── _datetime.html.erb
│               ├── _text.html.erb
│               ├── _enum.html.erb         # select from enum values
│               ├── _image_url.html.erb    # <img> tag from URL string
│               ├── _belongs_to.html.erb   # single-select dropdown
│               ├── _has_many.html.erb     # searchable checkbox multi-select
│               └── _thumbnails.html.erb   # thumbnail grid
├── lib/
│   ├── backstage/
│   │   ├── engine.rb                     # Rails::Engine definition
│   │   ├── configuration.rb              # global config (admin_user_method etc)
│   │   ├── registry.rb                   # in-memory resource registry
│   │   ├── resource_config.rb            # DSL evaluator for per-resource Ruby files
│   │   ├── field.rb                      # field metadata value object
│   │   ├── association_config.rb         # association metadata value object
│   │   └── auto_discovery.rb            # ActiveRecord reflection → field list
│   ├── generators/
│   │   └── backstage/
│   │       └── install/
│   │           ├── install_generator.rb
│   │           └── templates/
│   │               └── backstage.yml.tt  # commented YAML template
│   └── backstage.rb                      # gem entry point, requires, Backstage.configure
├── config/
│   └── routes.rb                         # engine routes
├── test/
│   ├── dummy/                            # minimal Rails 8 host app for tests
│   │   ├── app/
│   │   │   └── models/
│   │   │       ├── article.rb
│   │   │       └── tag.rb
│   │   ├── config/
│   │   │   └── backstage.yml
│   │   └── db/
│   │       └── schema.rb
│   ├── controllers/
│   ├── system/                           # Capybara system tests
│   └── test_helper.rb
├── backstage.gemspec
├── Gemfile
├── CHANGELOG.md
├── LICENSE
└── README.md
```

---

## 3. Core Components

### 3.1 `Backstage::Engine`
**File:** `lib/backstage/engine.rb`

The Rails engine definition. Responsibilities:
- Declares the engine as isolated (`isolate_namespace Backstage`)
- Registers the `config/backstage` initializer that loads YAML and Ruby config files
- Adds `config/backstage/*.rb` to the watchable file paths (so Rails reloads on change in development)
- Registers Stimulus controllers with the host app's import map via an `after_initialize` hook

```ruby
module Backstage
  class Engine < ::Rails::Engine
    isolate_namespace Backstage

    initializer "backstage.configuration" do |app|
      Backstage.load_configuration!(app.root)
    end

    initializer "backstage.importmap", before: "importmap" do |app|
      app.config.importmap.paths << root.join("config/importmap.rb")
    end
  end
end
```

---

### 3.2 `Backstage::Configuration`
**File:** `lib/backstage/configuration.rb`

Holds global settings parsed from `config/backstage.yml`. A plain Ruby value object, frozen after load.

```ruby
module Backstage
  class Configuration
    attr_reader :admin_user_method,   # Symbol, default: :is_admin?
                :redirect_on_failure, # String, default: "/"
                :per_page,            # Integer, default: 25
                :model_names,         # Array<String>
                :dashboard_configs    # Array<Hash>
  end
end
```

---

### 3.3 `Backstage::Registry`
**File:** `lib/backstage/registry.rb`

The central in-memory store, populated at boot. Maps model name strings to `ResourceConfig` instances. Singleton, accessed via `Backstage.registry`.

```ruby
module Backstage
  class Registry
    def register(model_name, &block)        # called by DSL or auto-discovery
    def resource_for(model_name)            # → ResourceConfig
    def all_resources                       # → Array<ResourceConfig>
    def dashboard_for(name)                 # → DashboardConfig
  end
end
```

Boot sequence:
1. Parse `config/backstage.yml` → `Configuration`
2. For each model name in config: create a `ResourceConfig` via `AutoDiscovery`
3. Load each `config/backstage/*.rb` file → DSL block evaluated against the matching `ResourceConfig`, overriding auto-discovered defaults
4. Register all dashboard configs from YAML

---

### 3.4 `Backstage::ResourceConfig`
**File:** `lib/backstage/resource_config.rb`

Holds all metadata for one administered resource. Built by `AutoDiscovery`, optionally modified by the DSL.

```ruby
module Backstage
  class ResourceConfig
    attr_accessor :model_class        # Class — the ActiveRecord model
    attr_accessor :index_fields       # Array<Field>
    attr_accessor :edit_fields        # Array<Field>
    attr_accessor :display_column     # Symbol
    attr_accessor :associations       # Array<AssociationConfig>
    attr_accessor :sidebar_links      # Array<{label:, url_or_proc:}>
    attr_accessor :custom_actions     # Array<Symbol>
    attr_accessor :excluded_columns   # Array<Symbol>

    # DSL interface (called from config/backstage/*.rb)
    def fields(*cols)
    def field(name, **opts)
    def exclude(*cols)
    def display_column(col)
    def has_many(assoc, **opts)
    def belongs_to(assoc, **opts)
    def has_one(assoc, **opts)
    def sidebar(&block)
    def actions(*names)

    # Derived helpers used by controllers/views
    def model_name_param          # "articles"
    def primary_display_value(record)
    def controller_class          # looks up host-app subclass if present
  end
end
```

---

### 3.5 `Backstage::Field`
**File:** `lib/backstage/field.rb`

A value object describing one field. Immutable after construction.

```ruby
module Backstage
  class Field
    attr_reader :name,        # Symbol
                :type,        # Symbol: :string, :integer, :boolean, :date, :datetime,
                              #         :text, :enum, :image_url, :custom
                :options      # Hash: format:, partial:, readonly:, enum_values:, etc.

    def partial_path          # → "backstage/fields/_#{type}" or custom partial
    def readonly?
    def enum?
    def enum_values           # → Array of [label, value] pairs
  end
end
```

---

### 3.6 `Backstage::AutoDiscovery`
**File:** `lib/backstage/auto_discovery.rb`

Reflects on an ActiveRecord model to build a default `ResourceConfig`. Called at boot for every registered model.

```ruby
module Backstage
  class AutoDiscovery
    def self.build(model_class) → ResourceConfig

    private

    def column_to_field(column)   # ActiveRecord::Column → Field
    def detect_enums(model)       # model.defined_enums → Array<Field>
    def detect_display_column(model)  # first of :name, :title, :email, :id
    def system_columns            # [:id, :created_at, :updated_at]
  end
end
```

---

### 3.7 Controller Layer

All controllers inherit from `Backstage::ApplicationController`, which:
- Sets the layout to `"backstage/backstage"`
- Runs the authentication `before_action`
- Provides `current_resource_config` helper

#### `Backstage::ApplicationController`
```ruby
before_action :verify_admin!

def verify_admin!
  method = Backstage.configuration.admin_user_method
  unless current_user&.public_send(method)
    redirect_to Backstage.configuration.redirect_on_failure
  end
end
```

#### `Backstage::ResourcesController`
Handles all standard CRUD. Uses `current_resource_config` to determine the model, permitted params, and fields to render. Does **not** know about specific models.

```ruby
def edit
  @resource_config = current_resource_config
  @record = @resource_config.model_class.find(params[:id])
end

def update
  @resource_config = current_resource_config
  @record = @resource_config.model_class.find(params[:id])
  if @record.update(permitted_params)
    redirect_to backstage.resources_path(@resource_config.model_name_param),
                notice: "#{@resource_config.model_class.name} updated."
  else
    render :edit, status: :unprocessable_entity
  end
end
```

#### `Backstage::ActionsController`
Handles custom actions. Looks up the host-app subclass (Option C hybrid pattern):

```ruby
def create  # POST /admin/:resource/:id/:action_name
  @resource_config = current_resource_config
  @record = @resource_config.model_class.find(params[:id])
  action = params[:action_name].to_sym

  controller_class = @resource_config.controller_class
  # controller_class is either Backstage::ResourcesController
  # or a host-app subclass like Backstage::PhotosController
  handler = controller_class.new
  handler.request = request
  handler.response = response

  if handler.respond_to?(action)
    handler.public_send(action)
  else
    raise NotImplementedError,
      "Define action `#{action}` in #{controller_class.name} to handle this custom action."
  end
end
```

`ResourceConfig#controller_class` resolution:
```ruby
def controller_class
  host_class_name = "Backstage::#{model_class.name.pluralize}Controller"
  host_class_name.safe_constantize || Backstage::ResourcesController
end
```

---

### 3.8 View Layer

Views are standard ERB partials. The key design is the **field partial dispatch** — `edit.html.erb` iterates over `@resource_config.edit_fields` and renders each field's partial:

```erb
<%# app/views/backstage/resources/_form.html.erb %>
<% resource_config.edit_fields.each do |field| %>
  <div class="field" id="field-<%= field.name %>">
    <%= label_tag field.name %>
    <%= render field.partial_path, field: field, record: record, f: f %>
  </div>
<% end %>
```

Each field partial in `app/views/backstage/fields/` handles one type:
- `_string.html.erb` → `text_field`
- `_enum.html.erb` → `select` with enum values
- `_has_many.html.erb` → Stimulus-powered searchable checkbox list
- `_thumbnails.html.erb` → `<img>` grid with links
- etc.

---

### 3.9 Stimulus Controllers

Two Stimulus controllers, vendored in the engine:

**`multi-select`** (`multi_select_controller.js`)
- Replaces native `<select multiple>` with a searchable checkbox list
- Search input filters checkboxes by label text in real time
- On form submit, syncs checked state back to a hidden `<select multiple>` for standard Rails params
- ~60 lines, zero dependencies

**`confirm-action`** (`confirm_action_controller.js`)
- Intercepts form submission or link click
- Shows a native `window.confirm` dialog (or a simple inline modal in v2)
- Proceeds or cancels based on user response
- ~20 lines

Both are registered in the engine's `config/importmap.rb` and pinned to the engine's asset path.

---

## 4. Data Flow

### 4.1 Boot sequence
```
Rails boot
  → Backstage::Engine initializer fires
  → Backstage.load_configuration!(root)
    → Parse config/backstage.yml → Configuration
    → For each model_name:
        AutoDiscovery.build(model_class) → ResourceConfig
        Registry.register(model_name, resource_config)
    → Dir.glob("config/backstage/*.rb").each
        → ResourceConfig DSL block evaluated
        → Registry entry updated
    → Dashboard configs stored in Registry
```

### 4.2 Request: GET /admin/photos/42/edit
```
Request arrives at Backstage::Engine
  → routes.rb matches → ResourcesController#edit
  → ApplicationController before_action :verify_admin!
      → current_user.is_admin? → true → proceed
  → params[:resource] = "photos"
  → current_resource_config = Registry.resource_for("photos")
  → @record = Photo.find(42)
  → render :edit
    → _form.html.erb iterates resource_config.edit_fields
    → each field renders its partial
    → sidebar rendered if resource_config.sidebar_links.any?
    → system columns (id, created_at, updated_at) rendered read-only at bottom
```

### 4.3 Request: POST /admin/photos/42/validate
```
Request arrives at Backstage::Engine
  → routes.rb matches → ActionsController#create
  → verify_admin! → pass
  → params[:resource] = "photos", params[:id] = "42", params[:action_name] = "validate"
  → resource_config = Registry.resource_for("photos")
  → controller_class = "Backstage::PhotosController".safe_constantize
      → found: Backstage::PhotosController (host-app subclass)
  → handler = Backstage::PhotosController.new
  → handler.validate
      → record.update!(status: :verified)
      → render turbo_stream: turbo_stream.replace("photo_42_row", ...)
```

### 4.4 Config DSL evaluation
```
# config/backstage/photo.rb evaluated at boot:
Backstage.resource :photo do
  fields :title, :status, :url
  field :url, as: :image_url
  has_many :tags
  belongs_to :resto
  sidebar do |record|
    link "View on site", record.public_url
  end
  actions :validate, :remove
end

# Backstage.resource(:photo) looks up Registry.resource_for("photo")
# and yields the ResourceConfig to the block
# DSL methods mutate the ResourceConfig in place
# After block: Registry entry is updated
```

---

## 5. Routing

```ruby
# lib/backstage/config/routes.rb
Backstage::Engine.routes.draw do
  root to: "home#index"

  get  "dashboards/:name", to: "dashboards#show", as: :dashboard

  # Dynamic resource routing — all model routes share one controller
  scope ":resource" do
    get    "/",          to: "resources#index",   as: :resources
    get    "/new",       to: "resources#new",     as: :new_resource
    post   "/",          to: "resources#create"
    get    "/:id/edit",  to: "resources#edit",    as: :edit_resource
    patch  "/:id",       to: "resources#update",  as: :resource
    delete "/:id",       to: "resources#destroy"
    post   "/:id/:action_name", to: "actions#create", as: :resource_action
  end
end
```

The `:resource` segment is validated at the controller level against registered model names — an unregistered resource name returns 404.

---

## 6. Key Design Decisions & Rationale

### D1: Single `ResourcesController` for all models
Rather than generating a controller per model (Administrate's approach), one controller handles all resources by looking up the `ResourceConfig` from the registry. This keeps the gem self-contained and requires no code generation per model.

### D2: Registry as single source of truth
All runtime knowledge about resources lives in the registry, built at boot. Controllers and views never import model-specific logic — they always go through the registry. This makes the gem genuinely model-agnostic.

### D3: Field partials for rendering dispatch
Rendering dispatch via partial paths (rather than a giant case statement in a helper) is the Rails-idiomatic extension point. Host apps can override any field partial by placing a file at the same path in their own `app/views/backstage/fields/` directory — standard Rails view override behaviour.

### D4: Hybrid controller subclassing for custom actions
Zero config for standard CRUD. Host-app subclasses only needed for custom actions. `safe_constantize` lookup is clean, well-understood Rails pattern. No monkey-patching or concern injection required.

### D5: Stimulus for JS behaviour
Two small, focused Stimulus controllers. No jQuery, no external component libraries. Fully compatible with import maps. Host apps can override by defining a controller with the same identifier.

### D6: No route generation at boot
Routes use dynamic `:resource` segment rather than generating routes per model. This avoids requiring a `routes.rb` reload when models are added/removed from config, and keeps the engine's route table minimal.

---

## 7. Extension Points

These are the documented extension points for host-app developers and open-source contributors:

| Extension point | How |
|---|---|
| Override a field partial | Place `app/views/backstage/fields/_my_type.html.erb` in host app |
| Override any engine view | Place matching path under `app/views/backstage/` in host app |
| Custom action logic | Subclass `Backstage::ResourceController` as `Backstage::MyModelsController` |
| Custom field type | Use `field :col, partial: "my_app/admin/fields/my_type"` in resource config |
| Override Stimulus controller | Pin same controller name in host app's importmap |
| Override CSS | Add stylesheet after `backstage` in host app's layout |

---

## 8. Security Considerations

- **Authentication:** `before_action` on `Backstage::ApplicationController` — runs on every request, cannot be bypassed per-route
- **CSRF:** Standard Rails `protect_from_forgery` inherited by engine controller
- **Mass assignment:** `permitted_params` built from `resource_config.edit_fields` — only configured fields are permitted, no `permit!`
- **Resource validation:** `:resource` param validated against registry at controller level — prevents enumeration of unregistered models
- **YAML safety:** Config loaded with `YAML.safe_load` — no Ruby object deserialisation from YAML values

---

## 9. Testing Strategy

### Unit tests (`test/`)
- `Backstage::AutoDiscovery` — given a model class, produces correct field list
- `Backstage::ResourceConfig` — DSL methods mutate config correctly
- `Backstage::Registry` — registration, lookup, boot sequence
- `Backstage::Configuration` — YAML parsing, defaults, validation errors

### Controller tests (`test/controllers/`)
- `ResourcesController` — index, edit, create, update, destroy for dummy models
- `ActionsController` — custom action dispatch, host subclass lookup, NotImplementedError
- `DashboardsController` — scope application, row rendering
- Authentication filter — redirects when `is_admin?` returns false

### System tests (`test/system/`)
- Full CRUD flow for Article model in dummy app
- Search and pagination on index
- Enum filter links
- has_many multi-select: add/remove associations
- belongs_to single select
- Thumbnail grid renders on edit page
- Sidebar links render with dynamic URLs
- Dashboard displays scoped records
- Custom action (validate) updates row via Turbo Stream
- Bookmarklet URL pattern is predictable

### Dummy app models
```ruby
# Article: string, text, boolean, datetime, enum, belongs_to Tag
# Tag: string — minimal, used for association tests
```

---

## 10. Implementation Tickets

Tickets are scoped to the four PRD milestones. Each ticket is sized for a single focused session in Claude Code.

---

### Milestone 1 — Core Engine

**BACK-001: Gem skeleton**
Set up the gem structure: `backstage.gemspec`, `lib/backstage.rb`, `lib/backstage/engine.rb` with `isolate_namespace Backstage`, `Gemfile`, `Rakefile`, `LICENSE`, `CHANGELOG.md`. Engine should be mountable with `mount Backstage::Engine, at: "/admin"` and respond to `GET /admin` with a 200.

**BACK-002: Configuration loader**
Implement `Backstage::Configuration` and `Backstage.load_configuration!(root)`. Parse `config/backstage.yml` with `YAML.safe_load`. Expose `admin_user_method`, `redirect_on_failure`, `per_page`, `model_names`, `dashboard_configs`. Raise `Backstage::ConfigurationError` with a descriptive message on invalid config. Test: valid YAML loads correctly; missing required keys raise.

**BACK-003: Auto-discovery**
Implement `Backstage::AutoDiscovery.build(model_class)`. Reflect on `model_class.columns` to build a list of `Field` objects. Map column types to field types. Detect enums via `model_class.defined_enums`. Set `display_column` to first of `:name`, `:title`, `:email`, `:id`. Exclude system columns from edit fields. Test: given `Article` model, produces correct field list.

**BACK-004: Registry**
Implement `Backstage::Registry` as a singleton. `Backstage.load_configuration!` populates the registry by calling `AutoDiscovery.build` for each model name. Expose `resource_for(model_name)`, `all_resources`. Test: registry populated correctly at boot; unknown model name raises.

**BACK-005: Authentication filter**
Implement `Backstage::ApplicationController` with `before_action :verify_admin!`. Call `current_user.public_send(admin_user_method)` — redirect to `redirect_on_failure` if false or if `current_user` is nil. Test: request without admin access redirects; request with admin access proceeds.

**BACK-006: Routes**
Implement engine `config/routes.rb` with dynamic `:resource` segment routing. All routes resolve to correct controller actions. `:resource` validated against registry — unregistered name returns 404. Test: route recognition for all CRUD actions.

**BACK-007: ResourcesController — index**
Implement `ResourcesController#index`. Load `current_resource_config`. Fetch records with offset/limit pagination (`params[:page]`, `per_page` from config). Apply search filter on `display_column` if `params[:q]` present (case-insensitive `LIKE`). Render `resources/index.html.erb`. Test: pagination; search; unknown resource returns 404.

**BACK-008: Index view**
Implement `app/views/backstage/resources/index.html.erb`. Render a table with `resource_config.index_fields` as columns. Each row links to `edit_resource_path`. Pagination links at bottom. Search form at top. "New [Resource]" button. Test: correct columns rendered; links correct.

**BACK-009: ResourcesController — edit/update**
Implement `edit` and `update` actions. `edit`: find record, render form. `update`: find record, call `update` with permitted params (built from `edit_fields`), redirect to index on success, render edit with 422 on failure (Turbo Stream error response). Test: valid update redirects; invalid update renders errors.

**BACK-010: ResourcesController — new/create**
Implement `new` and `create` actions. `new`: instantiate new record, render form. `create`: build and save, redirect to edit on success, render new with 422 on failure. Test: successful create; validation failure.

**BACK-011: ResourcesController — destroy**
Implement `destroy`. Find and destroy record, redirect to index with notice. Test: record deleted; redirect correct.

**BACK-012: Edit/form views**
Implement `resources/edit.html.erb` and `resources/_form.html.erb`. Iterate `resource_config.edit_fields`, render each via field partial. Render system columns (id, created_at, updated_at) read-only at bottom. Delete button with `data-controller="confirm-action"`. Test: form renders all field types; system columns read-only.

**BACK-013: Field partials — basic types**
Implement field partials for: `_string`, `_integer`, `_text`, `_boolean`, `_date`, `_datetime`. Each renders the appropriate Rails form helper for edit, and plain display value for index. Test: each type renders correctly in edit and display contexts.

**BACK-014: Home controller and view**
Implement `HomeController#index`. Load all resources from registry, compute record count for each. Render `home/index.html.erb` with model list, counts, and links to index pages. Test: all registered models listed with correct counts.

**BACK-015: Pico CSS and layout**
Vendor Pico CSS in `app/assets/stylesheets/backstage/pico.css`. Implement engine layout `backstage/backstage.html.erb`: nav with model links, main content area, sidebar slot (empty if no sidebar content). Add `backstage.css` for two-column layout and engine-specific overrides. Test: layout renders without errors; CSS served correctly.

**BACK-016: Install generator**
Implement `rails generate backstage:install`. Creates `config/backstage.yml` from template with commented examples. Appends `mount Backstage::Engine, at: "/admin"` to `config/routes.rb`. Prints next-steps message. Test: generator creates correct files.

**BACK-017: Dummy app and base test suite**
Set up `test/dummy` as a minimal Rails 8 app with `Article` (string, text, boolean, datetime, enum) and `Tag` (string) models. Configure `config/backstage.yml` for both models. Implement `test/test_helper.rb`. Write controller tests for all CRUD actions. Write one system test for the full Article CRUD flow.

---

### Milestone 2 — Field & Association Configuration

**BACK-018: ResourceConfig DSL loader**
Implement DSL evaluation: at boot, after auto-discovery, `Dir.glob("config/backstage/*.rb")` loads each file. `Backstage.resource(:model_name) { |config| ... }` yields the `ResourceConfig` to the block. DSL methods (`fields`, `field`, `exclude`, `display_column`) mutate the config. Test: DSL overrides auto-discovered values correctly.

**BACK-019: `fields` and `exclude` DSL**
Implement `fields(*cols)` — sets `index_fields` to the declared columns in order. Implement `exclude(*cols)` — removes named columns from both index and edit fields. Test: fields reorders index columns; exclude removes from both contexts.

**BACK-020: `field` override DSL**
Implement `field(name, **opts)` — finds or creates a `Field` in the config and merges options (`as:`, `partial:`, `format:`, `readonly:`). Test: field override applied; unoverridden fields unchanged.

**BACK-021: Enum field rendering**
Implement `_enum.html.erb` partial — renders `select` with enum values on edit form. On index, display human-readable value. Implement enum filter links above index table: one link per enum value, plus "All". Auto-detect enum fields in `AutoDiscovery`. Test: select renders correct options; filter links filter correctly.

**BACK-022: `belongs_to` and `has_one` DSL + partial**
Implement `belongs_to` and `has_one` DSL methods on `ResourceConfig`. Store as `AssociationConfig`. Implement `_belongs_to.html.erb` — renders `select` populated from associated model's records (using `display_column`). Blank option for nullable. Test: select populated; saving updates foreign key.

**BACK-023: `has_many` multi-select DSL + partial**
Implement `has_many` DSL method. Implement `_has_many.html.erb` — renders a searchable checkbox list via Stimulus `multi-select` controller. Hidden `<select multiple>` synced on submit for Rails params. Saving updates the association. Test: checkboxes rendered; add/remove associations; search filters checkboxes.

**BACK-024: Stimulus multi-select controller**
Implement `multi_select_controller.js`. Targets: search input, checkbox list, hidden select. On search input: filter visible checkboxes by label text match. On form submit: sync checked checkboxes to hidden select options. Register in engine importmap. Test: search filters; form submits correct params.

**BACK-025: `has_many as: :thumbnails` DSL + partial**
Implement `has_many :photos, as: :thumbnails` DSL option. Implement `_thumbnails.html.erb` — renders `<figure>` grid with `<img src="record.url">` and link to photo edit page. `url` column configurable via `image_col:` option (default `:url`). CSS custom property `--backstage-thumbnail-size` controls size. Test: thumbnails render; links correct.

**BACK-026: `field as: :image_url` partial**
Implement `_image_url.html.erb` — renders `<img>` on both index and edit form (read-only display; URL is editable as string field beneath). Test: image renders; URL editable.

**BACK-027: Sortable index columns**
Add sort params (`sort`, `dir`) to `ResourcesController#index`. Apply `order(sort => dir)` to the query. Sanitise sort column against `index_fields` column names. Column header links in index view toggle sort direction. Sort state persisted in URL. Test: sort ASC/DESC; invalid sort column ignored.

**BACK-028: Milestone 2 system tests**
Write Capybara system tests for: enum select and filter; belongs_to single select; has_many multi-select with search; thumbnail grid; sortable columns; field override (custom format).

---

### Milestone 3 — Dashboards, Sidebars & Custom Actions

**BACK-029: Dashboard config and routing**
Implement `Backstage::DashboardConfig` value object from YAML definition. Register dashboards in registry at boot. Implement `DashboardsController#show`: load dashboard config, apply scope (`where(scope_hash)`), paginate. Render `dashboards/show.html.erb`. Test: correct records returned for scope; pagination works.

**BACK-030: Dashboard view**
Implement `dashboards/show.html.erb`. Render table using resource's configured index fields. Per-row action buttons for each declared action. Action button submits `POST /admin/:resource/:id/:action_name` via a small form. Each action button wrapped in `confirm-action` Stimulus controller if action name includes "remove" or "delete" (configurable). Test: records rendered; action buttons present.

**BACK-031: Dashboard counts on home page**
Update `HomeController#index` to also load dashboard configs and compute record count for each (applying scope). Render dashboard section on home page with title, count, and link. Test: counts correct; scoped correctly.

**BACK-032: Sidebar DSL**
Implement `sidebar(&block)` DSL on `ResourceConfig`. Block stored as a `SidebarConfig` — an array of `{label:, url_or_proc:}` structs built by `link` calls within the block. Implement sidebar rendering in engine layout: if `resource_config.sidebar_links.any?`, render right-column `<aside>` with links, evaluating procs with the current record. Test: static links render; dynamic links evaluated correctly.

**BACK-033: Custom actions routing**
Update engine routes: `post "/:id/:action_name", to: "actions#create"`. Implement `ActionsController`. Resolve host-app controller subclass via `resource_config.controller_class`. Dispatch to action method on subclass instance. Raise `NotImplementedError` with helpful message if method not found. Test: host subclass action called; NotImplementedError raised when not found.

**BACK-034: Turbo Stream custom action responses**
Implement `respond_with_success(message)` and `respond_with_row_removed` helpers in `Backstage::ResourcesController` (available to subclasses). Each returns a Turbo Stream response targeting the record's row by DOM id (`"#{resource_name}_#{record.id}_row"`). Index and dashboard row partials use this id convention. Test: Turbo Stream response updates correct DOM element.

**BACK-035: Confirm action Stimulus controller**
Implement `confirm_action_controller.js`. Intercepts form submit, calls `window.confirm` with configurable message (`data-confirm-action-message-value`). Cancels submit if rejected. Register in engine importmap. Test: confirmation shown; cancel prevents submission; confirm allows it.

**BACK-036: Milestone 3 system tests**
Write Capybara system tests for: dashboard renders scoped records; custom action dispatched to host subclass; Turbo Stream row update; sidebar static and dynamic links; confirm dialog shown for destructive actions.

---

### Milestone 4 — Open Source Readiness

**BACK-037: README**
Write `README.md` covering: what Backstage is, installation, mounting, YAML config reference, Ruby DSL reference, custom actions guide, sidebar guide, bookmarklet reference implementation (10-line JS example), contributing link.

**BACK-038: Bookmarklet documentation**
Document and test the reference bookmarklet. Example:
```javascript
javascript:(function(){
  var m = location.pathname.match(/\/(\w+)\/(\d+)/);
  if(m){ location.href = '/admin/' + m[1] + '/' + m[2] + '/edit'; }
})();
```
Include in README. Verify URL pattern works across dummy app routes.

**BACK-039: CHANGELOG and versioning**
Write `CHANGELOG.md` with v0.1.0 entry. Document public API surface (YAML keys + DSL methods) in README under "Versioning" section. Add `VERSION` constant to `lib/backstage/version.rb`.

**BACK-040: GitHub Actions publish workflow**
Add `.github/workflows/publish.yml`: on tag push (`v*`), run tests, then `gem push`. Add `.github/workflows/test.yml`: on push/PR, run full test suite against Ruby 3.2 + 3.3, Rails 8.0. Add test matrix for SQLite (default), PostgreSQL, MySQL.

**BACK-041: Contributing guide**
Write `CONTRIBUTING.md`: how to set up dev environment, run tests, add a field type, add a DSL method, PR process, code style (StandardRB).

**BACK-042: Final dummy app polish**
Ensure dummy app demonstrates all v1 features: two models with all field types, associations, enums, sidebar, dashboard, custom action. Update `README.md` with screenshot or ASCII example of the home page.
