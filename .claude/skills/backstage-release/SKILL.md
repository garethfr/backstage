---
name: backstage-release
description: Cut a new Backstage gem release. Bumps version, writes CHANGELOG entry, commits, tags, and pushes to trigger the GitHub Actions publish workflow.
---

# backstage-release

Cut a new release of the Backstage gem. Work through each step in order, confirming with the user before making changes.

---

## Step 1 — Confirm everything is ready

Before touching any files, check:

- Run `bundle exec rake test` — all tests must pass. Stop if any fail.
- Run `standardrb` — no offences. Stop if any fail.
- Check `git status` — working tree must be clean (all changes committed). Stop if dirty.

Report results before proceeding.

---

## Step 2 — Determine the new version number

Read `lib/backstage/version.rb` to get the current version.

Ask the user: **"Current version is X.Y.Z. What should the new version be?"**

Follow [Semantic Versioning](https://semver.org/):
- **Patch** (X.Y.Z+1) — bug fixes, no new API
- **Minor** (X.Y+1.0) — new features, backwards compatible
- **Major** (X+1.0.0) — breaking changes

---

## Step 3 — Collect release notes

Ask: **"What should go in the CHANGELOG for this release?"**

If the user isn't sure, run `git log vPREVIOUS..HEAD --oneline` (where PREVIOUS is the last tagged version from `git tag --sort=-v:refname | head -1`) to show commits since the last release. Summarise them into bullet points grouped as Added / Changed / Fixed / Removed, and confirm with the user before writing.

---

## Step 4 — Bump the version

Edit `lib/backstage/version.rb`:

```ruby
module Backstage
  VERSION = "NEW_VERSION"
end
```

---

## Step 5 — Update CHANGELOG.md

Read the current `CHANGELOG.md`. Add a new section **above** the most recent release entry (but below `## [Unreleased]`):

```markdown
## [NEW_VERSION] — YYYY-MM-DD

### Added
- ...

### Fixed
- ...
```

Use today's date. Only include sections (Added / Changed / Fixed / Removed) that have entries. Move anything from `## [Unreleased]` into this section and leave `## [Unreleased]` empty.

---

## Step 6 — Commit

Stage only release files:

```bash
git add lib/backstage/version.rb CHANGELOG.md
git commit -m "Release v{NEW_VERSION}"
```

---

## Step 7 — Tag and push

```bash
git tag vNEW_VERSION
git push origin main
git push origin vNEW_VERSION
```

Pushing the tag triggers the GitHub Actions publish workflow (`.github/workflows/publish.yml`), which builds and pushes the gem to RubyGems automatically.

---

## Step 8 — Verify

- Check the Actions tab on GitHub to confirm the publish workflow ran successfully.
- Confirm the new version appears at https://rubygems.org/gems/backstage.

---

## Summary

After completion, print:
- New version number
- Tag pushed
- Link to the GitHub Actions run (if available from `gh run list --workflow=publish.yml --limit=1`)
- Any manual steps remaining (e.g. if the publish workflow is not configured)
