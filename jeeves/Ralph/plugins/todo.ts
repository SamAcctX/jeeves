import { z } from "zod"
import fs from "node:fs"
import path from "node:path"

// ---------------------------------------------------------------------------
// Storage — session-scoped JSON files in /tmp/opencode-todos/
// ---------------------------------------------------------------------------

interface TodoItem {
  content: string
  status: string
  priority: string
}

const TODO_DIR = path.join("/tmp", "opencode-todos")

function ensureDir() {
  if (!fs.existsSync(TODO_DIR)) {
    fs.mkdirSync(TODO_DIR, { recursive: true })
  }
}

function todoPath(sessionID: string): string {
  const safe = sessionID.replace(/[^a-zA-Z0-9_-]/g, "_")
  return path.join(TODO_DIR, `${safe}.json`)
}

function getTodos(sessionID: string): TodoItem[] {
  ensureDir()
  const fp = todoPath(sessionID)
  if (!fs.existsSync(fp)) return []
  try {
    return JSON.parse(fs.readFileSync(fp, "utf-8")) as TodoItem[]
  } catch {
    return []
  }
}

function setTodos(sessionID: string, todos: TodoItem[]): void {
  ensureDir()
  fs.writeFileSync(todoPath(sessionID), JSON.stringify(todos, null, 2), "utf-8")
}

// ---------------------------------------------------------------------------
// Tool definitions (plain objects — no @opencode-ai/plugin import needed)
// ---------------------------------------------------------------------------

const todoReadDef = {
  description: `Use this tool to read the current to-do list for the session. This tool should be used proactively and frequently to ensure that you are aware of
the status of the current task list. You should make use of this tool as often as possible, especially in the following situations:
- At the beginning of conversations to see what's pending
- Before starting new tasks to prioritize work
- When the user asks about previous tasks or plans
- Whenever you're uncertain about what to do next
- After completing tasks to update your understanding of remaining work
- After every few messages to ensure you're on track

Usage:
- Returns a list of todo items with their status, priority, and content
- Use this information to track progress and plan next steps
- If no todos exist yet, an empty list will be returned`,
  args: {},
  async execute(_args: any, context: any) {
    const todos = getTodos(context.sessionID)
    const pending = todos.filter((t: TodoItem) => t.status !== "completed")
    context.metadata({
      title: `${pending.length} todos`,
      metadata: { todos },
    })
    return JSON.stringify(todos, null, 2)
  },
}

const todoWriteDef = {
  description: `Use this tool to create and manage a structured task list for your current coding session. This helps you track progress, organize complex tasks, and demonstrate thoroughness to the user.
It also helps the user understand the progress of the task and overall progress of their requests.

## When to Use This Tool
Use this tool proactively in these scenarios:

1. Complex multistep tasks - When a task requires 3 or more distinct steps or actions
2. Non-trivial and complex tasks - Tasks that require careful planning or multiple operations
3. User explicitly requests todo list - When the user directly asks you to use the todo list
4. User provides multiple tasks - When users provide a list of things to be done (numbered or comma-separated)
5. After receiving new instructions - Immediately capture user requirements as todos. Feel free to edit the todo list based on new information.
6. After completing a task - Mark it complete and add any new follow-up tasks
7. When you start working on a new task, mark the todo as in_progress. Ideally you should only have one todo as in_progress at a time. Complete existing tasks before starting new ones.

## When NOT to Use This Tool

Skip using this tool when:
1. There is only a single, straightforward task
2. The task is trivial and tracking it provides no organizational benefit
3. The task can be completed in less than 3 trivial steps
4. The task is purely conversational or informational

NOTE that you should not use this tool if there is only one trivial task to do. In this case you are better off just doing the task directly.

## Task States and Management

1. **Task States**: Use these states to track progress:
   - pending: Task not yet started
   - in_progress: Currently working on (limit to ONE task at a time)
   - completed: Task finished successfully
   - cancelled: Task no longer needed

2. **Task Management**:
   - Update task status in real-time as you work
   - Mark tasks complete IMMEDIATELY after finishing (don't batch completions)
   - Only have ONE task in_progress at any time
   - Complete current tasks before starting new ones
   - Cancel tasks that become irrelevant

3. **Task Breakdown**:
   - Create specific, actionable items
   - Break complex tasks into smaller, manageable steps
   - Use clear, descriptive task names

When in doubt, use this tool. Being proactive with task management demonstrates attentiveness and ensures you complete all requirements successfully.`,
  args: {
    todos: z
      .array(
        z.object({
          content: z.string().describe("Brief description of the task"),
          status: z
            .string()
            .describe("Current status of the task: pending, in_progress, completed, cancelled"),
          priority: z.string().describe("Priority level of the task: high, medium, low"),
        }),
      )
      .describe("The updated todo list"),
  },
  async execute(args: any, context: any) {
    setTodos(context.sessionID, args.todos)
    const pending = args.todos.filter((t: TodoItem) => t.status !== "completed")
    context.metadata({
      title: `${pending.length} todos`,
      metadata: { todos: args.todos },
    })
    return JSON.stringify(args.todos, null, 2)
  },
}

// ---------------------------------------------------------------------------
// Plugin export
// ---------------------------------------------------------------------------

export const TodoPlugin = async (_ctx: any) => {
  return {
    tool: {
      todoread: todoReadDef,
      todowrite: todoWriteDef,
    },

    // TUI metadata fix: fromPlugin() in registry.ts overwrites metadata
    // with { truncated }, destroying the todos field. This hook re-injects
    // it so the TUI TodoWrite component renders checkboxes.
    "tool.execute.after": async (input: any, output: any) => {
      if (input.tool === "todowrite" || input.tool === "todoread") {
        try {
          const todos = JSON.parse(output.output)
          output.metadata = {
            ...output.metadata,
            todos: Array.isArray(todos) ? todos : [],
          }
        } catch {
          // leave metadata as-is
        }
      }
    },
  }
}
