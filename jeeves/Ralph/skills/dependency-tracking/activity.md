## Attempt 1 [2026-02-13]
Iteration: 1
Tried: Running tests, manual testing, analyzing code
Coverage: N/A
Tests Passed: 0/15
Issues Found: 6 test failures

### Root Cause Analysis
**The script is failing because YAML numeric keys are being parsed without leading zeros.**

When the script queries yq with task ID "0001", it expects to find a key named "0001" in the parsed YAML, but yq converts numeric keys to plain numbers (1 instead of 0001).

### Specific Issues

**Issue 1: Task Not Found Errors**
- Test: `test_add_dependency_new_relationship`
- Error: "Task not found: 0001"
- Cause: yq returns null because key "0001" doesn't exist (key is "1")

**Issue 2: Dependencies Not Added**
- Test: `test_add_dependency_new_relationship`
- Expected: depends_on contains "0006"
- Actual: empty
- Cause: yq commands fail silently due to task not found

**Issue 3: Blocks Not Updated**
- Test: `test_add_dependency_new_relationship`
- Expected: blocks contains "0001"
- Actual: empty
- Cause: yq commands fail silently

**Issue 4: Duplicate Dependencies Not Detected**
- Test: `test_add_dependency_existing_no_duplicate`
- Expected: depends_on contains "0001" only once
- Actual: contains "0001 0002"
- Cause: Task IDs are being duplicated (1 and 2 instead of 0001 and 0002)

**Issue 5: Exit Codes Not Set**
- Tests: `test_add_dependency_invalid_format`, `test_add_dependency_task_not_found`
- Expected: Exit codes 4 and 5 respectively
- Actual: Exit code 0 (success)
- Cause: Script doesn't return proper exit codes for error cases

### Code Path Analysis

1. Test creates YAML with numeric keys: `0001`, `0002`, etc.
2. deps-parse.sh sources and sets DEPS_FILE
3. deps-update.sh sources deps-parse.sh
4. deps_add_dependency calls yq with task ID as string
5. yq converts YAML to JSON, removing leading zeros from keys
6. yq query `.tasks."0001"` returns null (no key "0001")
7. Script incorrectly reports "Task not found"
8. yq commands fail, no updates made

### Fix Requirements

**Option 1: Store task IDs without leading zeros**
- Modify deps-tracker.yaml to use numeric keys (1, 2, 3...)
- Pros: Simple change
- Cons: Breaks existing files, inconsistent with TODO.md numbering

**Option 2: Update script to query numeric keys**
- Modify deps-update.sh and deps-parse.sh to convert task IDs to numbers
- Pros: Works with current file format
- Cons: Complex, conversion issues

**Option 3: Use yq with --yaml-roundtrip**
- Try to preserve key format during parsing
- Pros: Keeps original format
- Cons: May not work with yq 0.0.0

**Option 4: Use different data structure**
- Store tasks in array instead of object
- Pros: No key conversion issues
- Cons: Major refactor, breaks existing functionality

### Recommendation
**Option 1 with migration script** - Modify the script to store task IDs without leading zeros, and provide a migration utility to update existing deps-tracker.yaml files.

### Acceptance Criteria Verification
- [ ] FAIL: deps_add_dependency adds to depends_on
- [ ] FAIL: deps_add_dependency updates blocks bidirectionally
- [ ] FAIL: depends_on contains 0001 only once
- [ ] FAIL: deps_add_dependency adds from_task's depends_on
- [ ] FAIL: deps_add_dependency adds from_task to to_task's blocks
- [ ] FAIL: deps_add_dependency rejects invalid task ID format
- [ ] FAIL: deps_add_dependency handles non-existent task gracefully
- [x] PASS: deps_add_dependency returns empty on success

### Coverage Gap Analysis
None - tests are failing due to implementation issues, not coverage gaps
