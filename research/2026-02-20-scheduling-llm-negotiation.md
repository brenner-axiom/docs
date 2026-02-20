---
layout: page
title: "LLMs and Structured Approaches for Appointment Negotiation"
---

# LLMs and Structured Approaches for Appointment Negotiation

**Author:** Roman "Romanov" Research-Rachmaninov, #B4mad Industries  
**Date:** 2026-02-20  
**Bead:** beads-hub-dbq

## Abstract

Scheduling meetings—especially multi-party ones—remains one of the most tedious coordination problems in professional and personal life. This paper surveys the current landscape of AI scheduling assistants, examines the structured protocols that underpin calendar interoperability, and explores how Large Language Models can serve as negotiation agents for appointment scheduling. We propose an architecture for a #B4mad scheduling agent built on open standards (CalDAV, iCalendar, FREEBUSY) with LLM-driven natural language negotiation, and provide concrete implementation recommendations.

## Context: Why This Matters for #B4mad

#B4mad Industries operates as an agent-first organization. Agents already manage code, research, and infrastructure. Scheduling—the coordination of human and agent time—is a natural next frontier. A scheduling agent that speaks both natural language (to humans) and structured protocols (to calendars) would:

- Reduce coordination overhead for goern and collaborators
- Demonstrate #B4mad's agent-first philosophy in a tangible, daily-use product
- Create a reusable component for the broader OpenClaw ecosystem
- Showcase open-standard interoperability vs. proprietary walled gardens

## 1. Current State of AI Scheduling Assistants

### 1.1 Commercial Landscape

**x.ai (acquired by Bizzabo, 2021):** Pioneered the "AI assistant in CC" model where users would CC `amy@x.ai` on emails. It parsed natural language, checked calendars, and proposed times. Shut down as standalone product but proved the concept viable. Key lesson: the email-as-interface model worked but was brittle—parsing free-text email threads is error-prone.

**Reclaim.ai (acquired by Clockwise, 2024):** Focused on "smart calendar blocking"—automatically scheduling habits, tasks, and buffer time. More of an optimization engine than a negotiation agent. Strength: integrates deeply with Google Calendar. Weakness: doesn't negotiate across organizational boundaries.

**Clara (Clara Labs):** Virtual assistant service that combined AI with human-in-the-loop for scheduling. Positioned as premium enterprise. Demonstrated that full automation wasn't reliable enough for high-stakes scheduling—humans still needed to handle edge cases.

**Clockwise:** Calendar optimization focused on protecting "focus time" and finding optimal meeting slots for teams. Strong within-organization but limited cross-org negotiation.

**Cal.com (open source):** Scheduling links platform (like Calendly) but open source. Not AI-driven but provides important infrastructure: booking pages, availability rules, webhook integrations. Relevant as a potential integration target.

**Motion:** AI-powered task and calendar management. Uses optimization algorithms to auto-schedule tasks around meetings. More task-management than negotiation.

### 1.2 Key Patterns and Limitations

| Pattern | Examples | Strength | Limitation |
|---|---|---|---|
| CC-the-AI | x.ai | Natural email flow | Email parsing fragility |
| Smart blocking | Reclaim, Clockwise | Great within-org | No cross-org negotiation |
| Scheduling links | Calendly, Cal.com | Simple, reliable | One-directional; requester adapts |
| Human-in-loop | Clara | High quality | Expensive, doesn't scale |
| Chat-based | ChatGPT plugins | Flexible | No persistent calendar state |

**The gap:** No current solution combines (a) natural language multi-party negotiation, (b) deep calendar protocol integration, and (c) open-source/self-hosted architecture. This is the opportunity.

### 1.3 Recent LLM-Native Approaches (2025–2026)

Google's Gemini and OpenAI's ChatGPT have added calendar integrations, but these are walled-garden implementations tied to their respective ecosystems. Apple Intelligence added scheduling suggestions in iOS 19 but only within Apple Calendar. The trend is clear: LLMs are being connected to calendars, but always within proprietary silos.

## 2. Structured Scheduling Protocols and Languages

### 2.1 iCalendar (RFC 5545)

The foundational standard for calendar data interchange. Key components relevant to scheduling negotiation:

- **VEVENT**: The core event object with DTSTART, DTEND, SUMMARY, LOCATION, ATTENDEE
- **VFREEBUSY**: Represents free/busy time—critical for negotiation
- **VTODO**: Task objects that could represent scheduling requests
- **iTIP (RFC 5546)**: The interoperability protocol defining how calendar objects are exchanged (REQUEST, REPLY, COUNTER, CANCEL)
- **iMIP (RFC 6047)**: How iTIP messages are transported via email

**iTIP's COUNTER method** is particularly relevant: it allows an attendee to propose an alternative time for a meeting request. This is essentially a negotiation primitive built into the standard but almost never implemented by clients.

### 2.2 CalDAV (RFC 4791)

WebDAV extension for calendar access. Provides:

- Remote calendar CRUD operations
- Calendar collection discovery
- Free/busy reporting via `CALDAV:free-busy-query` REPORT
- Scheduling extensions (RFC 6638): server-side scheduling with inbox/outbox model

**CalDAV scheduling** (RFC 6638) defines a server-mediated model where:
1. Organizer submits a scheduling request to their outbox
2. Server delivers to attendees' inboxes
3. Attendees respond, server processes replies

This is the most complete open standard for automated scheduling, yet most implementations only support the basics.

### 2.3 FREEBUSY: The Negotiation Primitive

The `VFREEBUSY` component is the most underutilized tool in calendar standards:

```ical
BEGIN:VFREEBUSY
DTSTART:20260220T090000Z
DTEND:20260220T180000Z
FREEBUSY;FBTYPE=BUSY:20260220T100000Z/20260220T110000Z
FREEBUSY;FBTYPE=BUSY:20260220T140000Z/20260220T150000Z
END:VFREEBUSY
```

FREEBUSY allows sharing availability without revealing meeting details—a privacy-preserving negotiation mechanism. An LLM agent could:

1. Query each participant's FREEBUSY via CalDAV
2. Compute intersection of available slots
3. Apply preference heuristics (time-of-day, buffer time, timezone fairness)
4. Propose optimal slots in natural language

### 2.4 Jmap Calendar (RFC 8984)

JMAP (JSON Meta Application Protocol) includes a calendar extension that modernizes CalDAV with JSON-based APIs. More LLM-friendly than XML/WebDAV. Fastmail implements this; broader adoption is growing.

### 2.5 Schema.org and ScheduleAction

Schema.org defines `ScheduleAction` and `Event` types that could serve as structured output targets for LLMs. Combined with JSON-LD, this provides a web-native vocabulary for scheduling.

## 3. LLM-Based Negotiation Patterns for Multi-Party Scheduling

### 3.1 The Multi-Party Scheduling Problem

Scheduling a meeting with N participants is a constraint satisfaction problem:
- **Hard constraints**: Availability windows, timezone boundaries, room/resource availability
- **Soft constraints**: Preferred times, meeting duration preferences, buffer time, fairness across timezones
- **Social constraints**: Priority of participants, politeness norms, organizational hierarchy

Classical approaches (constraint solvers, optimization) handle hard constraints well but fail at soft and social constraints. This is where LLMs excel.

### 3.2 LLM as Negotiation Mediator

The most promising pattern uses the LLM as a **mediator** between participants:

```
Participant A ←→ [LLM Mediator] ←→ Participant B
                      ↕
               [Calendar APIs]
```

**Negotiation flow:**
1. **Intent extraction**: LLM parses natural language request ("Let's meet next week for an hour to discuss the roadmap")
2. **Constraint gathering**: Query each participant's calendar via CalDAV/FREEBUSY
3. **Slot computation**: Algorithmic intersection (not LLM—this is deterministic)
4. **Preference ranking**: LLM applies soft constraints and cultural norms
5. **Proposal generation**: LLM crafts natural language proposals personalized per participant
6. **Counter-negotiation**: Handle "that doesn't work, how about..." responses
7. **Confirmation**: Send iTIP REQUEST to all participants, process REPLYs

### 3.3 Structured Output for Reliability

LLMs must produce structured calendar data reliably. Key techniques:

- **Function calling / tool use**: Define scheduling tools (check_availability, propose_time, book_meeting) that the LLM invokes with structured parameters
- **JSON mode with schema validation**: Constrain LLM output to valid scheduling objects
- **CalDAV as ground truth**: Never trust LLM's "memory" of availability—always re-query the calendar

### 3.4 Multi-Agent Scheduling

In an agent-first world, each participant might have their own scheduling agent:

```
Agent A (represents Alice) ←→ Agent B (represents Bob)
         ↕                              ↕
   Alice's Calendar               Bob's Calendar
```

This requires a **negotiation protocol**. Options:

- **iTIP over email**: Agents exchange iTIP messages via iMIP. Mature, widely supported, but slow (email latency).
- **Direct API**: Agents communicate via REST/gRPC with structured scheduling messages. Fast but requires mutual discovery.
- **ActivityPub + Calendar extensions**: Federated scheduling using ActivityPub for agent discovery and message passing, with iCalendar payloads. Aligns with #B4mad's open-standards philosophy.
- **MCP (Model Context Protocol)**: Anthropic's MCP could define scheduling tools that agents expose to each other.

### 3.5 Handling Ambiguity and Cultural Norms

LLMs are uniquely suited to handle the "soft" parts of scheduling:

- "Let's meet sometime next week" → LLM infers reasonable business hours, avoids Monday morning and Friday afternoon
- Timezone fairness: rotating who gets the early/late slot in recurring cross-timezone meetings
- Urgency detection: "ASAP" vs. "when you get a chance" → different search windows
- Cultural norms: lunch-hour avoidance (varies by culture), meeting-free days

## 4. A #B4mad Scheduling Agent: Architecture Proposal

### 4.1 Design Principles

1. **Open standards only**: CalDAV, iCalendar, iTIP. No proprietary lock-in.
2. **Privacy-preserving**: Use FREEBUSY for cross-org queries. Never expose meeting details.
3. **LLM for language, algorithms for logic**: Don't ask the LLM to compute time intersections.
4. **Human-in-the-loop by default**: Propose, don't book. Escalate ambiguity.
5. **Multi-channel**: Works via Signal, email, or any OpenClaw channel.

### 4.2 Component Architecture

```
┌─────────────────────────────────────────────┐
│              OpenClaw Agent Layer            │
│  ┌──────────┐  ┌───────────┐  ┌──────────┐ │
│  │ NL Parser│  │ Negotiator│  │ Proposer │ │
│  │  (LLM)   │  │   (LLM)   │  │  (LLM)   │ │
│  └────┬─────┘  └─────┬─────┘  └────┬─────┘ │
│       │               │              │       │
│  ┌────▼───────────────▼──────────────▼────┐ │
│  │        Scheduling Engine (Rust/Python)  │ │
│  │  - Constraint solver                    │ │
│  │  - Timezone arithmetic                  │ │
│  │  - Slot intersection                    │ │
│  │  - Preference scoring                   │ │
│  └────────────────┬───────────────────────┘ │
│                   │                          │
│  ┌────────────────▼───────────────────────┐ │
│  │        CalDAV/iCalendar Adapter        │ │
│  │  - FREEBUSY queries                    │ │
│  │  - iTIP REQUEST/REPLY/COUNTER          │ │
│  │  - JMAP Calendar (optional)            │ │
│  └────────────────┬───────────────────────┘ │
└───────────────────┼─────────────────────────┘
                    │
    ┌───────────────┼───────────────┐
    ▼               ▼               ▼
 Nextcloud      Google Cal     Fastmail
 (CalDAV)     (CalDAV/API)     (JMAP)
```

### 4.3 Interaction Flow Example

**Signal conversation:**
```
goern: "Schedule a call with Alice and Bob next week, 
        45 minutes, about the DAO proposal"

Brenner: Checking calendars...
         
         Found 3 slots that work for everyone:
         1. Tue 10:00-10:45 CET (Alice: 04:00 PST, Bob: 18:00 JST)
         2. Wed 16:00-16:45 CET (Alice: 07:00 PST, Bob: 00:00 JST ⚠️)
         3. Thu 10:00-10:45 CET (Alice: 01:00 PST ⚠️, Bob: 18:00 JST)
         
         Recommendation: Tuesday — fairest across timezones.
         Shall I send the invite?

goern: Tuesday works. Send it.

Brenner: ✅ Invite sent to alice@example.com and bob@example.com
         Subject: "DAO Proposal Discussion"
         Tue Feb 24, 10:00-10:45 CET
```

### 4.4 Integration with Existing #B4mad Infrastructure

- **OpenClaw channels**: Scheduling requests arrive via Signal, Discord, or email
- **Beads**: Each scheduling negotiation tracked as a bead for auditability
- **Nextcloud**: Primary CalDAV backend (already in #B4mad stack)
- **MCP tools**: Expose scheduling capabilities as MCP tools for other agents

## 5. Recommendations for Implementation

### 5.1 Phase 1: CalDAV Read-Only Agent (2-3 weeks)

**Goal:** Agent can query availability and suggest meeting times.

- Implement CalDAV client (Python `caldav` library or Rust `reqwest` + iCalendar parsing)
- Connect to Nextcloud CalDAV endpoint
- Expose as OpenClaw MCP tool: `check_availability(participants, date_range, duration)`
- LLM formats results as natural language proposals
- **No booking yet**—just suggestions

### 5.2 Phase 2: Single-Org Booking (2-3 weeks)

**Goal:** Agent can create calendar events for participants within #B4mad.

- Implement iTIP REQUEST generation
- Send invites via CalDAV scheduling outbox
- Handle REPLY processing (accepted/declined/tentative)
- Add human confirmation step before booking

### 5.3 Phase 3: Cross-Org Negotiation (4-6 weeks)

**Goal:** Agent negotiates with external participants via email.

- Implement iMIP (iTIP over email) for cross-org scheduling
- FREEBUSY queries for privacy-preserving availability exchange
- Multi-round negotiation with counter-proposals
- Timezone fairness scoring

### 5.4 Phase 4: Multi-Agent Federation (exploratory)

**Goal:** #B4mad scheduling agent communicates with other agents.

- Define scheduling MCP tools for agent-to-agent negotiation
- Explore ActivityPub for federated agent discovery
- Implement COUNTER proposal handling in iTIP

### 5.5 Technology Choices

| Component | Recommendation | Rationale |
|---|---|---|
| CalDAV client | Python `caldav` library | Mature, well-tested, Nextcloud-compatible |
| iCalendar parsing | `icalendar` (Python) | Full RFC 5545 support |
| Constraint solver | Custom Python/Rust | Simple interval intersection; no need for heavy frameworks |
| LLM integration | OpenClaw native | Already the agent framework |
| Calendar backend | Nextcloud | Already deployed in #B4mad infrastructure |
| Cross-org transport | iMIP (email) | Universal, no setup required for counterparties |

### 5.6 Key Risks and Mitigations

| Risk | Mitigation |
|---|---|
| LLM hallucinates availability | Always query CalDAV as ground truth; never cache |
| Timezone errors | Use `dateutil` / `chrono` with IANA timezone database; test extensively |
| Privacy leakage | Only share FREEBUSY, never event details, across org boundaries |
| Spam/abuse | Rate limiting, human confirmation for external invites |
| Calendar conflicts | Optimistic locking; re-check availability before final booking |

## References

1. RFC 5545 — Internet Calendaring and Scheduling Core Object Specification (iCalendar). Desruisseaux, B. (2009). https://datatracker.ietf.org/doc/html/rfc5545
2. RFC 5546 — iCalendar Transport-Independent Interoperability Protocol (iTIP). Daboo, C. (2009). https://datatracker.ietf.org/doc/html/rfc5546
3. RFC 6047 — iCalendar Message-Based Interoperability Protocol (iMIP). Melnikov, A. (2010). https://datatracker.ietf.org/doc/html/rfc6047
4. RFC 4791 — Calendaring Extensions to WebDAV (CalDAV). Daboo, C., Desruisseaux, B., Dusseault, L. (2007). https://datatracker.ietf.org/doc/html/rfc4791
5. RFC 6638 — Scheduling Extensions to CalDAV. Daboo, C., Desruisseaux, B. (2012). https://datatracker.ietf.org/doc/html/rfc6638
6. RFC 8984 — JSCalendar: A JSON Representation of Calendar Data. Jenkins, N., Stepanek, R. (2021). https://datatracker.ietf.org/doc/html/rfc8984
7. Cal.com — Open-source scheduling infrastructure. https://cal.com
8. Reclaim.ai — AI scheduling for Google Calendar. https://reclaim.ai (acquired by Clockwise, 2024)
9. Schema.org ScheduleAction. https://schema.org/ScheduleAction
10. Anthropic Model Context Protocol (MCP). https://modelcontextprotocol.io

---

*Published by #B4mad Research. Bead: beads-hub-dbq.*
