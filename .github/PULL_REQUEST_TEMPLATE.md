## Description

<!-- Provide a brief description of the changes -->

## Type of Change

<!-- Check all that apply -->
- [ ] feat: New feature
- [ ] fix: Bug fix
- [ ] docs: Documentation only changes
- [ ] style: Code style changes (formatting, semicolons, etc.)
- [ ] refactor: Code refactoring
- [ ] perf: Performance improvements
- [ ] test: Adding or updating tests
- [ ] chore: Build process or auxiliary tool changes
- [ ] sec: Security-related changes
- [ ] revert: Revert to a previous commit

## PR Title Convention

**PR titles must follow the Conventional Commits specification:**

```
<type>[optional scope]: <description>
```

**Types:**
- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation changes
- `style:` - Code style/formatting
- `refactor:` - Code refactoring
- `perf:` - Performance improvements
- `test:` - Test-related changes
- `chore:` - Build/config/tooling changes
- `sec:` - Security fixes
- `revert:` - Reverting changes

**Examples:**
- `feat: add container restart command`
- `fix: resolve PowerShell path escaping issue`
- `docs: update installation instructions`
- `sec: fix privilege escalation vulnerability`
- `chore: update Docker base image`

## Testing

<!-- Describe the testing you've done -->
- [ ] Tested locally
- [ ] Tested on [Windows/macOS/Linux]
- [ ] Verified with clean build (`./jeeves.ps1 build --no-cache`)
- [ ] Tested lifecycle commands (start, stop, restart, shell)

## Checklist

- [ ] PR title follows conventional commits format (see above)
- [ ] Code follows the project's style guidelines (see AGENTS.md)
- [ ] Self-review completed
- [ ] Comments added for complex logic (only if requested)
- [ ] Documentation updated (if needed)
- [ ] No secrets or credentials committed
- [ ] Cross-platform compatibility considered

## Related Issues

<!-- Link to related issues using #123 -->
Fixes #
Closes #
Related to #

## Screenshots/Logs

<!-- If applicable, add screenshots or logs -->

## Breaking Changes

<!-- List any breaking changes and migration steps -->
**BREAKING CHANGE:**
