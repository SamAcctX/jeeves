# Secrets Protection Rules (DUP-02)

<!-- version: 1.2.0 | last_updated: 2026-02-25 | canonical: YES -->

**Priority**: P0 (Must-never-break)
**Scope**: Universal (all agents)
**Location**: `jeeves/Ralph/templates/agents/shared/secrets.md`
**Canonical ID**: SEC-01

---

## Rule Precedence (Tie-break order)

1. P0 Safety & forbidden actions  ← SEC-P0-01 lives here
2. P0 Output format & validators
3. P1 Workflow/state-machine steps
4. P2/P3 Style guidance

If any lower-priority rule conflicts with a higher-priority rule, the lower-priority rule is dropped.

---

## SEC-P0-01: Never Write Secrets to Repository Files (MANDATORY — DO NOT REFERENCE ELSEWHERE)

<rule priority="P0" id="SEC-P0-01" enforce="pre-write">
<forbidden>
<item>Writing secrets to any repository file under any circumstances</item>
<item>Including secrets in log files, activity.md, attempts.md, TODO.md</item>
<item>Committing secrets in commit messages or documentation</item>
</forbidden>

### What Constitutes Secrets

- API keys and tokens (OpenAI, AWS, GitHub, Anthropic, etc.)
- Passwords and credentials
- Private keys (SSH, TLS, JWT signing keys)
- Database connection strings with passwords
- OAuth client secrets
- Encryption keys
- Session tokens
- Any high-entropy secret values

### Where Secrets Must NOT Be Written

<validator type="forbidden-paths">
- Source code files (.js, .py, .ts, .go, .java, etc.)
- Configuration files (.yaml, .yml, .json, .toml, .env)
- Log files (activity.md, attempts.md, TODO.md)
- Commit messages
- Documentation (README, guides, PRDs)
- Any project artifacts under version control
</validator>

</rule>

---

## Approved Methods for Secrets Handling

<allowed_methods>
<method name="environment-variables">
  <description>Use environment variables for runtime secrets</description>
  <examples>
    - `process.env.API_KEY`
    - `os.environ['API_KEY']`
  </examples>
</method>
<method name="secret-management">
  <description>Use dedicated secret management services</description>
  <examples>
    - AWS Secrets Manager
    - HashiCorp Vault
    - Azure Key Vault
  </examples>
</method>
<method name="env-files">
  <description>Use .env files listed in .gitignore</description>
  <constraint>Must never be committed to version control</constraint>
</method>
<method name="docker-secrets">
  <description>Use Docker Secrets for containerized environments</description>
</method>
<method name="cicd-variables">
  <description>Use CI/CD environment variables for build/deployment</description>
</method>
</allowed_methods>

---

## SEC-P1-01: Secret Exposure Response Protocol

<rule priority="P1" id="SEC-P1-01" enforce="on-detection">
<trigger when="secret-detected">
<action>STOP</action>
<required>Apply exposure response protocol immediately</required>
</trigger>

**If secrets are accidentally exposed:**

1. **Immediately rotate the secret** (revoke and regenerate at source)
2. **Remove from repository** using git filter-branch or BFG Repo-Cleaner
3. **Document in activity.md** (without exposing the secret value — describe incident only)
4. **Signal TASK_BLOCKED** if uncertain how to proceed:
   ```
   TASK_BLOCKED_XXXX:Secret_exposure_detected_rotation_required
   ```

**Never ignore exposed secrets** — they remain in git history forever unless properly cleaned.

**Edge Case — Uncertain if value is a secret**: If content looks like it might be a secret (high-entropy string, key-like format) but you're unsure, treat it AS a secret. Apply SEC-P0-01 (do not write it) and signal TASK_BLOCKED for human review. False positives are acceptable; false negatives are P0 violations.

</rule>

---

## Secret Detection Patterns

<detection_patterns>
<pattern type="api-key">
  <regex>['"]sk-[a-zA-Z0-9]{48}['"]</regex>
  <name>OpenAI API Key</name>
</pattern>
<pattern type="api-key">
  <regex>['"]AKIA[0-9A-Z]{16}['"]</regex>
  <name>AWS Access Key</name>
</pattern>
<pattern type="api-key">
  <regex>['"]ghp_[a-zA-Z0-9]{36}['"]</regex>
  <name>GitHub Personal Token</name>
</pattern>
<pattern type="private-key">
  <regex>-----BEGIN (RSA |DSA |EC |OPENSSH )?PRIVATE KEY-----</regex>
  <name>Private Key</name>
</pattern>
<pattern type="connection-string">
  <regex>mongodb(\+srv)?://[^:]+:[^@]+@</regex>
  <name>MongoDB with password</name>
</pattern>
<pattern type="connection-string">
  <regex>postgres://[^:]+:[^@]+@</regex>
  <name>PostgreSQL with password</name>
</pattern>
<pattern type="token">
  <regex>eyJ[a-zA-Z0-9_-]*\.eyJ[a-zA-Z0-9_-]*\.[a-zA-Z0-9_-]*</regex>
  <name>JWT Token</name>
</pattern>

<action trigger="detection">
STOP and apply SEC-P1-01 protocol immediately
</action>
</detection_patterns>

---

## Compliance Checkpoint (SEC-CP-01)

**Invoke at**: pre-write (MANDATORY before any file write operation)

<checkpoint id="SEC-CP-01" trigger="pre-write">
- [ ] SEC-P0-01: Content does not contain secrets (no API keys, passwords, tokens)
- [ ] SEC-P0-01: No private keys or connection strings with credentials
- [ ] SEC-P0-01: File being written is not a committed path containing sensitive data
- [ ] Detection patterns: Scanned content against known secret regex patterns
- [ ] SEC-P1-01: If secret detected during scan — STOP and apply exposure protocol
</checkpoint>

**[P0 REINFORCEMENT — verify before EVERY write operation]**
```
SEC-P0-01: Does the content I am about to write contain any secret?
Types: API keys, passwords, tokens, private keys, connection strings
If YES → STOP, do not write, apply SEC-P1-01 protocol
```

---

## Using This Rule File

### At Start of Turn

- [ ] Review which files will be modified in this turn
- [ ] Check if any file paths match forbidden paths (SEC-P0-01)
- [ ] Identify if task involves credentials, API keys, or configuration

### Before Tool Calls (file writes)

- [ ] Will this write operation potentially include secrets?
- [ ] Is this a file-write operation to a committed path?
- [ ] Scan content against secret detection patterns above
- [ ] Run SEC-CP-01 checkpoint (all 5 items)

### Before Response

- [ ] SEC-P0-01: Confirm no secrets written this turn
- [ ] SEC-P1-01: If secret detected during turn, confirm protocol applied
- [ ] Document any exposure incidents in activity.md (incident description only — no secret values)

### TODO Items for Secrets Detection

```
- [ ] SEC-P0-01-CHECK: Before any write, scan content for secret patterns
- [ ] SEC-P1-01-RESPONSE: If secret detected, invoke SEC-P1-01 protocol
- [ ] SEC-P0-01-VERIFY: Confirm environment variable usage over hardcoded secrets
- [ ] SEC-P0-01-AUDIT: Review any new .env additions are gitignored
```

---

## Related Rules

- **SIG-P0-03**: Signal types (see: signals.md)
- **ACT-P1-12**: Activity.md updates (see: activity-format.md)
