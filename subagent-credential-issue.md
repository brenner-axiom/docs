# P0 Issue: Sub-Agent Credential Isolation

**Date:** 2026-02-18
**Bead:** beads-hub-s2k
**Author:** Brenner Axiom

## 1. Problem

Sub-agents spawned via `sessions_spawn` are failing critical tasks because they do not inherit the parent agent's environment or home directory configuration. This has repeatedly blocked tasks requiring authentication with external services like Codeberg.

**Examples:**
- **`forgejo-gomod-update`:** CodeMonkey could not push a branch to Codeberg because it lacked the `~/.netrc` file configured in the main agent's session.
- **`ingest-approve-refinement`:** The agent's work was lost because its workspace was ephemeral and it couldn't push changes.

This sterile environment, while secure, fundamentally breaks the "delegation-first" model for any task that touches an authenticated external service.

## 2. Root Cause Analysis

The `sessions_spawn` tool in OpenClaw is designed to create highly isolated, reproducible execution environments for sub-agents.

- **No Environment Inheritance:** `env` variables from the parent are not passed down.
- **No Home Directory Mounting:** Configuration files like `~/.netrc`, `~/.gitconfig`, or `~/.config/gopass` are not available.
- **Ephemeral Workspaces:** Unless a specific workspace is defined for the agent in `openclaw.json`, their working directory may be temporary.

This is a platform-level design choice for security, but it's too restrictive for our use case where agents are trusted members of the same fleet.

## 3. Proposed Solution

This requires a change to the OpenClaw platform configuration, likely in `openclaw.json`. I propose adding a new configuration section for sub-agent sessions that allows for controlled inheritance.

**Example `openclaw.json` modification:**

```json
{
  "agents": {
    "defaults": {
      "subagents": {
        "maxConcurrent": 8,
        "session": {
          "inheritEnv": [
            "GOPASS_STORE_DIR",
            "GIT_AUTHOR_NAME",
            "GIT_AUTHOR_EMAIL"
          ],
          "mountHomePaths": [
            ".netrc",
            ".gitconfig",
            ".config/gopass"
          ]
        }
      }
    }
  }
}
```

- **`inheritEnv`**: An allowlist of environment variables to pass from the parent to the sub-agent.
- **`mountHomePaths`**: An allowlist of files/directories from the parent's home directory to mount into the sub-agent's home directory.

This provides a secure, explicit way to grant sub-agents the context they need without opening up the entire environment.

## 4. Next Steps

1.  Present this finding to `goern`.
2.  If approved, `goern` will need to update the OpenClaw source code to implement this new configuration.
3.  Once implemented, this bead (`beads-hub-s2k`) can be closed.

This is the highest priority issue for enabling true autonomous collaboration within the agent fleet.
