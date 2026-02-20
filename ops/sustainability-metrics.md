---
layout: page
title: "Sustainability Metrics"
permalink: /ops/sustainability-metrics
---

# Sustainability Model — Metrics Tracking

**Bead:** beads-hub-n56 | **Date:** 2026-02-20 | **Author:** PltOps

## LOOPY Model Nodes & Metrics

Each node from the LOOPY sustainability model maps to concrete, trackable metrics.

### Node Definitions

| # | Node | Metrics | Collection Method | Frequency |
|---|------|---------|-------------------|-----------|
| 1 | **Donation Volume** | Total € donated, donor count, avg donation size | Open Collective API, GitHub Sponsors API, bank statements | Monthly |
| 2 | **Compute Spend** | Total € infra cost, cost per service, cost per user | Cloud billing APIs, invoices | Monthly |
| 3 | **Active Users** | MAU, DAU, session count, retention rate | Application logs, auth provider stats | Monthly (MAU), Weekly (WAU) |
| 4 | **Community Contributors** | Unique contributors/month, new contributors, returning contributors | Git log analysis (`git shortlog`), Codeberg/GitHub API | Monthly |
| 5 | **PR Count** | PRs opened, merged, closed, avg time-to-merge | Codeberg/GitHub API (`/repos/{owner}/{repo}/pulls`) | Monthly |
| 6 | **Ops Drag (B2)** | Toil hours, incident count, manual deployment count | Time tracking, incident log, deployment log | Monthly |
| 7 | **Community Engagement** | Forum posts, chat messages, event attendance | Signal/Discord message counts, event logs | Monthly |
| 8 | **Project Velocity** | Issues closed, story points completed, release frequency | Beads-hub stats (`bd` CLI), git tags | Monthly |

### Metric Details

#### 1. Donation Volume
```
donation_total_eur = sum(all donations in period)
donor_count = count(distinct donors in period)
avg_donation = donation_total_eur / donor_count
donation_growth_rate = (this_month - last_month) / last_month
```

#### 2. Compute Spend
```
compute_total_eur = sum(all infra invoices in period)
cost_per_user = compute_total_eur / active_users
cost_per_service = compute_total_eur / service_count
```

#### 3. Active Users
```
mau = count(distinct users with activity in 30d window)
retention = returning_users / previous_month_users
churn = 1 - retention
```

#### 4. Community Contributors
```
contributors = count(distinct git authors in period)
new_contributors = contributors NOT IN previous_period_contributors
bus_factor = min N contributors covering 50% of commits
```

#### 5. PR Count
```
prs_opened = count(PRs created in period)
prs_merged = count(PRs merged in period)
avg_ttm = mean(merge_date - open_date) for merged PRs
review_turnaround = mean(first_review_date - open_date)
```

### Dashboard Specification

**Recommended tool:** Grafana dashboard or static markdown report (start simple).

#### Dashboard Layout

| Panel | Type | Data |
|-------|------|------|
| Sustainability Ratio (SR) | Gauge | Current SR with color thresholds |
| SR Trend | Line chart | SR over last 12 months |
| Revenue vs Cost | Stacked bar | Monthly donations vs compute spend |
| Active Users | Line chart | MAU over time |
| Contributors | Bar chart | Monthly unique contributors |
| PR Velocity | Line chart | PRs merged/month, avg TTM |
| Cost per User | Line chart | Trend over time |

#### Data Collection Script (Skeleton)

```bash
#!/bin/bash
# collect-sustainability-metrics.sh
# Run monthly, outputs JSON for dashboard ingestion

MONTH=${1:-$(date +%Y-%m)}
OUTPUT="metrics/${MONTH}.json"

# Donations (manual input or API)
DONATIONS_EUR=${DONATIONS:-0}

# Compute cost (manual input or billing API)
COMPUTE_EUR=${COMPUTE:-0}

# Active users (from logs)
ACTIVE_USERS=$(grep -c "unique-session" /var/log/app/${MONTH}*.log 2>/dev/null || echo 0)

# Contributors (from git)
CONTRIBUTORS=$(cd /path/to/repos && git shortlog -sn --since="${MONTH}-01" --until="${MONTH}-31" | wc -l)

# PRs (from API)
PRS_MERGED=$(curl -s "https://codeberg.org/api/v1/repos/ORG/REPO/pulls?state=closed&sort=updated&limit=50" | jq "[.[] | select(.merged)] | length")

cat > "$OUTPUT" <<EOF
{
  "month": "${MONTH}",
  "donations_eur": ${DONATIONS_EUR},
  "compute_eur": ${COMPUTE_EUR},
  "active_users": ${ACTIVE_USERS},
  "contributors": ${CONTRIBUTORS},
  "prs_merged": ${PRS_MERGED},
  "sustainability_ratio": $(echo "scale=2; ${DONATIONS_EUR} / ${ACTIVE_USERS} / (${COMPUTE_EUR} / ${ACTIVE_USERS})" | bc 2>/dev/null || echo 0)
}
EOF

echo "Metrics written to ${OUTPUT}"
```

### Implementation Phases

1. **Phase 1 (Now):** Manual monthly data collection into markdown report (see sustainability-ratio.md template)
2. **Phase 2 (Month 2):** Automate git-based metrics (contributors, PRs) via script
3. **Phase 3 (Month 3):** Connect billing APIs for compute cost automation
4. **Phase 4 (Month 4+):** Grafana dashboard with automated data pipeline
