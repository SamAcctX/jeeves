# Troubleshooting Guide

Solutions to common issues with the Jeeves container and the Ralph Loop system.

For command usage, see [commands.md](commands.md). For configuration details and environment variables, see [configuration.md](configuration.md).

---

## Quick Diagnostics

Run these checks first when something goes wrong.

**Inside the container:**
```bash
ls -la .ralph/                          # Ralph directory exists?
cat .ralph/tasks/TODO.md                # Current task state
cat .ralph/tasks/deps-tracker.yaml      # Dependency graph
git status                              # Uncommitted changes or conflicts?
grep "ABORT" .ralph/tasks/TODO.md       # Blocked task?
tail -n 30 .ralph/tasks/*/activity.md   # Recent agent activity
```

**On the host:**
```bash
./jeeves.ps1 status                     # Container running?
./jeeves.ps1 logs                       # Container output
```

---

## 1. Container Issues

### Container Won't Start

**Problem:** `./jeeves.ps1 start` fails with a container creation error.

**Solutions:**

1. Verify Docker is running: `docker info`
2. Check for port 3333 conflicts: `lsof -i :3333` (free with `sudo fuser -k 3333/tcp`)
3. Clean rebuild: `./jeeves.ps1 clean && ./jeeves.ps1 build --no-cache && ./jeeves.ps1 start`
4. Docker socket permissions (Linux, `--dind` mode): `sudo usermod -aG docker $USER && newgrp docker`

### Container Stops Immediately

**Problem:** Container starts but exits without staying running.

**Solutions:**

1. Check logs: `./jeeves.ps1 logs`
2. Debug interactively: `docker run -it --rm --entrypoint /bin/bash jeeves:latest`
3. Inspect configuration: `docker inspect jeeves`

### Permission Issues

**Problem:** `permission denied` errors accessing files inside the container.

The container runs as user `jeeves` (UID/GID 1000). If your host user has a different UID/GID, ownership mismatches occur.

**Solutions:**

1. Check alignment: run `id` on both host and container.
2. Rebuild (auto-maps UID/GID on Linux/macOS): `./jeeves.ps1 build --no-cache`
3. Fix host permissions: `sudo chown -R $(id -u):$(id -g) ~/.opencode ~/.claude`

### GPU/CUDA Issues

**Problem:** GPU not detected or CUDA errors inside the container.

The base image is `nvidia/cuda:12.9.1-cudnn-devel-ubuntu24.04`. GPU passthrough requires the NVIDIA Container Toolkit on the host.

**Solutions:**

1. Verify host drivers: `nvidia-smi`
2. Test toolkit: `docker run --rm --gpus all nvidia/cuda:12.9.1-cudnn-devel-ubuntu24.04 nvidia-smi`
3. Confirm GPU access was passed to the container: `docker inspect jeeves | grep -A5 DeviceRequests`
4. Inside the container, verify CUDA: `nvcc --version`
5. If `nvidia-smi` works on the host but not in the container, the Docker daemon may need NVIDIA runtime configuration. See the [NVIDIA Container Toolkit docs](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html).

---

## 2. Ralph Loop Issues

### Ralph Directory Not Found

**Problem:** `Ralph directory not found: .ralph/`

**Solution:** Run `ralph-init.sh` to initialize, or verify you are in the correct working directory with `pwd`.

### Ralph Loop Fails to Start

**Problem:** `ralph-loop.sh` exits with an error immediately.

**Solutions:**

1. Check required tools:
   ```bash
   command -v yq && echo "OK" || echo "missing"
   command -v jq && echo "OK" || echo "missing"
   command -v git && echo "OK" || echo "missing"
   ```
2. Check agent installation: `ls .opencode/agents/ .claude/agents/ 2>/dev/null`
3. Re-initialize: `ralph-init.sh --force`

### Ralph Loop Stops Immediately (Zero Iterations)

**Problem:** Loop starts but exits without performing any work.

Check these in order:

1. **ABORT sentinel:** `grep "ABORT: HELP NEEDED" .ralph/tasks/TODO.md` -- If found, a task previously signaled TASK_BLOCKED. Fix the issue, then remove the line: `sed -i '/^ABORT:/d' .ralph/tasks/TODO.md`
2. **Completion sentinel:** `grep "ALL TASKS COMPLETE" .ralph/tasks/TODO.md`
3. **Invalid deps file:** `yq eval '.' .ralph/tasks/deps-tracker.yaml`

### Loop Appears Stuck

**Problem:** No output for an extended period.

**Solutions:**

1. Check the process: `ps aux | grep -E "opencode|claude"`
2. Monitor activity: `tail -f .ralph/tasks/*/activity.md`
3. Use `ralph-peek.sh` to attach to the active session (see [Debugging Tools](#10-debugging-tools--techniques)).
4. Interrupt with Ctrl+C and restart if needed. The loop is safe to restart.

### Iteration Limit Reached

**Problem:** `GLOBAL_ITERATION_LIMIT_REACHED: 100 iterations`

**Solutions:**

1. Review progress: `cat .ralph/tasks/TODO.md`
2. Increase the limit: `ralph-loop.sh --max-iterations 200` (or `0` for unlimited)
3. Check for stuck tasks: `grep -c "^## Attempt" .ralph/tasks/*/attempts.md`

### Git Conflicts in Ralph State Files

**Problem:** `Git conflict detected: .ralph/tasks/TODO.md`

**Cause:** Manual edits while the loop was running, or concurrent modifications.

**Solution:** Stop the loop (Ctrl+C), resolve conflicts manually, then `git add` and `git commit` the affected files. Restart the loop.

**Prevention:** Never edit TODO.md or deps-tracker.yaml while the loop is running.

---

## 3. Agent Issues

### Agent Not Found

**Problem:** `Agent 'developer' not found` during sync or loop execution.

**Solutions:**

1. Verify agent files: `ls .opencode/agents/ .claude/agents/`
2. Run sync: `sync-agents.sh`
3. Re-initialize: `ralph-init.sh --force`

All 10 agent types should be present: manager, architect, developer, ui-designer, tester, researcher, writer, decomposer, decomposer-architect, decomposer-researcher.

### Agent Sync Failed

**Problem:** `Agent sync failed after Xs (continuing anyway)`

This is a non-critical warning. The loop continues regardless.

**Solutions:**

1. Validate agents.yaml: `yq eval '.' .ralph/config/agents.yaml`
2. Common issues: tabs instead of spaces, missing colons, incorrect indentation.
3. For OpenCode agents, model values should be `""` (empty string), not `"inherit"`.

### Wrong Agent or Model Selected

**Problem:** The loop dispatches the wrong agent type or uses an unexpected model.

**Solutions:**

1. Inspect configurations: `sync-agents.sh --show`
2. Verify agents.yaml maps the correct models (see [configuration.md](configuration.md)).
3. Re-sync after editing: `sync-agents.sh`

### Tool Command Not Found

**Problem:** `opencode: command not found` or `claude: command not found`

- OpenCode: verify with `which opencode`
- Claude Code: only available if built with `--install-claude-code`. Check with `which claude`.

---

## 4. Signal System Issues

### Signal Not Detected

**Problem:** Task finished but the loop continues iterating on the same task.

**Cause:** The agent did not emit a properly formatted signal.

**Rules for valid signals:**
- Must be the first token on its own line
- No prefix text before the signal
- Exactly one signal per execution
- Task ID must be exactly 4 digits with leading zeros

**Valid examples:**
```
TASK_COMPLETE_0042
TASK_INCOMPLETE_0042
TASK_FAILED_0042: syntax error in module
TASK_BLOCKED_0042: needs human input
```

**Invalid examples:**
```
Result: TASK_COMPLETE_0042     # Not first token
task_complete_0042             # Wrong case
TASK_COMPLETE_42               # Must be 4 digits
```

**Diagnosis:** `tail -20 .ralph/tasks/XXXX/activity.md`

### Malformed Signal

**Problem:** Manager does not recognize the worker response.

- TASK_FAILED and TASK_BLOCKED require a colon and message: `TASK_FAILED_0042: error description`
- TASK_COMPLETE and TASK_INCOMPLETE take no message: `TASK_COMPLETE_0042`
- Task ID must be 4 digits with leading zeros (`0042`, not `42`)

### Multiple Signals Detected

**Problem:** `Multiple signals detected (3) - using first valid signal`

Only the first valid signal is used. This is usually caused by copy-paste artifacts in agent responses.

### Unexpected TASK_BLOCKED

**Problem:** A task signals TASK_BLOCKED, the Manager writes `ABORT: HELP NEEDED` to TODO.md, and the loop stops.

**Recovery:**

1. Read the blockage reason: `cat .ralph/tasks/XXXX/activity.md`
2. Fix the underlying issue manually.
3. Remove the ABORT line: `sed -i '/^ABORT:/d' .ralph/tasks/TODO.md`
4. Restart the loop.

---

## 5. Dependency Tracking Issues

### Circular Dependency Detected

**Problem:** Tasks cannot proceed because of a dependency cycle.

**Diagnosis:** `cat .ralph/tasks/deps-tracker.yaml`

**Solution:** Break the cycle by removing one dependency edge:
```yaml
tasks:
  "0001":
    depends_on: ["0002"]
  "0002":
    depends_on: ["0003"]
  "0003":
    depends_on: []           # Was ["0001"] -- cycle broken
```

### Task Not Selected Despite Being in TODO

**Problem:** A task is incomplete in TODO.md but the loop never picks it up.

**Cause:** Unmet dependencies in deps-tracker.yaml.

**Diagnosis:** `yq eval '.tasks."XXXX".depends_on' .ralph/tasks/deps-tracker.yaml`

**Solutions:** Complete the blocking tasks, remove the dependency if no longer needed, or check for circular dependencies.

### Invalid deps-tracker.yaml Format

The expected format uses a `tasks` root with `depends_on` and `blocks` arrays:
```yaml
tasks:
  "0001":
    depends_on: []
    blocks: ["0002"]
  "0002":
    depends_on: ["0001"]
    blocks: []
```

**Validate:** `yq eval '.' .ralph/tasks/deps-tracker.yaml`

Common issues: tabs instead of spaces, unquoted task IDs, missing array brackets.

---

## 6. MCP Server Issues

### MCP Servers Not Working

**Problem:** No MCP servers available in OpenCode or Claude Code.

**Solutions:**

1. Preview and install: `install-mcp-servers.sh --dry-run && install-mcp-servers.sh --global`
2. Verify configuration:
   ```bash
   cat ~/.config/opencode/opencode.json | jq .mcp
   cat ~/.claude.json | jq .mcpServers
   ```

### SearXNG Connection Issues

**Problem:** SearXNG MCP server cannot connect to the search service.

1. Verify the URL: `echo $SEARXNG_URL`
2. Test connectivity: `curl -I "$SEARXNG_URL"`
3. Find a public instance at [https://searx.space/](https://searx.space/) if needed.

### Playwright Browser Issues

**Problem:** Playwright MCP server fails or browser automation does not work.

1. Install browsers: `npx playwright install`
2. Verify installation: `ls ~/ms-playwright/ && npx playwright --version`
3. Enable headless mode (required in containers): `export PLAYWRIGHT_MCP_HEADLESS=1`

---

## 7. Network Issues

### Cannot Connect to Internet

**Problem:** Container cannot reach external services.

1. Test DNS: `nslookup api.anthropic.com`
2. Test connectivity: `curl -I https://api.anthropic.com`
3. Check proxy: `env | grep -i proxy`
4. If DNS fails, configure custom DNS in Docker compose. See [configuration.md](configuration.md).

### Web UI Not Accessible

**Problem:** Cannot reach `http://localhost:3333` from the host.

1. Verify container is running: `./jeeves.ps1 status`
2. Check port binding: `docker port jeeves` (expect `3333/tcp -> 0.0.0.0:3333`)
3. Test from inside: `curl -I http://localhost:3333`
4. Check host firewall (Linux: `sudo ufw status`)

### API Authentication Errors

**Problem:** `API connection failed` or `authentication error` when running agents.

1. Verify the key is set: `echo $ANTHROPIC_API_KEY | head -c 10`
2. Test the endpoint: `curl -I https://api.anthropic.com`
3. Check the [Anthropic status page](https://status.anthropic.com) for outages.

---

## 8. Shell and Terminal Issues

### Welcome Message Displays Twice

**Problem:** The Jeeves welcome banner appears twice when attaching.

**Explanation:** This is expected behavior. The message runs once before tmux starts and once inside the tmux session.

**Suppress:** `DISABLE_WELCOME=1 ./jeeves.ps1 shell`

### tmux Issues

**Problem:** tmux fails to start or causes display problems.

- Skip tmux: `./jeeves.ps1 shell --raw` (sets `DISABLE_TMUX=1` internally)
- Inside the container: `export DISABLE_TMUX=1`

### Shell Selection

The container supports both bash and zsh. See [configuration.md](configuration.md) for `DISABLE_WELCOME` and `DISABLE_TMUX` details.

---

## 9. Initialization Issues

### Template Source Not Found

**Problem:** `Template source directory not found: /opt/jeeves/Ralph/templates`

**Solutions:**

1. Verify: `ls /opt/jeeves/Ralph/templates/`
2. Rebuild: `./jeeves.ps1 build --no-cache`

### Ralph Already Initialized

**Problem:** `Existing Ralph installation detected at .ralph/`

- Use `--force` to overwrite: `ralph-init.sh --force`
- Or back up first: `mv .ralph .ralph.backup.$(date +%Y%m%d) && ralph-init.sh`

### Invalid Task ID Format

**Problem:** `Task ID must be 4 digits` or `Task ID must be numeric`

Task IDs must be exactly 4 digits (0001-9999). Rename folders: `mv .ralph/tasks/42 .ralph/tasks/0042`

---

## 10. Debugging Tools and Techniques

### ralph-validate.sh

A sourceable library of validation functions:

```bash
source ralph-validate.sh
validate_task_id "0042"                         # Task ID format
validate_yaml ".ralph/tasks/deps-tracker.yaml"  # YAML syntax
validate_file_exists ".ralph/tasks/TODO.md"     # File existence
validate_dir_exists ".ralph/tasks/0042"         # Directory existence
validate_git_repo                               # Git repository check
```

### ralph-peek.sh

Attach to the most recent OpenCode session to observe agent activity in real time:

```bash
ralph-peek.sh              # TUI mode (default)
ralph-peek.sh --web        # Print web UI URL instead
```

### ralph-filter-output.sh

Filter verbose OpenCode JSON output to show only essential information:

```bash
ralph-filter-output.sh output.json                    # Full output
ralph-filter-output.sh --compact --no-text output.json # Compact, no text
ralph-filter-output.sh --signals output.json           # Signals only
```

Run `ralph-filter-output.sh --help` for all options.

### Verbose Mode

```bash
ralph-loop.sh --verbose    # or -v
```

Enables JSON format output in OpenCode for detailed agent interaction logs.

### Key Log Files

| File | Purpose |
|------|---------|
| `.ralph/tasks/TODO.md` | Task list and completion status |
| `.ralph/tasks/deps-tracker.yaml` | Task dependency graph |
| `.ralph/tasks/XXXX/activity.md` | Per-task execution log |
| `.ralph/tasks/XXXX/attempts.md` | Per-task attempt history |
| `.ralph/tasks/XXXX/TASK.md` | Task requirements and acceptance criteria |
| `.ralph/config/agents.yaml` | Agent model configuration |

### Log Aggregation

```bash
grep -r "ERROR\|FAILED\|BLOCKED" .ralph/tasks/    # Errors across all tasks

for f in .ralph/tasks/*/attempts.md; do            # Find stuck tasks
  count=$(grep -c "^## Attempt" "$f" 2>/dev/null || echo 0)
  [ "$count" -gt 5 ] && echo "$f: $count attempts"
done
```

### Recovery Procedures

**Complete state reset** (corrupted beyond repair):
```bash
cp -r .ralph .ralph.backup.$(date +%Y%m%d)
rm -rf .ralph/tasks/*
git checkout HEAD -- .ralph/tasks/TODO.md .ralph/tasks/deps-tracker.yaml
ralph-init.sh --force
```

**Manual task completion:**
```bash
sed -i 's/- \[ \] 0042/- [x] 0042/' .ralph/tasks/TODO.md
mv .ralph/tasks/0042 .ralph/tasks/done/
```

**Clearing a stuck task:**
```bash
# Option 1: Reset history, keep task definition
mv .ralph/tasks/XXXX/activity.md .ralph/tasks/XXXX/activity.md.old
mv .ralph/tasks/XXXX/attempts.md .ralph/tasks/XXXX/attempts.md.old

# Option 2: Mark done and decompose into smaller tasks
sed -i 's/- \[ \] XXXX/- [x] XXXX/' .ralph/tasks/TODO.md
mv .ralph/tasks/XXXX .ralph/tasks/done/
```

---

## 11. Getting Help

### Collecting Diagnostic Information

```bash
# Host-side
docker version && docker info
./jeeves.ps1 logs > jeeves-debug.log 2>&1

# Container-side
cat .ralph/tasks/TODO.md
cat .ralph/tasks/deps-tracker.yaml
cat .ralph/config/agents.yaml
```

### Platform-Specific Notes

**Windows:** If `./jeeves.ps1` is not recognized:
```powershell
pwsh ./jeeves.ps1
# Or: Set-ExecutionPolicy -Scope Process -Bypass
```

**Linux/macOS:** Install PowerShell Core if not available:
```bash
sudo apt-get update && sudo apt-get install -y powershell   # Ubuntu/Debian
brew install powershell                                       # macOS
```

### Reporting Issues

When filing issues on [GitHub](https://github.com/SamAcctX/jeeves/issues), include:

- Operating system and version
- Docker and PowerShell versions
- Complete error messages
- Steps to reproduce
- Expected vs. actual behavior
- Diagnostic logs from the steps above

### Resources

- [GitHub Issues](https://github.com/SamAcctX/jeeves/issues) -- Report bugs
- [GitHub Discussions](https://github.com/SamAcctX/jeeves/discussions) -- Ask questions
- [Command Reference](commands.md)
- [Configuration Reference](configuration.md)
