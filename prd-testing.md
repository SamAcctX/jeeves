# PRD Creator - Comprehensive Test Cases

This document provides a comprehensive set of test cases to verify that the PRD Creator implementation works correctly across all functionality areas.

---

## Test Environment Setup

### Prerequisites
1. Start from a clean Jeeves container
2. Verify OpenCode is not running initially
3. Ensure workspace is clean: `rm -rf /workspace/*`
4. Verify no existing configuration: `rm -rf ~/.config/opencode/*`

### Test Data Preparation
```bash
# Create a test workspace
cd /workspace
mkdir -p test-project
cd test-project
git init
```

---

## 1. Basic Script Functionality Tests

### 1.1 Help and Usage Commands

**Test Case: Basic Help Display**
```bash
# Test: prd-creator help
/workspace/jeeves/prd-creator.sh help

# Expected: Usage message with all commands and options displayed
# Verify: Shows init, install, save-prompt, show-readme, check-mcp commands
# Verify: Shows --global, --project, --skip-mcp options
```

**Test Case: Uninstall Help Display**
```bash
# Test: prd-creator-uninstall help
/workspace/jeeves/prd-creator-uninstall.sh help

# Expected: Usage message showing global, project, all commands
# Verify: Shows --dry-run, --force, --include-mcp options
```

### 1.2 Quick Start Commands

**Test Case: Init Command**
```bash
# Test: prd-creator init
/workspace/jeeves/prd-creator.sh init

# Expected: Quick start guide displayed
# Verify: Shows Method 1 (OpenCode Agent) and Method 2 (Direct Prompt Copy)
# Verify: Mentions MCP configuration option
```

**Test Case: Save Prompt Command**
```bash
# Test: prd-creator save-prompt
/workspace/jeeves/prd-creator.sh save-prompt

# Expected: Prompt file saved to workspace
# Verify: File exists at /workspace/test-project/prd-creator.md
# Verify: File content matches source prompt
# Test: File overwrite protection works when run again
```

---

## 2. Installation Tests

### 2.1 Global Installation Tests

**Test Case: Global Agent Installation with MCP**
```bash
# Test: prd-creator install (auto-detect global)
/workspace/jeeves/prd-creator.sh install

# Expected: Auto-detects global installation and installs agent
# Verify: Agent file exists at ~/.config/opencode/agent/prd-creator.md
# Verify: MCP configuration exists in ~/.config/opencode/opencode.json
# Verify: Backup file created: ~/.config/opencode/opencode.json.prd-backup-*
# Verify: Sequential Thinking server configured
# Verify: File System server configured with correct workspace path
# Verify: Success messages displayed
```

**Test Case: Global Agent Installation (Manual)**
```bash
# Test: prd-creator install --global
/workspace/jeeves/prd-creator.sh install --global

# Expected: Forces global installation
# Verify: Same results as auto-detect global test
# Verify: No project agent created
```

**Test Case: Global Installation with MCP Skip**
```bash
# Test: prd-creator install --global --skip-mcp
/workspace/jeeves/prd-creator.sh install --global --skip-mcp

# Expected: Global agent installed without MCP configuration
# Verify: Agent file installed
# Verify: No changes to opencode.json MCP section
# Verify: Message indicates MCP configuration skipped
```

### 2.2 Project Installation Tests

**Test Case: Project Agent Installation (Auto-Detect)**
```bash
# Test: prd-creator install in git repository
/workspace/jeeves/prd-creator.sh install

# Expected: Auto-detects project installation
# Verify: Agent file exists at /workspace/test-project/.opencode/agent/prd-creator.md
# Verify: MCP configuration exists in ~/.config/opencode/opencode.json
# Verify: File System MCP configured with /workspace/test-project path
# Verify: Project-specific success messages displayed
```

**Test Case: Project Agent Installation (Manual)**
```bash
# Test: prd-creator install --project
/workspace/jeeves/prd-creator.sh install --project

# Expected: Forces project installation
# Verify: Same results as auto-detect project test
# Verify: No global agent created
```

**Test Case: Installation Conflict Resolution**
```bash
# Test: prd-creator install --global --project
/workspace/jeeves/prd-creator.sh install --global --project

# Expected: Warning message and preference for project installation
# Verify: Only project agent created
# Verify: Warning about conflict displayed
```

### 2.3 MCP Configuration Verification

**Test Case: JSON Configuration Integrity**
```bash
# Verify: Check MCP configuration JSON validity
jq . ~/.config/opencode/opencode.json

# Expected: Valid JSON output
# Verify: mcpServers section exists
# Verify: sequential-thinking server configuration present
# Verify: filesystem server configuration present
# Verify: No JSON syntax errors
```

**Test Case: Backup Creation**
```bash
# Verify: Backup file created
ls -la ~/.config/opencode/opencode.json.prd-backup-*

# Expected: At least one backup file exists
# Verify: Backup timestamp format is correct (YYYYMMDD-HHMMSS)
# Verify: Backup contains original configuration
```

---

## 3. Uninstallation Tests

### 3.1 Agent Removal Tests

**Test Case: Remove Global Agent Only**
```bash
# Test: prd-creator-uninstall global
/workspace/jeeves/prd-creator-uninstall.sh global

# Expected: Remove only global agent
# Verify: Global agent file removed
# Verify: Project agent (if exists) remains
# Verify: MCP servers NOT removed (default behavior)
# Verify: Success message displayed
```

**Test Case: Remove Project Agent Only**
```bash
# Test: prd-creator-uninstall project
/workspace/jeeves/prd-creator-uninstall.sh project

# Expected: Remove only project agent
# Verify: Project agent file removed
# Verify: Global agent (if exists) remains
# Verify: MCP servers NOT removed (default behavior)
```

**Test Case: Remove All Agents**
```bash
# Test: prd-creator-uninstall all
/workspace/jeeves/prd-creator-uninstall.sh all

# Expected: Remove both global and project agents
# Verify: Global agent removed
# Verify: Project agent removed
# Verify: MCP servers NOT removed (default behavior)
# Verify: Note about MCP removal option displayed
```

### 3.2 MCP Deconfiguration Tests

**Test Case: Remove All with MCP Deconfiguration**
```bash
# Test: prd-creator-uninstall all --include-mcp
/workspace/jeeves/prd-creator-uninstall.sh all --include-mcp

# Expected: Remove agents and deconfigure MCP servers
# Verify: Both agent files removed
# Verify: Sequential Thinking removed from opencode.json
# Verify: File System removed from opencode.json
# Verify: Backup created before changes
# Verify: Warning about other agents potentially using MCP servers
```

### 3.3 Safety Features Tests

**Test Case: Dry Run Mode**
```bash
# Test: prd-creator-uninstall all --dry-run
/workspace/jeeves/prd-creator-uninstall.sh all --dry-run

# Expected: Show what would be removed without actually removing
# Verify: "Would remove" messages for agents
# Verify: Files still exist after command
# Verify: No actual deletions occur
```

**Test Case: Force Mode**
```bash
# Test: prd-creator-uninstall all --force --include-mcp
/workspace/jeeves/prd-creator-uninstall.sh all --force --include-mcp

# Expected: Remove without confirmation prompts
# Verify: No interactive prompts
# Verify: Direct removal occurs
# Verify: Success/failure messages still displayed
```

### 3.4 Error Handling Tests

**Test Case: Uninstall Non-existent Agent**
```bash
# Test: Uninstall when no agents exist
/workspace/jeeves/prd-creator-uninstall.sh all --include-mcp

# Expected: Graceful handling of missing agents
# Verify: "Not found" messages displayed
# Verify: No errors or crashes
# Verify: Appropriate completion status
```

---

## 4. MCP Functionality Tests

### 4.1 MCP Configuration Check Command

**Test Case: MCP Check Command**
```bash
# Test: prd-creator check-mcp
/workspace/jeeves/prd-creator.sh check-mcp

# Expected: Comprehensive MCP information displayed
# Verify: Shows all 5 recommended MCP servers
# Verify: Shows configuration examples for each
# Verify: Checks environment variables (BRAVE_API_KEY, TAVILY_API_KEY)
# Verify: Shows auto-configured status
# Verify: Provides manual installation commands
```

### 4.2 Environment Variable Tests

**Test Case: Environment Variable Detection**
```bash
# Set environment variables
export BRAVE_API_KEY="test-key-brave"
export TAVILY_API_KEY="test-key-tavily"

# Test detection
/workspace/jeeves/prd-creator.sh check-mcp

# Expected: Shows both API keys as set
# Verify: Success messages for both keys
# Clear variables and test unset state
unset BRAVE_API_KEY TAVILY_API_KEY
/workspace/jeeves/prd-creator.sh check-mcp

# Expected: Shows both keys as not set
# Verify: Instructions for setting both keys
```

---

## 5. Integration Tests (Actual Agent Usage)

### 5.1 Basic Agent Mode Test

**Setup for Integration Tests:**
```bash
# Install agent globally
/workspace/jeeves/prd-creator.sh install

# Start OpenCode (if not already running)
opencode web --hostname 0.0.0.0 --port 3333 &

# Give it time to load
sleep 10
```

**Test Case: Pong Game PRD Creation**
1. Access OpenCode Web UI at http://localhost:3333
2. Verify "PRD Creator" agent appears in agents menu
3. Select "PRD Creator" agent or use @prd-creator
4. Start conversation with simple request:
   ```
   I want to create a simple pong game for mobile devices. It should have a paddle that moves up and down, a ball that bounces, and basic scoring.
   ```

**Expected Agent Behavior:**
- Agent introduces itself and explains the process
- Asks about core features first (paddle movement, ball physics, scoring)
- Asks about target audience (mobile gamers, casual players)
- Asks about platform (mobile - iOS/Android)
- Asks about UI concepts (minimalist design, touch controls)
- Asks about data storage (high scores, settings)
- Asks about authentication (optional user profiles)
- Asks about third-party integrations (analytics, ads)
- Asks about scalability (leaderboards, multiplayer)
- Asks about technical challenges (performance on mobile)
- Asks about costs (development tools, app store fees)
- Asks about visual materials (mockups, wireframes)

**Expected PRD Output:**
- Complete PRD with all sections
- Technical stack recommendations (Unity/Unreal for mobile, etc.)
- Conceptual data model (Player scores, Settings)
- UI design principles (minimalist, touch-friendly)
- Security considerations (data protection, user privacy)
- Development phases (prototype, alpha, beta, release)
- Technical challenges and solutions
- Future expansion possibilities

**File System Test:**
- Verify agent automatically saves PRD to workspace
- Check for file: /workspace/test-project/PRD-PongGame-[DATE].md
- Verify file content is complete and well-formatted
- Verify file is accessible and readable

### 5.2 Sequential Thinking MCP Test

**Test Sequential Thinking Usage:**
1. During agent conversation, agent should use Sequential Thinking for complex analysis
2. Monitor agent logs or look for Sequential Thinking tool usage
3. Expected tool calls like:
   - "Let me think through this systematically using Sequential Thinking"
   - Analysis of technical requirements broken down step-by-step
   - Structured approach to development phases

**Verification:**
- Check if Sequential Thinking server automatically installs via npx
- Verify no manual configuration required
- Confirm tool works without errors

### 5.3 File System MCP Test

**Test File System Usage:**
1. Agent should save PRD using File System MCP
2. Expected behavior:
   - "I'll save this PRD to your filesystem for easy reference"
   - File created in project directory automatically
   - Proper filename format used

**Verification:**
- Check if File System server automatically installs via npx
- Verify workspace permissions allow file creation
- Confirm file appears in correct location

---

## 6. Error Handling and Edge Cases

### 6.1 Permission and File System Tests

**Test Case: Missing Prompt File**
```bash
# Simulate missing prompt file
sudo mv /opt/jeeves/prd-creator/prd-creator-prompt.md /opt/jeeves/prd-creator/backup.md

# Test: prd-creator install
/workspace/jeeves/prd-creator.sh install

# Expected: Graceful error handling
# Verify: Error message about missing prompt file
# Verify: Appropriate exit code
# Verify: No partial installation occurs
```

**Test Case: Read-only Configuration Directory**
```bash
# Make config directory read-only (simulate permission issue)
chmod 444 ~/.config/opencode/

# Test: prd-creator install
/workspace/jeeves/prd-creator.sh install

# Expected: Permission error handling
# Verify: Error message about configuration issues
# Verify: Clean failure without partial changes

# Cleanup
chmod 755 ~/.config/opencode/
```

### 6.2 JSON and Configuration Tests

**Test Case: Invalid JSON Configuration**
```bash
# Create invalid JSON in config
echo '{"invalid": json}' > ~/.config/opencode/opencode.json

# Test: prd-creator install
/workspace/jeeves/prd-creator.sh install

# Expected: Fallback to Python JSON handling
# Verify: Still configures MCP servers correctly
# Verify: Creates valid JSON output
# Verify: Warning about jq not found (if applicable)
```

### 6.3 Dependency Tests

**Test Case: Missing jq Command**
```bash
# Temporarily remove jq (if present)
sudo mv $(which jq) $(dirname $(which jq))/jq.backup 2>/dev/null || true

# Test: prd-creator install
/workspace/jeeves/prd-creator.sh install

# Expected: Python fallback works
# Verify: "jq not found, using basic JSON manipulation" message
# Verify: MCP configuration still succeeds
# Verify: Uses Python3 for JSON manipulation

# Restore jq
sudo mv $(dirname $(which jq))/jq.backup $(which jq) 2>/dev/null || true
```

**Test Case: Missing Python3**
```bash
# Temporarily remove python3 (NOT RECOMMENDED FOR REAL USE)
# This test requires careful restoration - may skip if risky

# Expected: Error message about missing JSON manipulation tools
# Verify: Clear error about needing jq or python3
# Verify: Installation fails gracefully
```

---

## 7. Performance and Stress Tests

### 7.1 Multiple Installations

**Test Case: Consecutive Installations**
```bash
# Install global, then project, then global again
/workspace/jeeves/prd-creator.sh install --global
/workspace/jeeves/prd-creator.sh install --project
/workspace/jeeves/prd-creator.sh install --global

# Expected: Each installation works correctly
# Verify: No conflicts between installations
# Verify: Appropriate directories updated
# Verify: MCP configuration maintained correctly
```

### 7.2 Large Workspace Tests

**Test Case: Deep Workspace Path**
```bash
# Create deeply nested workspace
mkdir -p /workspace/very/deep/workspace/path/test-project
cd /workspace/very/deep/workspace/path/test-project
git init

# Test: prd-creator install --project
/workspace/jeeves/prd-creator.sh install --project

# Expected: Installation works with deep paths
# Verify: File System MCP configured with full path
# Verify: Agent file created in correct location
```

---

## 8. Cleanup and Reset Tests

### 8.1 Complete Environment Reset

**Test Case: Full Uninstall and Reinstall**
```bash
# Complete uninstall with MCP removal
/workspace/jeeves/prd-creator-uninstall.sh all --include-mcp

# Verify: All traces removed
# Verify: No agent files remain
# Verify: No PRD Creator MCP entries in configuration

# Reinstall
/workspace/jeeves/prd-creator.sh install --global

# Expected: Fresh installation works
# Verify: All functionality restored
# Verify: No conflicts from previous installation
```

---

## 9. Documentation and Help Accuracy Tests

### 9.1 Help Message Accuracy

**Test Case: Help Documentation Verification**
```bash
# Capture help output
/workspace/jeeves/prd-creator.sh help > /tmp/prd-help.txt
/workspace/jeeves/prd-creator-uninstall.sh help > /tmp/prd-uninstall-help.txt

# Expected: Accurate documentation
# Verify: All commands documented
# Verify: All options explained
# Verify: Examples are correct
# Verify: No undocumented features mentioned
```

---

## 10. Test Results Documentation

### Expected Outcomes Summary

1. **Success Indicators:**
   - All help commands display correctly
   - Both global and project installations work
   - MCP configuration automatically applied
   - Agent appears in OpenCode UI
   - Agent creates proper PRD output
   - MCP servers install via npx on first use
   - File System MCP saves files to workspace
   - Sequential Thinking MCP assists with complex analysis

2. **Error Handling Indicators:**
   - Graceful handling of missing files
   - Appropriate fallbacks (jq → Python)
   - Clear error messages for permission issues
   - Safe handling of invalid JSON
   - Backup creation before modifications

3. **Integration Success Indicators:**
   - Pong game PRD created successfully
   - All expected sections present in output
   - Technical recommendations appropriate for mobile game
   - File automatically saved with proper naming
   - No manual intervention required

---

## Test Execution Notes

### Running Tests Sequentially

1. **Environment Isolation:** Run each test category in a fresh container or after cleanup
2. **Backup Original State:** Document initial state before each major test
3. **Verify Artifacts:** Check files, directories, and configurations after each test
4. **Log Output:** Capture command output for analysis
5. **Test Coverage:** Ensure each requirement is tested by multiple test cases

### Test Automation (Optional)

For automated testing, consider wrapping test cases in a script that:
- Sets up test environment
- Runs each test case
- Captures exit codes and output
- Verifies expected file/directory states
- Generates test report with pass/fail status

---

## Testing Checklist

### Pre-Test Checklist
- [ ] Clean container environment
- [ ] Verify script permissions
- [ ] Verify required dependencies (jq, python3)
- [ ] Backup any existing configurations

### Post-Test Checklist
- [ ] All help commands work
- [ ] Global installation successful
- [ ] Project installation successful
- [ ] MCP configuration applied correctly
- [ ] Agent appears in OpenCode UI
- [ ] PRD creation works for test case
- [ ] File System MCP saves files
- [ ] Sequential Thinking MCP functions
- [ ] Uninstall removes all components
- [ ] Error handling works correctly
- [ ] Documentation matches implementation

### Success Criteria
- **Pass:** All test cases execute without errors
- **Pass:** Agent mode creates complete PRD for pong game
- **Pass:** MCP servers configure and function automatically
- **Pass:** Install/uninstall cycles work repeatedly
- **Pass:** Edge cases handled gracefully

This comprehensive test suite ensures the PRD Creator implementation meets all requirements and functions correctly in real-world usage scenarios.