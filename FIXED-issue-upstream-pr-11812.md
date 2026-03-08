# Upstream Tracking: Fix `run --attach` agent validation crash

## Type
Bug Fix / Upstream Dependency

## Upstream Reference

| Field | Value |
|-------|-------|
| **Repository** | anomalyco/opencode |
| **PR** | [#11812](https://github.com/anomalyco/opencode/pull/11812) |
| **Title** | fix: `run --attach` agent validation and forward cwd |
| **Author** | @alberti42 |
| **Status** | Open (awaiting review) |
| **Branch** | `alberti42:dev-fork-fix-agent-attach` |
| **Target** | `anomalyco:dev` |

## Related Issues Fixed by This PR

| Issue | Title | Status | Reporter |
|-------|-------|--------|----------|
| [#6489](https://github.com/anomalyco/opencode/issues/6489) | Specify an agent when attaching to server fails | Open | @mschenk42 |
| [#8094](https://github.com/anomalyco/opencode/issues/8094) | Unable to use `--agent` option when using `run` with `--attach` | Open | @mschenk42 |

## Dupe/Superceded PRs

| PR | Title | Status | Author | Relationship |
|----|-------|--------|--------|--------------|
| [#8154](https://github.com/anomalyco/opencode/pull/8154) | fix(cli): skip local agent validation in attach mode | Open (older) | @zerone0x | Earlier attempt at fix - skips validation entirely rather than validating against server |
| [#13844](https://github.com/anomalyco/opencode/pull/13844) | fix(attach): default working directory to invoker's cwd | Closed | @R44VC0RP | Related to attach/cwd behavior but closed by author |

## Problem Statement

When using `opencode run` with both `--attach` and `--agent` flags, the CLI crashes with:

```
Error: No context found for instance
      at use (src/util/context.ts:16:21)
      at directory (src/project/instance.ts:42:20)
      at src/project/instance.ts:63:31
      at src/project/state.ts:14:19
      at get (src/agent/agent.ts:231:12)
      at get (src/agent/agent.ts:230:29)
      at src/cli/cmd/run.ts:234:35
```

### Root Cause

- The `--attach` code path in `packages/opencode/src/cli/cmd/run.ts` does **not** run `bootstrap(...)`, so no `Instance` async-local context is created
- The CLI tried to validate `--agent` via `Agent.get(...)`, which depends on `Instance.state(...)` and requires that context
- Result: immediate crash before any request is sent to the attached server

## Proposed Fix

When `--attach` is used, validate `--agent` against the attached server instead of locally:

1. Query the attached server via `GET /agent` (SDK: `sdk.app.agents()`) to get available agents
2. Validate the specified agent against the server's agent list
3. If the agent doesn't exist (or is `mode: "subagent"`), print a warning and fall back to the default agent
4. If the agent list can't be fetched, warn and fall back

### Files Changed

- `packages/opencode/src/cli/cmd/run.ts`

## Release Note

> Fix crash when running `opencode run --attach ... --agent ...` by validating agents on the attached server.

## Impact on Jeeves

### Relevance

This upstream fix is important for Jeeves users who:
- Run the OpenCode server in a container (like Jeeves)
- Use `opencode run --attach` to connect to the containerized server
- Want to specify custom agents with the `--agent` flag

### Current Workaround

Until this PR is merged, users must either:
1. Not use `--agent` when using `--attach` (uses default agent)
2. Use the TUI (`opencode`) instead of `opencode run` for agent selection

### Testing in Jeeves

Once merged, test with:
```bash
# Start Jeeves container
./jeeves.ps1 start

# In another terminal, attach with specific agent
opencode run \
  --attach http://localhost:4096 \
  --agent developer \
  "your prompt here"
```

## Checklist

- [ ] PR #11812 merged into upstream `dev` branch
- [ ] Fix included in upstream release
- [ ] Jeeves Dockerfile updated to new release (if needed)
- [ ] Test `--attach` with `--agent` in Jeeves container
- [ ] Update documentation if behavior changes

## Additional Context

### Discussion Highlights

- **Feb 2, 2026**: PR #11812 opened by @alberti42 as a more comprehensive alternative to #8154
- **Feb 3, 2026**: Conventional commit title formatting fixed
- **Feb 7, 2026**: @BlankParticle noted that forwarding `process.cwd()` could cause issues when client and server are on different machines/filesystems
- **Feb 8, 2026**: @alberti42 removed the cwd forwarding based on feedback
- **Feb 24-25, 2026**: @alberti42 updated PR description to explicitly reference issues and pinged maintainers for review

### Related Issues/PRs to Monitor

- [#8154](https://github.com/anomalyco/opencode/pull/8154) - Earlier simpler fix (may be closed in favor of #11812)
- [#13844](https://github.com/anomalyco/opencode/pull/13844) - Related cwd behavior PR (closed)
- [#12443](https://github.com/anomalyco/opencode/pull/12443) - @BlankParticle's PR adding `--dir` support to `opencode run`

---

**Last Updated**: 2026-03-01
**Tracked by**: Jeeves Project
