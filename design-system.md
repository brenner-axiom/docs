---
layout: page
title: "#B4mad Design System"
description: "Corporate design system for all #B4mad Industries web properties"
---

# #B4mad Design System

The canonical visual identity for all **#B4mad Industries** web properties. This system defines colors, typography, spacing, and component patterns used across our sites and documentation.

---

## Color Palette

### Primary

| Role | Name | Hex | Usage |
|------|------|-----|-------|
| **Accent** | DarkSeaGreen4 | `#458B74` | Brand color, links, highlights, borders |
| **Accent Light** | — | `#5AAD92` | Hover states, headings, inline code |
| **Accent Dark** | — | `#346B59` | Pressed states, scrollbar hover |
| **Accent Glow** | — | `rgba(69, 139, 116, 0.4)` | Glows, text-shadow, pulse animations |

### Backgrounds (Dark Mode — Default)

| Role | Hex | Usage |
|------|-----|-------|
| **Primary** | `#0A0E14` | Page background |
| **Secondary** | `#111820` | Code blocks, pre elements |
| **Card** | `#151C25` | Card backgrounds |
| **Card Hover** | `#1A2330` | Card hover state |

### Text

| Role | Hex | Usage |
|------|-----|-------|
| **Primary** | `#E0E6ED` | Headings, body text |
| **Secondary** | `#8899AA` | Paragraphs, descriptions |
| **Muted** | `#556677` | Footer, meta text, agent roles |

### Borders

| Role | Value | Usage |
|------|-------|-------|
| **Default** | `#1E2A36` | Cards, dividers, table borders |
| **Accent** | `rgba(69, 139, 116, 0.3)` | Active/hover borders, section lines |

### Semantic

| Role | Hex | Usage |
|------|-----|-------|
| **Danger** | `#E74C3C` | Errors, destructive actions |
| **Warning** | `#F39C12` | Caution, alerts |
| **Info** | `#3498DB` | Informational highlights |

---

## Typography

### Font Stack

| Role | Font | Fallbacks |
|------|------|-----------|
| **Body** | Inter | -apple-system, BlinkMacSystemFont, sans-serif |
| **Code** | JetBrains Mono | monospace |

Both loaded via Google Fonts:
```
Inter: 300, 400, 600, 700, 900
JetBrains Mono: 400, 700
```

### Heading Hierarchy

| Level | Size | Weight | Notes |
|-------|------|--------|-------|
| **H1** (hero) | 3.5rem | 900 | Letter-spacing: -0.03em |
| **H1** (page) | 2.5rem | 900 | Gradient fill (text → accent-light) |
| **H2** | 1.5rem | 700 | Bottom border, 2.5rem top margin |
| **H3** | 1.2rem | 600 | Accent-light color |
| **Body** | 1rem (16px) | 400 | Line-height: 1.7 |
| **Small/Meta** | 0.85rem | — | Used for card text, nav items |
| **Section Label** | 0.75rem | 700 | Uppercase, 0.15em letter-spacing |

---

## Spacing & Layout

### Border Radius

| Token | Value | Usage |
|-------|-------|-------|
| `--radius` | 8px | Cards, buttons, code blocks |
| `--radius-lg` | 16px | Hero cards, large containers |
| Pill | 999px | Tags, status badges, nav pills |

### Container

- **Max width:** 1200px
- **Content max width:** 800px (page-content)
- **Padding:** 2rem (desktop), 1rem (mobile)

### Grid

- **Card grid:** `repeat(auto-fill, minmax(320px, 1fr))`, gap 1.25rem
- **Agent grid:** `repeat(auto-fill, minmax(200px, 1fr))`, gap 1rem

---

## Components

### Cards

- Background: `--bg-card` → `--bg-card-hover` on hover
- Border: `--border` → `--border-accent` on hover
- Top accent line (2px gradient) appears on hover
- Lift effect: `translateY(-2px)` + box-shadow on hover
- Transition: 0.3s ease

### Navigation

- Sticky header with blur backdrop (`blur(20px)`)
- Semi-transparent background: `rgba(10, 14, 20, 0.85)`
- Nav links: pill-shaped hover with accent background
- Mobile: hamburger toggle → vertical dropdown

### Code Blocks

- **Inline:** accent-light color, card background, 1px border, 4px radius
- **Block:** secondary background, border, 8px radius, 1.25rem padding

### Status Badge

- Pill shape (999px radius)
- JetBrains Mono font
- Accent border, card background
- Blinking cursor animation

### Page List

- Full-width link cards
- Slide-right effect on hover (`translateX(4px)`)
- Title + description layout

---

## Effects & Animation

| Effect | Details |
|--------|---------|
| **Background grid** | Subtle 60px grid lines at 3% opacity |
| **Glow orb** | Radial gradient, 20s drift animation |
| **Scanline** | 2px horizontal line, 8s vertical sweep |
| **Pulse dot** | Status indicator, 2s ease-in-out |
| **Card hover** | 2px lift + shadow + top accent line |
| **Link glow** | text-shadow on hover |

---

## Responsive Breakpoints

| Breakpoint | Changes |
|------------|---------|
| **≤ 768px** | Hero text shrinks, card grid → 1 col, hamburger nav, agent grid → 2 col |
| **≤ 480px** | Hero text smaller, agent grid → 1 col |

---

## Logo Usage

The #B4mad wordmark uses:
- **Font:** Inter, weight 900
- **Hash symbol:** Accent color (`#458B74`) with glow (`text-shadow: 0 0 12px`)
- **Status dot:** 8px accent circle with pulse animation
- Minimum clear space: 0.5rem around the mark

No standalone logo asset yet — the wordmark **is** the logo.

---

## Dark / Light Mode

Currently **dark mode only**. All CSS custom properties are defined for the dark theme. Light mode support is planned but not yet implemented.

---

## Implementation

The canonical CSS lives at:
```
assets/css/style.css
```

All values use CSS custom properties (`:root` vars) for consistency. When building new pages or components, always reference the design tokens rather than hard-coding values.

### CSS Custom Properties Reference

```css
:root {
  --accent: #458B74;
  --accent-light: #5aad92;
  --accent-dark: #346b59;
  --accent-glow: rgba(69, 139, 116, 0.4);
  --bg-primary: #0a0e14;
  --bg-secondary: #111820;
  --bg-card: #151c25;
  --bg-card-hover: #1a2330;
  --text-primary: #e0e6ed;
  --text-secondary: #8899aa;
  --text-muted: #556677;
  --border: #1e2a36;
  --border-accent: rgba(69, 139, 116, 0.3);
  --danger: #e74c3c;
  --warning: #f39c12;
  --info: #3498db;
  --radius: 8px;
  --radius-lg: 16px;
}
```
