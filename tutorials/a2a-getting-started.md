---
title: "A2A Protocol Tutorial: Getting Started with Agent-to-Agent Communication"
date: 2026-02-23
author: Brenner Axiom
tags: [a2a, protocol, agents, tutorial, json-rpc]
---

# A2A Protocol Tutorial: Getting Started with Agent-to-Agent Communication

**Author:** Brenner Axiom  
**Date:** 2026-02-23  
**Bead:** beads-hub-98w (A2A Enablement Epic)  
**Status:** Working prototype on `localhost:3001`

## What is A2A?

A2A (Agent-to-Agent) is [Google's open protocol](https://google.github.io/A2A/) for enabling AI agents to communicate with each other. It uses:

- **JSON-RPC 2.0** for structured request/response
- **Agent Cards** (`/.well-known/agent.json`) for capability discovery
- **SSE (Server-Sent Events)** for streaming long-running tasks
- **Standard HTTP** — no proprietary transports

For #B4mad, A2A is how our agent fleet becomes interoperable with the wider agent ecosystem. Any external agent that speaks A2A can discover and task our agents — and vice versa.

## Architecture

```
┌─────────────────┐         ┌─────────────────┐
│  External Agent  │  HTTP   │  #B4mad A2A     │
│  (A2A Client)    │ ──────→ │  Server (:3001)  │
│                  │         │                  │
│  1. Discover     │ GET     │  /.well-known/   │
│     agent card   │ ──────→ │  agent.json      │
│                  │         │                  │
│  2. Send task    │ POST    │  /a2a            │
│     (JSON-RPC)   │ ──────→ │  tasks/send      │
│                  │         │                  │
│  3. Poll status  │ POST    │  /a2a            │
│     or stream    │ ──────→ │  tasks/get       │
└─────────────────┘         └─────────────────┘
```

## Prerequisites

- Node.js v22+ (installed on gamer-0)
- The A2A server module at `~/.openclaw/workspaces/codemonkey/a2a-server/`

## Quick Start

### 1. Start the A2A Server

```bash
cd ~/.openclaw/workspaces/codemonkey/a2a-server
npm start
# Output: A2A Server listening at http://localhost:3001
```

### 2. Discover the Agent Card

Every A2A agent exposes a card at `/.well-known/agent.json` describing its capabilities:

```bash
curl -s http://localhost:3001/.well-known/agent.json | python3 -m json.tool
```

Response:
```json
{
    "capabilities": {
        "tasks": {
            "send": true,
            "get": true,
            "cancel": true
        },
        "streaming": {
            "sse": true
        },
        "protocol": "A2A",
        "version": "1.0"
    },
    "description": "A2A Server Implementation"
}
```

This tells any client: "I can accept tasks, report status, cancel tasks, and stream results via SSE."

### 3. Send a Task

Tasks are sent via JSON-RPC 2.0 `POST` to `/a2a`:

```bash
curl -s -X POST http://localhost:3001/a2a \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tasks/send",
    "params": {
      "task": {
        "message": "Summarize the latest #B4mad research papers"
      }
    },
    "id": 1
  }' | python3 -m json.tool
```

Response:
```json
{
    "jsonrpc": "2.0",
    "result": {
        "taskId": "task-1771837003190",
        "status": "queued"
    },
    "id": 1
}
```

The server returns a `taskId` you can use to track progress.

### 4. Check Task Status

Poll for results with `tasks/get`:

```bash
curl -s -X POST http://localhost:3001/a2a \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tasks/get",
    "params": {
      "taskId": "task-1771837003190"
    },
    "id": 2
  }' | python3 -m json.tool
```

Response:
```json
{
    "jsonrpc": "2.0",
    "result": {
        "taskId": "task-1771837003190",
        "status": "completed",
        "output": "Task result would be here"
    },
    "id": 2
}
```

### 5. Cancel a Task

```bash
curl -s -X POST http://localhost:3001/a2a \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tasks/cancel",
    "params": {
      "taskId": "task-1771837003190"
    },
    "id": 3
  }' | python3 -m json.tool
```

### 6. Stream Results (SSE)

For long-running tasks, use Server-Sent Events by setting `Accept: text/event-stream`:

```bash
curl -s -X POST http://localhost:3001/a2a \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tasks/send",
    "params": {
      "task": {
        "message": "Long-running research task"
      }
    },
    "id": 4
  }'
```

This returns a stream of `data:` events with progress updates until the task completes.

## Error Handling

The server returns standard JSON-RPC 2.0 errors:

```bash
# Unknown method
curl -s -X POST http://localhost:3001/a2a \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"unknown/method","params":{},"id":5}'
```

Response:
```json
{
    "jsonrpc": "2.0",
    "error": {
        "code": -32601,
        "message": "Method not found"
    },
    "id": 5
}
```

## Current Limitations (Prototype)

This is a Phase 1 prototype. Key limitations:

| Feature | Status | Notes |
|---|---|---|
| Task persistence | ❌ In-memory only | Tasks lost on restart |
| OpenClaw integration | ❌ Not connected | Doesn't route to actual agents yet |
| Authentication | ❌ None | No API keys, OAuth, or mTLS (see beads-hub-98w.5) |
| Agent Card richness | ⚠️ Minimal | Missing skills, input schemas, pricing info |
| Task queuing | ⚠️ Simulated | No real queue or worker pool |

## Next Steps

These are tracked as beads in the A2A Enablement Epic (beads-hub-98w):

1. **beads-hub-98w.5** — Add authentication layer (API keys, OAuth2, mTLS)
2. **beads-hub-98w.4** — Build A2A client so our agents can call *other* A2A agents
3. **beads-hub-98w.6** — DNS-based agent discovery (`.well-known` + DNS TXT records)
4. **beads-hub-98w.7** — End-to-end demo: one agent tasks another via A2A

## How This Fits the #B4mad Vision

A2A is one leg of our interoperability triangle:

```
        A2A (Agent ↔ Agent)
           ╱         ╲
          ╱           ╲
    MCP (Agent ↔ Tool)  DAO (Agent ↔ Governance)
```

- **A2A** lets agents talk to each other across organizational boundaries
- **MCP** gives agents access to tools and data sources
- **DAO** provides decentralized governance for the agent fleet

Together, they make the "million-agent network" possible — discoverable, authenticated, and community-governed.

## References

1. [Google A2A Specification](https://google.github.io/A2A/)
2. [JSON-RPC 2.0 Specification](https://www.jsonrpc.org/specification)
3. [Server-Sent Events (MDN)](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events)
4. Romanov, "A2A + MCP Integration Analysis" — pending research bead
5. Bead: beads-hub-98w — A2A Enablement Epic
