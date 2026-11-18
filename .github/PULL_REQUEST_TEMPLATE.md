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

- [ ] Dotfiles under `home/` (shell rc files, `dot_config/`, etc.)
- [ ] `scripts/sync-agents/` (coding-agent config sync tool)
- [ ] `scripts/setup.sh` (bootstrap entry point)
- [ ] Tooling / CI
- [ ] Documentation (`AGENTS.md`, `README.md`, and subdirectory READMEs)

## Breaking Changes

- [ ] No breaking changes
- [ ] Breaking changes (describe below)

<!--
If this changes an existing symlink target, or moves/removes a tracked dotfile, describe what breaks and why the breakage is justified.
-->

## Deferred Items and TODOs

- Items intentionally deferred and the reasons why.

```txt
If you deferred something due to time constraints, document it here.
Reviewers cannot tell whether something was intentionally skipped or overlooked
without this information.
```

## Test Items

- Describe the bats tests added, following Red/Green TDD (which test was written first, and what it confirmed failed before the implementation existed).
- Confirm `just verify` (shellcheck and bats) passes locally, and note any test that is skipped on your OS.
- If the change touches the bootstrap scripts, note which OS and profile it was exercised on, and whether `setup.sh` was run against a real `$HOME`.

## [Required] Quality Checklist

**Please check all items before merging.**

- [ ] **CI Workflow Execution**: All checks passed on the [CI workflow](../actions/workflows/ci.yml) for this PR.
- [ ] **Code Comments**: None added without the maintainer's explicit permission, per this project's comment policy (see `AGENTS.md`).
- [ ] **Reference Docs**: `README.md` / `AGENTS.md` reflect the actual current scope

> **Important**: This checklist ensures quality. Please verify all items before requesting review.
