<!-- # PULL_REQUEST_TEMPLATE -->

<!-- Remove unnecessary sections to keep the review focused -->

## Related Links

- Issues
  - <!-- <https://github.com/connect0459/dotfiles/issues/xxx> -->
- PRs
  - <!-- <https://github.com/connect0459/dotfiles/pull/xxx> -->

## [Required] Overview

- Describe the problem being solved, its background, and what changes when this PR is merged.
- Links to specs, design documents, or other references are welcome.

```txt
It is difficult to review without knowing the specifications and background.
```

## Scope of Change

- [ ] Shell dotfiles (`.bashrc` / `.bash_profile` / `.bash_aliases` / `.config/`)
- [ ] `sync/` (coding-agent config sync tool)
- [ ] Tooling / CI
- [ ] Documentation (`AGENTS.md` / `README.md`)

## Breaking Changes

- [ ] No breaking changes
- [ ] Breaking changes (describe below)

<!--
If this changes an existing symlink target, or moves/removes a tracked
dotfile, describe what breaks and why the breakage is justified.
-->

## Deferred Items and TODOs

- Items intentionally deferred and the reasons why.

```txt
If you deferred something due to time constraints, document it here.
Reviewers cannot tell whether something was intentionally skipped or overlooked
without this information.
```

## Test Items

- Describe any test considerations beyond the automated bats suite.
- Note whether `bats sync/test/*.bats` and `shellcheck sync/lib/*.sh` were run locally.

## [Required] Quality Checklist

**Please check all items before merging.**

- [ ] **Shell Tests**: `bats sync/test/*.bats` passes
- [ ] **Lint**: `shellcheck sync/lib/*.sh` reports no warnings
- [ ] **Docs in sync**: `AGENTS.md` / `sync/README.md` reflect the actual current scope

> **Important**: This checklist ensures quality. Please verify all items before requesting review.
