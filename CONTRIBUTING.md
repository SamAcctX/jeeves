# Contributing to Jeeves

Guidelines for contributing to the Jeeves container management system and Ralph autonomous task execution framework.

## Prerequisites

- **Docker**: Docker Desktop (Windows/Mac) or Docker Engine (Linux)
- **PowerShell 7.0+**: Pre-installed on Windows 10+; install via `brew install powershell` (macOS) or `sudo apt-get install -y powershell` (Linux)
- **Git**: 2.x+
- **GPU** (optional): NVIDIA GPU with CUDA support

## Getting Started

### Fork and Clone

```bash
git clone https://github.com/SamAcctX/jeeves.git
cd jeeves
```

### Build and Start

All container lifecycle commands run from the **host machine** using `jeeves.ps1`:

```bash
./jeeves.ps1 build --no-cache
./jeeves.ps1 start
./jeeves.ps1 shell
```

### Verify Your Setup

Inside the container:

```bash
opencode --version
claude --version
install-mcp-servers.sh --dry-run
install-agents.sh --global
```

## Development Workflow

### 1. Create a Feature Branch

The `main` branch is protected. All changes must go through pull requests.

```bash
git checkout -b feature/your-feature-name
```

### 2. Make Changes

Follow the code style guidelines defined in [AGENTS.md](AGENTS.md). That file is the single source of truth for:

- PowerShell script conventions (PascalCase, `Write-Log`, `[CmdletBinding()]`)
- Shell script conventions (POSIX bash, `set -e`, `print_info`/`print_success`)
- Dockerfile conventions (multi-stage builds, `nvidia/cuda:12.9.1-cudnn-devel-ubuntu24.04` base, layer optimization)
- Agent template conventions (YAML frontmatter, tool permissions)
- The "no comments unless requested" policy

### 3. Test Your Changes

Testing happens in two contexts -- **host** and **container** -- and it is important to use the right one.

**Host commands** (run from your development machine):

```bash
./jeeves.ps1 build --no-cache
./jeeves.ps1 start
./jeeves.ps1 stop
./jeeves.ps1 shell
```

**Container commands** (run inside the container via `./jeeves.ps1 shell`):

```bash
opencode --version
claude --version
install-mcp-servers.sh --dry-run
install-agents.sh --global
install-skills.sh
```

There is no formal test suite. See the manual testing checklist below.

### 4. Commit and Push

```bash
git add .
git commit -m "feat: your conventional commit message"
git push origin feature/your-feature-name
```

Then open a pull request via the GitHub UI or `gh pr create`.

## Manual Testing Checklist

Before submitting a PR, verify:

- [ ] `./jeeves.ps1 build --no-cache` completes without errors
- [ ] `./jeeves.ps1 start && ./jeeves.ps1 stop` lifecycle works
- [ ] `./jeeves.ps1 shell` provides shell access
- [ ] `install-mcp-servers.sh --dry-run` runs inside container
- [ ] `install-agents.sh --global` runs inside container
- [ ] File permissions work correctly on host
- [ ] Cross-platform compatibility verified (Windows, macOS, Linux where possible)

### Cross-Platform Notes

- **Windows**: Test on Windows 10/11 with PowerShell 7.x
- **macOS**: Test on Intel and Apple Silicon
- **Linux**: Test on Ubuntu 24.04 or Debian derivatives

## Contribution Types

### Bug Reports

Open a [GitHub Issue](https://github.com/SamAcctX/jeeves/issues) with:

- Detailed reproduction steps
- Operating system and version
- Docker version
- PowerShell version
- Container status and relevant logs

### Feature Requests

Open an issue describing the use case, proposed approach, and impact on existing functionality.

### Code Contributions

Bug fixes, new features, performance improvements, refactoring, and cross-platform fixes. Follow the code style in [AGENTS.md](AGENTS.md).

### Documentation

Improvements to any file in `docs/`, `README.md`, `AGENTS.md`, or this file. See [Contributing to Documentation](#contributing-to-documentation) below.

### Ralph Contributions

Agents, skills, templates, and loop improvements. See [Contributing to Ralph](#contributing-to-ralph) below.

## Contributing to Ralph

Ralph is the autonomous task execution framework. Its source lives in `jeeves/Ralph/`.

### Agent Templates

Ralph has 11 agent types with 11 OpenCode and 10 Claude Code templates (OpenCode and Claude Code) in `jeeves/Ralph/templates/agents/`. When contributing a new agent or modifying an existing one:

- Follow the naming convention: `{role}-opencode.md` and `{role}-claude.md`
- Include proper YAML frontmatter with `description`, `mode`, `permission`, and `tools`
- Shared rules live in `jeeves/Ralph/templates/agents/shared/` and are included by all agent templates
- Test with both OpenCode and Claude Code platforms
- See the existing templates for reference

### Skills

Ralph skills live in `jeeves/Ralph/skills/`. Each skill is a directory containing a `SKILL.md` and any supporting files. Current skills:

- `dependency-tracking/` -- Task dependency management and cycle detection
- `git-automation/` -- Branch management, commits, squash merges
- `rationalization-defense/` -- Detect and correct rationalization patterns
- `system-prompt-compliance/` -- Prompt compliance verification

When adding a new skill:

- Create a directory under `jeeves/Ralph/skills/`
- Include a `SKILL.md` with clear instructions
- If the skill has dependencies, include a manifest parseable by `parse_skill_deps.py`
- Update `install-skills.sh` if needed

### Scripts

All scripts live in `jeeves/bin/` (15 total). The core Ralph loop scripts are:

| Script | Purpose |
|--------|---------|
| `ralph-init.sh` | Initialize Ralph scaffolding |
| `ralph-loop.sh` | Main autonomous loop orchestrator |
| `ralph-peek.sh` | Monitor active loop sessions |
| `ralph-paths.sh` | Path resolution utilities |
| `ralph-validate.sh` | Validate Ralph configuration |
| `ralph-filter-output.sh` | Filter agent output for signals |
| `sync-agents.sh` | Sync agent model configurations |

Supporting scripts include `apply-rules.sh`, `find-rules-files.sh`, `install-mcp-servers.sh`, `install-agents.sh`, `install-skills.sh`, `install-skill-deps.sh`, `fetch-opencode-models.sh`, and `parse_skill_deps.py`. See [jeeves/bin/AGENTS.md](jeeves/bin/AGENTS.md) for full details.

Changes to loop scripts should preserve the signal-based state machine (COMPLETE, INCOMPLETE, FAILED, BLOCKED) and fresh-context-per-iteration design.

### Standalone Agents

PRD Creator (`jeeves/PRD/`) and Deepest-Thinking (`jeeves/Deepest-Thinking/`) operate outside the Ralph Loop. Each has OpenCode and Claude Code templates and a README.

## Contributing to Documentation

Project documentation lives in `docs/`:

| File | Content |
|------|---------|
| `guide.md` | Workflow guide: setup, Ralph phases, agent selection, tips |
| `reference.md` | Commands, flags, configuration, environment variables |
| `troubleshooting.md` | Common issues and solutions |

When updating documentation:

- Keep content factually accurate and consistent with the current codebase
- Do not duplicate content that belongs in `AGENTS.md` (code style) or `README.md` (project overview)
- Reference other docs rather than repeating information
- No emojis unless explicitly requested
- See the [Ralph documentation](jeeves/Ralph/docs/) for Ralph-specific docs

## Commit Message Convention

All commit messages and PR titles **must** follow the [Conventional Commits](https://www.conventionalcommits.org/) specification. PR titles are validated by GitHub Actions.

**Format:**

```
<type>[optional scope]: <description>
```

**Types:**

| Type | Meaning |
|------|---------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation changes |
| `style` | Formatting, no logic change |
| `refactor` | Code restructuring |
| `perf` | Performance improvement |
| `test` | Adding or updating tests |
| `chore` | Build process or tooling |
| `sec` | Security-related changes |
| `revert` | Reverting a previous commit |

**Scopes** (optional): `ps1`, `docker`, `docs`, `ci`, `deps`, `core`, `bin`, `ralph`, `agents`, `skills`

**Examples:**

```
feat(ralph): add retry backoff to loop script
fix(docker): resolve path escaping on Windows
docs: update troubleshooting guide
sec: fix privilege escalation in container setup
chore(deps): update CUDA base image
feat(agents): add decomposer-architect template
```

**Rules:**

- Subject line must not start with an uppercase letter
- No period at the end of the subject line
- Breaking changes: add `!` before the colon (e.g., `feat!: breaking change`)

## Pull Request Process

### Before Submitting

1. Test thoroughly (see [Manual Testing Checklist](#manual-testing-checklist))
2. Update documentation for any new features or changed behavior
3. Check for existing issues to avoid duplicate work
4. Keep PRs focused -- one feature or fix per PR when possible
5. Follow the commit message convention above

### PR Requirements

- At least 1 approval from a maintainer
- All status checks passing (including PR title linting)
- No merge conflicts
- All review conversations resolved

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Manual testing completed
- [ ] Cross-platform tested
- [ ] Automated tests pass (if applicable)

## Checklist
- [ ] Code follows AGENTS.md style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No duplicated code style content
```

### Review Process

1. **Automated checks** -- CI/CD pipeline validation and PR title linting
2. **Peer review** -- At least one maintainer review
3. **Testing validation** -- Manual verification of changes
4. **Approval** -- Maintainer approval required for merge

## Project Structure

See [README.md](README.md) for the full repository structure. Key directories for contributors:

```
jeeves/
├── jeeves.ps1                     # Host-side container management
├── Dockerfile.jeeves              # Multi-stage Docker build
├── jeeves/
│   ├── bin/                       # All scripts (15 total)
│   ├── PRD/                       # PRD Creator agent
│   ├── Deepest-Thinking/          # Research agent
│   └── Ralph/                     # Ralph Loop framework
│       ├── skills/                #   Pluggable skills
│       └── templates/
│           ├── agents/            #   11 agent types (OpenCode + Claude)
│           │   └── shared/        #   Shared rules (10 files)
│           ├── config/            #   Configuration templates
│           ├── prompts/           #   Prompt templates
│           └── task/              #   Task file templates
├── docs/                          # Project documentation (3 files)
├── AGENTS.md                      # Code style and agent guidelines
└── CONTRIBUTING.md                # This file
```

## License

Jeeves is licensed under the [GNU Affero General Public License v3.0](LICENSE) (AGPL-3.0). By submitting a contribution, you agree that your work will be licensed under the same terms. The AGPL-3.0 requires that any modified version of this software made available over a network must also make its source code available. Keep this in mind when contributing features that involve network-facing services.

## Community Guidelines

- Be respectful and inclusive
- Focus on constructive, actionable feedback
- Use [GitHub Issues](https://github.com/SamAcctX/jeeves/issues) for bugs and feature requests
- Use [GitHub Discussions](https://github.com/SamAcctX/jeeves/discussions) for general conversation
- Check the [troubleshooting guide](docs/troubleshooting.md) before asking for help

## Resources

- [Docker Documentation](https://docs.docker.com/)
- [PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/)
- [MCP Specification](https://modelcontextprotocol.io/)
- [Conventional Commits](https://www.conventionalcommits.org/)
