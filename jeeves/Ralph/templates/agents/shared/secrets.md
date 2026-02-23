# Secrets Protection Rules (DUP-02)

**Priority**: P0 (Must-never-break)  
**Scope**: Universal (all agents)  
**Location**: `jeeves/Ralph/templates/agents/shared/secrets.md`  
**Canonical ID**: SEC-01

---

## SEC-P0-01: Never Write Secrets to Repository Files (MANDATORY)

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
3. **Document in activity.md** (without exposing the secret value)
4. **Signal TASK_BLOCKED** if uncertain how to proceed

**Never ignore exposed secrets** - they remain in git history forever unless properly cleaned.

</rule>

---

## Compliance Checkpoint

<checkpoint id="SEC-CP-01" trigger="pre-write">
<required_checks>
- [ ] SEC-P0-01: Content does not contain secrets
- [ ] SEC-P0-01: No API keys, passwords, or tokens  
- [ ] SEC-P0-01: No private keys or connection strings
- [ ] SEC-P1-01: If exposed, rotate immediately
</required_checks>
</checkpoint>

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

## Using This Rule File

<todo_guidance>

### At Start of Turn
- Review which files will be modified in this turn
- Check if any file paths match forbidden paths (SEC-P0-01)
- Identify if task involves credentials, API keys, or configuration

### Before Tool Calls
**Verify P1 workflow gates:**
- [ ] Will this write operation potentially include secrets?
- [ ] Is this a file-write operation to a committed path?
- [ ] Does the content match any secret detection patterns?

**If writing to any file:**
- Run secrets detection on content before write
- Verify no API keys, tokens, or credentials present

### Before Response
**Run compliance checkpoint:**
- [ ] SEC-P0-01: Confirm no secrets written this turn
- [ ] SEC-P1-01: If secret detected during turn, ensure protocol applied
- [ ] Document any exposure incidents in activity.md

### TODO Items for Secrets Detection

<todoreference>
- **SEC-P0-01-CHECK**: Before any write, scan content for secret patterns
- **SEC-P1-01-RESPONSE**: If secret detected, invoke SEC-P1-01 protocol
- **SEC-P0-01-VERIFY**: Confirm environment variable usage over hardcoded secrets
- **SEC-P0-01-AUDIT**: Review any new .env additions are gitignored
</todoreference>

</todo_guidance>

---

## Related Rules

- **SIG-P0-03**: Signal types (see: signals.md)
- **ACT-P1-12**: Activity.md updates (see: activity-format.md)
