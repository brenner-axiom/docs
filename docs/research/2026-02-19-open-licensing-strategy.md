# Open Licensing Strategy for the #B4mad Agent Ecosystem

**Author:** Roman "Romanov" Research-Rachmaninov
**Date:** 2026-02-19
**Bead:** beads-hub-3kl
**Status:** Final

## Abstract

This paper analyzes the optimal open-source licensing strategy for the #B4mad agent ecosystem. goern's standing mandate is GPLv3 for all public repositories. We evaluate whether this is the right choice across the ecosystem's component types — agent skills, tools, infrastructure, and shared protocols — by comparing GPLv3, AGPLv3, Apache 2.0, MIT, and dual-licensing models. We conclude that GPLv3 is a strong default but recommend AGPLv3 for server-side infrastructure and consider a strategic carve-out for protocol definitions and interoperability layers.

## Context: Why This Matters for #B4mad

The agent ecosystem is at an inflection point. As noted in the Lex Fridman AI State of the Art discussion (#490, ~36:21), Chinese open models are winning developer loyalty precisely because they ship with truly unrestricted licenses — no usage restrictions, no behavioral clauses, no strings attached. Sebastian Bubeck observed: "people like things where strings are not attached." Nathan Lambert noted that open releases serve as distribution mechanisms.

#B4mad operates in this landscape. Its agent infrastructure (OpenClaw, skills, tools) must attract contributors, enable commercial adoption where appropriate, and protect against proprietary capture. The licensing choice is a strategic lever, not a formality.

## The Candidate Licenses

### MIT / BSD (Permissive)
- **Mechanism:** Do anything; keep the copyright notice.
- **Copyleft:** None. Derivatives can be proprietary.
- **Ecosystem examples:** Most npm packages, Kubernetes, React.

### Apache 2.0 (Permissive + Patent Grant)
- **Mechanism:** Like MIT but with explicit patent grant and retaliation clause.
- **Copyleft:** None.
- **Ecosystem examples:** Apache projects, TensorFlow, CrewAI, LangChain.

### GPLv3 (Strong Copyleft)
- **Mechanism:** Derivatives must be GPLv3. Source must accompany binaries.
- **SaaS gap:** Running GPL software as a service does NOT trigger distribution — no obligation to share modifications.
- **Ecosystem examples:** GCC, WordPress, GNU Coreutils.

### AGPLv3 (Network Copyleft)
- **Mechanism:** Like GPLv3, but network interaction counts as distribution. If you modify and serve it, you must share source.
- **Closes the SaaS gap.**
- **Ecosystem examples:** MongoDB (pre-SSPL), Grafana, Nextcloud, Mastodon.

### Dual Licensing (Copyleft + Commercial)
- **Mechanism:** Code is GPL/AGPL for open-source users; commercial license available for purchase.
- **Ecosystem examples:** MySQL/MariaDB, Qt, MongoDB (historical), GitLab.

## Analysis by Component Type

### 1. Agent Infrastructure (OpenClaw Core, Orchestration)

This is the crown jewel — the runtime that coordinates agents, manages sessions, routes tools.

**Risk with GPLv3:** A cloud provider could fork OpenClaw, modify it, and offer it as a hosted service without contributing back. GPLv3's distribution trigger does not cover SaaS deployment. This is the exact scenario that drove MongoDB from AGPL to SSPL and Elastic from Apache to SSPL.

**Recommendation: AGPLv3.** The network interaction clause ensures that anyone running a modified OpenClaw as a service must share their changes. This is the strongest protection against proprietary cloud capture while remaining OSI-approved and community-friendly.

### 2. Agent Skills and Tools (Plugins, MCP Servers)

Skills are modular capabilities — fetching URLs, controlling browsers, sending messages. They are the primary surface for community contribution and third-party adoption.

**The tension:** GPLv3 skills cannot be loaded into Apache 2.0 or MIT-licensed agent frameworks without those frameworks becoming GPL (if they create a derivative work through tight coupling). This could limit adoption.

**However:** The linking question for agent skills is nuanced. Skills typically communicate via well-defined protocols (MCP, tool schemas, IPC). This separation may mean that a skill running as a subprocess or over a network boundary does NOT create a derivative work of the host framework. The FSF has historically held that programs communicating at arm's length via pipes or sockets are separate works.

**Recommendation: GPLv3 (default).** Skills authored by #B4mad should be GPLv3 per goern's mandate. The process-boundary separation means GPL skills can interoperate with permissively-licensed frameworks without infection. Community contributors can choose their own license for their skills. Document this architectural separation explicitly.

### 3. Protocol Definitions and Interoperability Layers

Shared schemas, wire formats, API specifications — the glue between components.

**Risk with GPLv3:** If the MCP protocol adapter or shared type definitions are GPL, any tool implementing those interfaces might arguably create a derivative work. This chills ecosystem participation.

**Industry precedent:** Linux uses GPL but has an explicit syscall exception so userspace programs aren't derivative works. The FSF recommends LGPL for libraries intended for broad use.

**Recommendation: Apache 2.0 for protocol/interface definitions.** This maximizes ecosystem compatibility. Anyone can implement the protocol. The *implementations* (OpenClaw's MCP server, skill runtime) remain AGPL/GPL. This mirrors the Linux kernel (GPL) + POSIX (open standard) pattern.

### 4. Documentation and Research (This Repo)

**Recommendation: CC BY-SA 4.0.** Standard for documentation. Share-alike ensures contributions flow back; attribution ensures credit. Already common practice in open-source projects.

## Interaction with the Broader Agent Ecosystem

| Framework | License | GPL Compatible? | Notes |
|-----------|---------|-----------------|-------|
| CrewAI | MIT | ✅ Yes (one-way) | CrewAI can use GPL tools via process boundary |
| LangChain | MIT | ✅ Same | |
| AutoGen | MIT → CC BY 4.0 | ✅ | Microsoft shifted; watch for changes |
| MCP (Anthropic) | MIT | ✅ | Protocol spec is MIT; implementations vary |
| OpenClaw | Proprietary/Custom | ⚠️ Depends | Need to verify current license terms |
| Ollama | MIT | ✅ | |
| vLLM | Apache 2.0 | ✅ | |

**Key insight:** Because the agent ecosystem overwhelmingly uses permissive licenses, GPL components can *consume* them freely. The concern is the reverse — can permissively-licensed tools consume GPL code? The answer depends on coupling. With process-boundary separation (which is the standard architecture for agent skills), there is no issue.

## The SaaS Gap: Why GPLv3 Alone Is Insufficient for Infrastructure

This deserves emphasis. GPLv3 was designed for an era of distributed software. In 2026, most software runs as a service. The critical scenario:

1. Cloud provider takes OpenClaw (GPLv3)
2. Modifies it to scale better on their infrastructure
3. Offers it as "ManagedClaw" — a hosted agent platform
4. Never distributes a binary → never triggers GPL obligations
5. #B4mad sees no code back

AGPLv3 closes this. When a user interacts with a modified AGPL program over a network, the operator must offer the source. This is why **every serious open-source infrastructure project** has moved beyond GPL:

- Nextcloud: AGPL
- Mastodon: AGPL
- Grafana: AGPL
- Matrix/Synapse: Apache 2.0 (but with CLA enabling dual-licensing)

## Commercial Adoption Implications

**Concern:** "GPL scares companies away."

**Reality check:**
- WordPress is GPLv2. It powers 43% of the web. Automattic is worth billions.
- Red Hat built a $34B business on GPL software.
- Linux (GPLv2) is the most commercially successful open-source project in history.

**What actually scares companies:** Not GPL itself, but uncertainty about derivative work boundaries. The solution is clear documentation of what constitutes a derivative work in the #B4mad architecture. If skills communicate via defined protocols over process boundaries, commercial users can build proprietary skills that interoperate with GPL infrastructure without concern.

**Recommendation:** Publish a clear "Licensing FAQ" that explicitly states:
1. Skills running as separate processes are NOT derivative works of OpenClaw
2. Commercial entities CAN build proprietary skills
3. Modifications to OpenClaw core (AGPL) must be shared if served to users
4. Protocol implementations using Apache 2.0 specs are NOT GPL-encumbered

## Fork Protection

One of goern's core motivations for GPLv3 is fork protection — preventing someone from taking the code proprietary. Let's evaluate:

| License | Fork Protection | SaaS Protection |
|---------|----------------|-----------------|
| MIT | ❌ None | ❌ None |
| Apache 2.0 | ❌ None | ❌ None |
| GPLv3 | ✅ Strong (binary) | ❌ None (SaaS gap) |
| AGPLv3 | ✅ Strong (binary) | ✅ Strong (network) |
| Dual (AGPL + Commercial) | ✅ Maximum | ✅ Maximum |

**GPLv3 provides strong fork protection for traditional distribution but leaves the SaaS gap open.** For infrastructure components, this is a critical vulnerability. AGPLv3 provides comprehensive protection.

## The #B4mad Sustainability Model

The bead description asks about GNU Taler-based donation funding. This is compatible with any license, but license choice affects leverage:

- **Permissive (MIT/Apache):** Donations are the *only* revenue mechanism. No leverage to convert users to paying customers. Amazon can offer your software as a service and you get nothing.
- **AGPL:** Creates natural demand for commercial licenses. Companies that want to modify and serve without sharing source must negotiate. This is proven (MySQL, MongoDB, Grafana Enterprise).
- **Dual-licensing (AGPL + Commercial):** The strongest model. AGPL for community; commercial license for enterprises that want proprietary modifications. Donations supplement but aren't the sole revenue stream.

**Recommendation:** Start with pure AGPL. If #B4mad grows to need enterprise revenue, the path to dual-licensing is straightforward (requires CLA or copyright assignment from contributors). Consider implementing a CLA early to preserve this option.

## Recommendations Summary

| Component | Recommended License | Rationale |
|-----------|-------------------|-----------|
| OpenClaw core / infrastructure | **AGPLv3** | Closes SaaS gap; strongest fork + service protection |
| Agent skills & tools (#B4mad authored) | **GPLv3** | Per goern's mandate; process-boundary separation prevents infection concerns |
| Protocol definitions, schemas, APIs | **Apache 2.0** | Maximizes ecosystem adoption; implementations remain copyleft |
| Documentation & research | **CC BY-SA 4.0** | Standard for docs; share-alike ensures contributions flow back |
| Third-party contributed skills | **Contributor's choice** | Ecosystem health; document compatibility expectations |

### Action Items

1. **Adopt AGPLv3 for OpenClaw infrastructure** — upgrade from GPLv3 where applicable
2. **Carve out Apache 2.0 for protocol/interface packages** — publish as separate repos
3. **Publish a Licensing FAQ** — clarify derivative work boundaries for commercial users
4. **Implement a CLA** — preserve the option for dual-licensing if needed later
5. **Document the architecture boundary** — make explicit that skills are separate works when running as processes

## References

1. Free Software Foundation. "GNU General Public License v3." https://www.gnu.org/licenses/gpl-3.0.html
2. Free Software Foundation. "GNU Affero General Public License v3." https://www.gnu.org/licenses/agpl-3.0.html
3. Free Software Foundation. "Frequently Asked Questions about the GNU Licenses." https://www.gnu.org/licenses/gpl-faq.html
4. Open Source Initiative. "The Open Source Definition." https://opensource.org/osd
5. Välimäki, M. "Dual Licensing in Open Source Software Industry." Systemes d'Information et Management, 2003.
6. Fridman, L. "AI State of the Art 2026" (Podcast #490, transcript ~36:21). Discussion on open licensing and Chinese model adoption.
7. Fontana, R. & Kuhn, B. "A Legal Issues Primer for Open Source and Free Software Projects." Software Freedom Law Center, 2008.
8. Wheeler, D.A. "The Free-Libre / Open Source Software (FLOSS) License Slide." https://dwheeler.com/essays/floss-license-slide.html

---

*Romanov out. 🎹*
