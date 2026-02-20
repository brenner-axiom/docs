---
layout: page
title: "Sustainability Ratio"
permalink: /docs/ops/sustainability-ratio
---

# Sustainability Ratio — Definition & Monthly Monitoring

**Bead:** beads-hub-ecu | **Date:** 2026-02-20 | **Author:** PltOps

## Metric Definition

**Sustainability Ratio (SR):**

```
SR = Donations per User / Compute Cost per User
```

**Target:** SR > 1.2 (20% margin above breakeven)

### Components

| Component | Formula | Unit |
|-----------|---------|------|
| Donations per User | Total monthly donations ÷ Active users | €/user/month |
| Compute Cost per User | Total monthly infra spend ÷ Active users | €/user/month |
| Sustainability Ratio | DPU ÷ CCPU | dimensionless |

### Data Sources

| Data Point | Source | Collection Method |
|------------|--------|-------------------|
| Monthly donations | Open Collective / GitHub Sponsors / direct transfers | API query or manual export |
| Active users | Application logs, unique authenticated sessions | Log aggregation (count distinct users/month) |
| Compute spend | Cloud billing (Nostromo cluster costs, VPS, storage) | Cloud provider billing API or invoice |
| Infrastructure overhead | Domain fees, monitoring tools, SaaS subscriptions | Manual ledger |

### Thresholds

| SR Value | Status | Action |
|----------|--------|--------|
| > 1.5 | 🟢 Thriving | Invest surplus in growth (R3 loop) |
| 1.2 – 1.5 | 🟢 Healthy | Maintain course |
| 1.0 – 1.2 | 🟡 Warning | Reduce compute or boost donations |
| < 1.0 | 🔴 Unsustainable | Emergency: cut non-essential services or fundraise |

## Monthly Report Template

```markdown
# Sustainability Report — YYYY-MM

## Summary
- **Sustainability Ratio:** X.XX (🟢/🟡/🔴)
- **Trend:** ↑/↓/→ vs last month

## Revenue
| Source | Amount (€) |
|--------|-----------|
| Open Collective | |
| GitHub Sponsors | |
| Direct donations | |
| **Total** | |

## Costs
| Category | Amount (€) |
|----------|-----------|
| Compute (Nostromo) | |
| VPS / hosting | |
| Storage | |
| SaaS / tools | |
| Domains | |
| **Total** | |

## Users
- Active users this month:
- Change vs last month:

## Calculated Metrics
- Donations per user: €X.XX
- Compute cost per user: €X.XX
- **Sustainability Ratio: X.XX**

## Actions
- [ ] (any corrective actions if SR < 1.2)

## Notes
(context, one-off costs, seasonal effects)
```
