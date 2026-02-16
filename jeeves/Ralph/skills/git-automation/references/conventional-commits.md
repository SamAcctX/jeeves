# Conventional Commits Guide

This guide explains the conventional commit format used by the Ralph Loop Git Automation skill for generating consistent, semantic commit messages.

---

## Overview

Conventional Commits is a specification for adding human and machine-readable meaning to commit messages. The format provides:

- **Automated versioning** (semver)
- **Automatic changelog generation**
- **Clear communication** of changes to team members
- **Easy navigation** through git history

---

## Format Specification

### Basic Format

```
<type>: <subject>
```

### With Optional Scope

```
<type>(<scope>): <subject>
```

### With Body and Footer

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Components

| Component | Description | Required |
|-----------|-------------|----------|
| `type` | Category of change | ✓ Yes |
| `scope` | Area of codebase affected | ✗ No |
| `subject` | Short description of change | ✓ Yes |
| `body` | Detailed explanation | ✗ No |
| `footer` | Metadata (breaking changes, refs) | ✗ No |

---

## Commit Types

### feat

**When to use:** New feature or functionality

**Semantic Versioning Impact:** MINOR version bump (1.0.0 → 1.1.0)

**Examples:**

```bash
feat: add user authentication
feat(api): implement rate limiting
feat(auth): add OAuth2 login support
feat(ui): redesign dashboard layout
```

**Agent Mapping:**

| Agent Type | Default Type |
|------------|--------------|
| Developer | feat |
| Architect | feat |
| UI-Designer | feat |

---

### fix

**When to use:** Bug fix or error correction

**Semantic Versioning Impact:** PATCH version bump (1.0.0 → 1.0.1)

**Examples:**

```bash
fix: resolve null pointer exception
fix(api): correct response status code
fix(auth): handle expired tokens properly
fix(ui): fix button alignment on mobile
```

**Override Keywords:**

Task titles containing these words trigger `fix` type:
- fix
- bug
- error
- crash

**Examples with override:**

```bash
# Task title: "Fix authentication bug"
# Result: fix: fix authentication bug

# Task title: "Resolve null pointer error"
# Result: fix: resolve null pointer error

# Task title: "Fix crash on startup"
# Result: fix: fix crash on startup
```

---

### docs

**When to use:** Documentation changes only

**Semantic Versioning Impact:** None (documentation updates)

**Examples:**

```bash
docs: update README with setup instructions
docs(api): document authentication endpoints
docs: fix typos in contribution guide
docs: add examples to API reference
```

**Agent Mapping:**

| Agent Type | Default Type |
|------------|--------------|
| Writer | docs |
| Researcher | docs |

**Override Keywords:**

Task titles containing these words trigger `docs` type:
- doc
- documentation

**Examples with override:**

```bash
# Task title: "Document API endpoints"
# Result: docs: document api endpoints

# Task title: "Update documentation"
# Result: docs: update documentation
```

---

### test

**When to use:** Adding or correcting tests

**Semantic Versioning Impact:** None (test updates)

**Examples:**

```bash
test: add unit tests for user service
test(auth): implement integration tests
test: fix failing test cases
test(api): add edge case coverage
```

**Agent Mapping:**

| Agent Type | Default Type |
|------------|--------------|
| Tester | test |

**Override Keywords:**

Task titles containing "test" trigger `test` type for all agent types.

---

### refactor

**When to use:** Code changes that neither fix bugs nor add features

**Semantic Versioning Impact:** None (internal restructuring)

**Examples:**

```bash
refactor: simplify authentication logic
refactor(api): extract validation middleware
refactor: reorganize project structure
refactor(db): optimize query performance
```

**Override Keywords:**

Task titles containing "refactor" trigger `refactor` type.

---

### chore

**When to use:** Maintenance tasks, dependencies, build process

**Semantic Versioning Impact:** None (maintenance)

**Examples:**

```bash
chore: update dependencies
chore(build): configure webpack optimization
chore(ci): update GitHub Actions workflow
chore: bump version to 1.2.0
```

**Agent Mapping:**

| Agent Type | Default Type |
|------------|--------------|
| Unknown | chore |

---

## Breaking Changes

### Notation

Breaking changes are indicated with `!` after the type/scope:

```bash
feat!: remove deprecated API endpoints
feat(api)!: change response format
fix!: drop support for Node 12
```

### Footer Format

Alternative notation using footer:

```bash
feat: change authentication method

BREAKING CHANGE: authentication now requires API key header
```

**Semantic Versioning Impact:** MAJOR version bump (1.0.0 → 2.0.0)

### Script Usage

```bash
# Generate breaking change commit
/proj/.ralph/skills/git-automation/scripts/git-commit-msg.sh \
    --task-id 0042 \
    --agent-type developer \
    --task-title "Remove deprecated endpoints" \
    --breaking

# Output: feat!: remove deprecated endpoints
```

---

## Subject Line Best Practices

### Length Guidelines

| Aspect | Recommendation |
|--------|----------------|
| Ideal length | 50 characters or less |
| Maximum length | 72 characters |
| Hard limit | Truncated at 72 with "..." |

### Style Rules

✅ **DO:**

- Use imperative mood ("Add" not "Added" or "Adds")
- Use lowercase after the type prefix
- Be specific and descriptive
- Reference issue numbers when applicable

❌ **DON'T:**

- End with a period
- Use past tense
- Write generic messages like "fix bug" or "update code"
- Include type prefix manually (script handles this)

### Examples

✅ **Good:**

```bash
feat: add user authentication
fix: resolve race condition in cache
docs: document API rate limiting
test: add edge case coverage for parser
```

❌ **Bad:**

```bash
feat: Added user authentication.       # Past tense, has period
fix: bug                               # Too vague
docs: Update                           # Incomplete
test: Tests for parser                 # Not imperative
```

### Imperative Mood Examples

| ❌ Don't Use | ✅ Use Instead |
|--------------|----------------|
| Added | Add |
| Fixed | Fix |
| Updated | Update |
| Changed | Change |
| Removed | Remove |
| Implemented | Implement |
| Refactored | Refactor |

---

## Agent Type to Commit Type Mapping

### Default Mapping Table

| Agent Type | Default Commit Type | Use Case |
|------------|---------------------|----------|
| Developer | feat | Feature implementation |
| Architect | feat | Design and architecture |
| Tester | test | Test implementation |
| Writer | docs | Documentation |
| Researcher | docs | Research documentation |
| UI-Designer | feat | UI/UX implementation |
| Unknown | chore | General maintenance |

### Override Rules

Override keywords take precedence over agent type defaults:

1. **fix keywords:** fix, bug, error, crash
2. **refactor keyword:** refactor
3. **test keyword:** test
4. **docs keywords:** doc, documentation

### Example Mapping Scenarios

**Scenario 1: Developer + Feature**

```bash
# Task title: "Implement user authentication"
# Agent: developer
# Result: feat: implement user authentication
```

**Scenario 2: Developer + Bug Fix**

```bash
# Task title: "Fix authentication bug"
# Agent: developer (override: fix keyword)
# Result: fix: fix authentication bug
```

**Scenario 3: Tester + Documentation**

```bash
# Task title: "Document test strategy"
# Agent: tester (override: docs keyword)
# Result: docs: document test strategy
```

**Scenario 4: Writer + Breaking Change**

```bash
# Task title: "Restructure API documentation"
# Agent: writer + --breaking flag
# Result: docs!: restructure api documentation
```

---

## Full Commit Message Examples

### Minimal (Type + Subject)

```bash
feat: add dark mode support
```

### With Scope

```bash
feat(ui): add dark mode toggle
```

### With Body

```bash
feat: add dark mode support

Implement theme switching with system preference detection.
Store user preference in localStorage for persistence.
```

### With Footer

```bash
feat: add dark mode support

Implement theme switching with system preference detection.

Closes #123
```

### Breaking Change

```bash
feat(api)!: change authentication method

BREAKING CHANGE: JWT tokens now require 'Bearer ' prefix.
Update all API clients to include the prefix.
```

### Complete Example

```bash
feat(auth): implement OAuth2 login

Add support for Google and GitHub OAuth2 providers.
Includes automatic account linking for existing users.

- Add OAuth2 client configuration
- Implement callback handlers
- Create account linking UI
- Add provider selection screen

Closes #456
Relates to #789
```

---

## Generating Commit Messages

### Basic Usage

```bash
# Generate commit message
COMMIT_MSG=$(/proj/.ralph/skills/git-automation/scripts/git-commit-msg.sh \
    --task-id 0042 \
    --agent-type developer \
    --task-title "Implement user authentication")

echo "$COMMIT_MSG"
# Output: feat: implement user authentication
```

### With Breaking Change

```bash
COMMIT_MSG=$(/proj/.ralph/skills/git-automation/scripts/git-commit-msg.sh \
    --task-id 0042 \
    --agent-type developer \
    --task-title "Remove deprecated endpoints" \
    --breaking)

echo "$COMMIT_MSG"
# Output: feat!: remove deprecated endpoints
```

### Committing with Generated Message

```bash
# Generate message
COMMIT_MSG=$(/proj/.ralph/skills/git-automation/scripts/git-commit-msg.sh \
    --task-id 0042 \
    --agent-type developer \
    --task-title "Add user authentication")

# Stage and commit
git add .
git commit -m "$COMMIT_MSG"
```

---

## Validation Checklist

Before committing, verify:

- [ ] Type is appropriate for the change
- [ ] Subject is in imperative mood
- [ ] Subject is 50 characters or less
- [ ] Subject does not end with period
- [ ] Subject uses lowercase after type prefix
- [ ] Breaking changes marked with `!` or `BREAKING CHANGE:` footer
- [ ] Body explains what and why (not how)
- [ ] References to issues/PRs in footer

---

## Related Documentation

- [Git Workflow User Guide](git-workflow-user.md)
- [Git Commands Reference](git-commands.md)
- [Troubleshooting Guide](troubleshooting.md)
- [Conventional Commits Specification](https://www.conventionalcommits.org/)
