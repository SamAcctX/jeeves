#!/bin/bash

export OPENCODE_PERMISSION='{"*":"allow","question":"deny"}'

# Create output directory with timestamped filename
OUTPUT_DIR="/proj/cli-tests"
mkdir -p "$OUTPUT_DIR"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT_FILE="$OUTPUT_DIR/opencode-run-$TIMESTAMP.txt"

# Run and save output directly to file
opencode run --agent manager "Hello there.  Immediately say 'hi' to me, then proceed with your skill loading, then respond with any task status you like with a note (made up) that complies with your status format rules" > "$OUTPUT_FILE"

# Read the saved output
OUTPUT=$(cat "$OUTPUT_FILE")

# Match all signal types (COMPLETE, INCOMPLETE, FAILED, BLOCKED)
FIRST_SIGNAL_LINE=$(echo "$OUTPUT" | grep -E "TASK_(COMPLETE|INCOMPLETE|FAILED|BLOCKED)_[0-9]{4}" | head -1)
ALL_SIGNALS=$(echo "$OUTPUT" | grep -E "TASK_(COMPLETE|INCOMPLETE|FAILED|BLOCKED)_[0-9]{4}")
SIGNAL_COUNT=$(echo "$ALL_SIGNALS" | grep -c "TASK_" 2>/dev/null || echo "0")

echo "---"
echo "Output saved to: $OUTPUT_FILE"
echo "---"
echo ""
echo "---"
echo "FULL OUTPUT:"
echo "---"
echo "$OUTPUT"
echo ""
echo "---"
echo "FIRST SIGNAL LINE: [$FIRST_SIGNAL_LINE]"
echo "---"
echo ""
echo "---"
echo "ALL SIGNALS (count: $SIGNAL_COUNT):"
echo "---"
echo "$ALL_SIGNALS"
