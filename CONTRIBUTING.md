# Contributing to Backstage

## Development setup

```bash
git clone https://github.com/your-org/backstage
cd backstage
bundle install
```

The dummy app at `test/dummy/` is a minimal Rails 8 app used for all tests. It is already wired up — no additional setup is needed.

## Running tests

```bash
bundle exec rake test                                              # all tests
bundle exec ruby -I test test/path/to/test_file.rb                # single file
bundle exec ruby -I test test/path/to/test_file.rb -n test_name   # single test
bundle exec rake test:system                                       # system tests only
```

Tests use SQLite3 in-memory (unit/integration) and headless Chrome (system). Chrome must be installed for system tests.

Linting:

```bash
standardrb       # StandardRB (not RuboCop)
```

## Adding a field type

1. Add a partial at `app/views/backstage/fields/_your_type.html.erb`. The partial receives `f` (form builder), `field` (a `Backstage::Field` instance), and `record` (the ActiveRecord object).
2. If the type should be auto-detected from a column type, add the mapping in `Backstage::AutoDiscovery#column_type`.
3. Add a unit test in `test/unit/auto_discovery_test.rb` (if auto-detected) and an integration test for the rendered output.

## Adding a DSL method

DSL methods live in `lib/backstage/resource_config.rb`. Each method mutates the config object; the public API section in `README.md` documents which methods are considered stable.

1. Add the method to `ResourceConfig`.
2. Write a unit test in `test/unit/resource_config_test.rb`.
3. If the method affects rendering, add an integration test verifying the generated HTML.
4. Document the method in `README.md` under "Per-resource DSL".

## Code style

- StandardRB (run `standardrb --fix` to auto-correct)
- No comments unless the WHY is non-obvious
- No `permit!` — always enumerate permitted params explicitly
- `YAML.safe_load` — never `YAML.load`

## Pull requests

- One feature or fix per PR
- All tests must pass (`bundle exec rake test`)
- Update `CHANGELOG.md` under `## [Unreleased]`
- If the PR changes the public API, update `README.md`

## Releasing

Releases are made by pushing a version tag:

```bash
# Bump lib/backstage/version.rb
git commit -am "Bump to v0.2.0"
git tag v0.2.0
git push origin main --tags
```

The `publish` GitHub Actions workflow runs tests and pushes the gem to RubyGems automatically. You must have a `RUBYGEMS_API_KEY` secret set in the repository settings.
