---
name: backstage-install
description: Install and configure the Backstage admin engine gem. Checks compatibility, wires up authentication, registers models, optionally configures per-resource DSL and associations, and verifies the admin interface is reachable.
---

# backstage-install

Complete installation and setup of the Backstage admin engine in this Rails app. Work through each step in order, confirming with the user before making any changes.

---

## Step 1 — Compatibility check

Read `Gemfile`, `Gemfile.lock`, and `.ruby-version` (if present) to check:

- **Ruby >= 3.2** — stop with a clear error if not met
- **Rails >= 8.0** — check `Gemfile.lock` for the rails gem version; stop if not met
- **Asset pipeline** — check Gemfile for `propshaft`. Backstage vendors its own CSS and serves it via Propshaft. If the app uses Sprockets instead, warn the user and note that they may need to add `//= link backstage/backstage.css` to `app/assets/config/manifest.js`
- **Conflicts** — check for other admin gems (`rails_admin`, `activeadmin`, `administrate`). Note any found but do not block installation

Report findings before proceeding.

---

## Step 2 — Add gem to Gemfile

Check if `backstage` already appears in the Gemfile. If not:

- Add `gem "backstage"` to the Gemfile
- Run `bundle install`

If already present, skip to Step 3.

---

## Step 3 — Run the install generator

Check `config/routes.rb` for an existing `mount Backstage::Engine` line.

If absent, run the generator:

```bash
bin/rails generate backstage:install
```

This creates `config/backstage.yml` and adds the mount to `config/routes.rb`. If the generator has already been run, skip this step and proceed with the existing files.

---

## Step 4 — Configure authentication

Backstage calls a method on `current_user` to check admin access. You must tell it how to find the current user.

Ask the user:

1. **How is the current user provided?** Common answers: Devise (`current_user`), a custom session helper, a JWT token — or "I don't have auth yet"
2. **What method on the user object indicates admin access?** (default: `is_admin?`)
3. **Where should non-admins be redirected?** (default: `/`)

Check `config/initializers/` for an existing Backstage initializer. If none exists, create `config/initializers/backstage.rb`:

```ruby
Rails.application.config.to_prepare do
  Backstage::ApplicationController.class_eval do
    def current_user
      # TODO: replace with your actual current_user lookup
      # e.g. User.find_by(id: session[:user_id])
      # e.g. Current.user  (if using Current attributes)
      nil
    end
  end
end
```

Then update `config/backstage.yml` with the answers from above:

```yaml
admin_user_method: is_admin?    # or whatever method they specified
redirect_on_failure: /login     # or wherever they want non-admins to go
```

If the user doesn't have authentication set up yet, add the TODO comment and note that the admin will redirect everyone until it's wired up.

---

## Step 5 — Register models

Read `app/models/` to list the available ActiveRecord models (skip `ApplicationRecord` and concerns).

Show the list and ask: **Which models should appear in the admin?**

Update the `models:` list in `config/backstage.yml` with their choices:

```yaml
models:
  - Article
  - User
  - Tag
```

Backstage auto-discovers columns for each model — no further configuration is needed for basic CRUD.

---

## Step 6 — Optional: per-resource DSL

Ask the user: **"Would you like to configure any field overrides, associations, or sidebar links for these models? (optional — you can always add these later)"**

If yes, for each model they want to configure, create `config/backstage/<model_name_lowercase>.rb`. Common patterns:

**Set the display column** (used in belongs-to dropdowns and search):
```ruby
Backstage.resource(:Article) do |c|
  c.display_column :title
end
```

**Override a field type:**
```ruby
Backstage.resource(:Article) do |c|
  c.field :body, as: :text
  c.field :cover_image_url, as: :image_url
end
```

**Belongs-to association** (replaces the raw foreign key field with a dropdown):
```ruby
Backstage.resource(:Article) do |c|
  c.belongs_to :author, display_column: :name, class_name: "User"
end
```

**Has-many checkbox list:**
```ruby
Backstage.resource(:Article) do |c|
  c.has_many :tags, display_column: :name
end
```

**Sidebar links on the edit page:**
```ruby
Backstage.resource(:Article) do |c|
  c.sidebar do |s|
    s.link "View on site", ->(record) { "/posts/#{record.id}" }
  end
end
```

Only create files for models where the user wants customisation. Skip this step entirely if they prefer to configure later.

---

## Step 7 — Optional: dashboard

Ask: **"Would you like a dashboard — a filtered view of a model with a named scope? (optional)"**

If yes, ask for:
1. The model name
2. The scope name (must be a named scope on the model, e.g. `published`, `pending`)
3. A display name for the dashboard (e.g. "Published Articles")

Add to `config/backstage.yml`:

```yaml
dashboards:
  - name: "Published Articles"
    model: Article
    scope:
      status: published
```

Note: the scope value must match a value that `Model.where(scope_hash)` can accept. For integer-backed enums, use the integer value (e.g. `status: 1`).

---

## Step 8 — Verify

Start the Rails server (if not already running) and ask the user to visit `/admin` (or whatever path the engine is mounted at).

Check `config/routes.rb` to confirm the mount path. If the path is not `/admin`, tell the user the correct URL.

Expected results:
- Non-admin users (or unauthenticated users) are redirected to `redirect_on_failure`
- Admin users see the Backstage home page listing registered models and their record counts
- Each model links to a paginated, searchable index table
- Each record has an edit form with auto-discovered fields

If the user reports a problem, help diagnose:
- 404 → engine not mounted, or wrong path
- Redirect loop → `current_user` method raises or returns unexpected value
- Empty model list → `config/backstage.yml` not loaded, or model names misspelled
- Missing columns → model table may not exist yet; run `rails db:migrate`

---

## Step 9 — Optional commit

Ask: **"Would you like to commit these changes?"**

If yes, stage only the files created or modified during this setup:

```bash
git add Gemfile Gemfile.lock config/routes.rb config/backstage.yml \
        config/initializers/backstage.rb
# add any DSL files created in Step 6:
# git add config/backstage/article.rb config/backstage/user.rb
git commit -m "Install Backstage admin engine"
```

Do not use `git add -A` — only stage Backstage-related files.

---

## Summary

After all steps complete, print a summary of:
- Mount path and admin URL
- Models registered
- Authentication method wired up (or TODOs remaining)
- Any DSL or dashboard configuration added
- Any manual steps remaining (implementing `current_user`, adding `is_admin?` to the User model, Sprockets manifest updates if applicable)
