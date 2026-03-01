#!/bin/bash

export OPENCODE_PERMISSION='{"*":"allow","question":"deny"}'

MANAGER_OUTPUT=$(mktemp)

opencode run --agent manager "hello" | tee "$MANAGER_OUTPUT"

OUTPUT=$(cat "$MANAGER_OUTPUT")

LAST_RESPONSE=$(echo "$OUTPUT" | awk 'BEGIN{RS=""; ORS="\n\n"} {last=$0} END{print last}')

echo "---"
echo "FULL OUTPUT (stdout only):"
echo "---"
echo "$OUTPUT"
echo ""
echo "---"
echo "LAST RESPONSE ONLY:"
echo "---"
echo "$LAST_RESPONSE"

rm "$MANAGER_OUTPUT"
