---
name: system-prompt-compliance
description: Cross-agent compliance reminders. Agent-specific prompts take precedence over these generic fallbacks.
license: MIT
metadata:
  version: "3.0.0"
  author: Ralph Loop Team
---

# System Prompt Compliance — Minimal Cross-Agent Reminders

**Your agent prompt is authoritative.** These are fallback reminders only. Invoke once per session; apply from memory thereafter.

## 1. TODO TRACKING
Use todoread/todowrite to track progress. Initialize at task start; update at each milestone; verify before signal emission. Starting work without a TODO list or emitting a signal with unaddressed items is a compliance violation.

## 2. ACTIVITY LOGGING (Worker Agents)
Update activity.md at regular intervals (~every 15-20 tool calls), not just at the end. Include: what's done, what's in progress, what's next, and any issues. Long sessions with no activity.md updates create blind spots — mid-process logging creates recovery points.

## 3. SIGNAL & COMPLIANCE
Your agent prompt defines your signal validator regex, compliance checkpoints, and periodic reinforcement schedule. Follow those — they are stricter and more specific than any generic rule.

## 4. RATIONALIZATION DEFENSE
Load the `rationalization-defense` skill before emitting TASK_COMPLETE. Run its 11-question Self-Diagnostic Protocol.
