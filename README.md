# Backstage

A lightweight, mountable admin interface for Rails 8. Drop it into any app with a single YAML file — no code generation, no Devise dependency, no Node pipeline.

## Features

- Auto-discovers columns and builds index/edit pages from ActiveRecord reflection
- YAML model registration — adding a model takes one line
- Optional per-resource Ruby DSL for field overrides, associations, sidebars, and custom actions
- Named dashboards with custom scopes
- Searchable, sortable, paginated index tables
- Enum filter tabs, belongs-to dropdowns, has-many checkbox lists with search
- Turbo Stream responses for delete/custom actions (no full-page reload)
- Pico CSS vendored — zero asset pipeline setup required

## Installation

Add to your Gemfile:

```ruby
gem "backstage"
```

Run the installer:

```bash
bundle install
bin/rails generate backstage:install
```

The generator creates `config/backstage.yml` and mounts the engine in `config/routes.rb`:

```ruby
mount Backstage::Engine, at: "/admin"
```

## Authentication

Backstage does not handle authentication itself. It calls a method on `current_user` to decide whether to allow access. You must define `current_user` in your application controller and ensure it is accessible from Backstage's controllers.

Add to `config/initializers/backstage.rb` (or any initializer):

```ruby
Rails.application.config.to_prepare do
  Backstage::ApplicationController.class_eval do
    def current_user
      # return the current user object from your auth system
      # e.g. User.find_by(id: session[:user_id])
    end
  end
end
```

Configure the admin check in `config/backstage.yml`:

```yaml
admin_user_method: is_admin?   # method called on current_user (default: is_admin?)
redirect_on_failure: /login    # where to redirect non-admins (default: /)
```

## Configuration

### `config/backstage.yml`

```yaml
# Models to manage (required)
models:
  - Article
  - User
  - Tag

# Method called on current_user to check admin access
admin_user_method: is_admin?

# Where to redirect non-admin users
redirect_on_failure: /

# Records per page on index
per_page: 25

# Named dashboards
dashboards:
  - name: "Recent Drafts"
    model: Article
    scope: draft
```

Dashboards reference a named scope on the model. The scope must exist on the model class.

### Per-resource DSL (`config/backstage/*.rb`)

Create a file named after the model (e.g. `config/backstage/article.rb`):

```ruby
Backstage.resource(:Article) do |c|
  # Control which columns appear on the index table
  c.fields :title, :status, :published_at

  # Remove columns from both index and edit
  c.exclude :legacy_column

  # Override a field's display type
  c.field :body, as: :text
  c.field :cover_image_url, as: :image_url

  # Set the column used as the display name in belongs-to dropdowns
  c.display_column :title

  # Belongs-to association (replaces the foreign key field with a dropdown)
  c.belongs_to :author, display_column: :name, class_name: "User"

  # Has-many checkbox list with search
  c.has_many :tags, display_column: :name

  # Has-many as thumbnail grid (read-only)
  c.has_many :images, as: :thumbnails, image_col: :url

  # Sidebar links (appear next to the edit form)
  c.sidebar do |s|
    s.link "View on site", ->(record) { "/posts/#{record.id}" }
    s.link "All articles", "/admin/articles"
  end
end
```

### Field types

| Type | Auto-detected from | Notes |
|---|---|---|
| `:string` | `string`, `varchar` columns | Text input |
| `:integer` | `integer` columns | Number input |
| `:text` | `text` columns | Textarea |
| `:boolean` | `boolean` columns | Checkbox |
| `:date` | `date` columns | Date input |
| `:datetime` | `datetime` columns | Datetime-local input |
| `:enum` | `enum` columns | Select with filter tabs on index |
| `:belongs_to` | Set via DSL | Dropdown of associated records |
| `:has_many` | Set via DSL | Searchable checkbox list |
| `:thumbnails` | Set via DSL (`as: :thumbnails`) | Read-only image grid |
| `:image_url` | Set via DSL | Inline `<img>` rendered from a URL string |

### Custom field partials

Override any field type for a specific resource by pointing to your own partial:

```ruby
c.field :status, partial: "my_app/fields/status_badge"
```

Or place a partial at `app/views/backstage/fields/_my_type.html.erb` to override for all resources.

## Custom Actions

For actions beyond standard CRUD, create a controller that inherits from `Backstage::ResourcesController`:

```ruby
# app/controllers/backstage/articles_controller.rb
class Backstage::ArticlesController < Backstage::ResourcesController
  def publish
    @record.update!(status: :published)
    respond_with_success("Article published")
  end
end
```

Add a button to the edit form using a custom view override or sidebar link, and post to the action route:

```erb
<%= button_to "Publish", admin_action_path(resource: "articles", id: @record.id, action_name: "publish"), method: :post %>
```

The `respond_with_success` and `respond_with_row_removed` helpers render Turbo Stream responses that update the page without a full reload.

## Bookmarklet

Add a bookmarklet to your browser to jump from any record's show page directly to its Backstage edit page. Save this as a bookmark with the URL field set to:

```javascript
javascript:(function(){var m=location.pathname.match(/\/(\w+)\/(\d+)/);if(m){location.href='/admin/'+m[1]+'/'+m[2]+'/edit';}})();
```

This matches URL patterns like `/articles/42` and navigates to `/admin/articles/42/edit`. Adjust the path prefix if your engine is not mounted at `/admin`.

## Versioning

The public API consists of:
- `config/backstage.yml` keys: `models`, `admin_user_method`, `redirect_on_failure`, `per_page`, `dashboards`
- Ruby DSL methods on `ResourceConfig`: `fields`, `exclude`, `field`, `display_column`, `has_many`, `belongs_to`, `sidebar`
- Turbo Stream helper methods on `ResourcesController`: `respond_with_success`, `respond_with_row_removed`

Changes to this surface follow semantic versioning. Internal classes (`AutoDiscovery`, `Registry`, `Field`, `AssociationConfig`) are not part of the public API and may change between minor versions.

## License

MIT
