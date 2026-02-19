# Embedding LOOPY Simulations in goern.name Blog Posts

**Author:** Roman "Romanov" Research-Rachmaninov
**Date:** 2026-02-19
**Bead:** beads-hub-47n

## Abstract

LOOPY (ncase.me/loopy) is Nicky Case's open-source tool for creating interactive system dynamics simulations. Licensed CC0, built in pure JavaScript with no dependencies, it is ideal for embedding in static blog posts. This paper provides a complete guide for embedding LOOPY simulations in goern.name, covering iframe embedding, self-hosting, URL-parameter-driven pre-loaded models, responsive design, and a step-by-step Hugo integration guide.

## Context — Why This Matters for #B4mad

goern's blog (goern.name) discusses complex systems: agent architectures, open-source dynamics, decentralization trade-offs. Static text and diagrams fail to convey feedback loops and emergent behavior. LOOPY lets readers *play* with models — drag nodes, adjust relationships, run simulations — turning passive reading into active exploration. This is Nicky Case's "explorable explanations" philosophy applied to #B4mad's communication needs.

## State of the Art

### LOOPY Overview

- **Repository:** github.com/ncase/loopy
- **License:** CC0 (public domain) — no attribution required, fork freely
- **Technology:** Vanilla JavaScript, HTML5 Canvas, no build system, no dependencies
- **File size:** ~200KB total (JS + HTML + CSS)
- **Browser support:** All modern browsers, including mobile

### Embedding Approaches in the Wild

1. **Direct iframe to ncase.me** — simplest, used by many bloggers
2. **Self-hosted fork** — full control, used by educators and researchers
3. **LOOPY v2 (loopy.surge.sh)** — newer version with additional features, also embeddable

## Analysis

### Approach 1: Iframe Embedding (Quick Start)

The simplest method. LOOPY supports URL parameters that encode a full model state.

```html
<iframe
  src="https://ncase.me/loopy/v1.1/?embed=1&data=[encoded-model-data]"
  width="800"
  height="500"
  frameborder="0"
  style="border: none; max-width: 100%;"
  loading="lazy"
  allowfullscreen>
</iframe>
```

**How to get the embed URL:**
1. Open ncase.me/loopy and create your model
2. Click the share/export button — LOOPY encodes the entire model state as a URL parameter
3. Append `&embed=1` to hide the UI chrome and show only the simulation canvas

**Pros:** Zero setup, always up-to-date
**Cons:** External dependency, potential latency, ncase.me could go down

### Approach 2: Self-Hosting the LOOPY Engine

Given CC0 licensing, self-hosting is straightforward and recommended for production blogs.

**Steps:**
1. Clone/fork `github.com/ncase/loopy`
2. Copy the built files to your Hugo static directory:
   ```
   static/
     loopy/
       css/
       js/
       index.html
   ```
3. Reference locally:
   ```html
   <iframe src="/loopy/index.html?embed=1&data=[model]" ...></iframe>
   ```

**Advantages:**
- No external dependency
- Faster loading (same-origin, CDN-cached)
- Can customize CSS/behavior (brand colors, dark mode)
- Works offline/on corporate networks that block external sites
- Full control over versioning

### Approach 3: URL Parameters and Pre-loaded Models

LOOPY's URL parameter system encodes the complete model as a JSON-like structure in the `data` parameter. The format includes:

- **Nodes:** position (x,y), label, initial value, color/hue
- **Edges:** source→target, relationship type (+/−), strength
- **Labels:** text annotations

**Creating a model programmatically:**
The `data` parameter is a URL-encoded array structure. While the format is not formally documented, inspecting the source reveals it follows this pattern:
```
data=[[[node1],[node2],...],[[edge1],[edge2],...],[[label1],...],screenX,screenY]
```

Each node: `[id, x, y, initialValue, label, hue]`
Each edge: `[fromId, toId, arc, strength, label]`

**Workflow for blog authors:**
1. Design the model visually at ncase.me/loopy
2. Export/share to get the data parameter
3. Paste into the blog post's iframe src
4. The model loads pre-built when readers visit

### Responsive Design Considerations

LOOPY renders to HTML5 Canvas, which doesn't auto-resize. Solutions:

**CSS-based responsive wrapper:**
```html
<div style="position: relative; width: 100%; padding-bottom: 62.5%; overflow: hidden;">
  <iframe
    src="/loopy/index.html?embed=1&data=[model]"
    style="position: absolute; top: 0; left: 0; width: 100%; height: 100%; border: none;"
    loading="lazy"
    allowfullscreen>
  </iframe>
</div>
```

This maintains a 16:10 aspect ratio and scales to container width.

**Mobile considerations:**
- Touch interactions work natively on LOOPY's canvas
- Minimum recommended width: 320px (LOOPY remains usable)
- Consider adding a "tap to interact" overlay on mobile to prevent scroll-jacking

**Dark mode:**
Self-hosted version can be CSS-customized. The canvas background and node colors are set in JS — fork and modify `css/` and the color constants in the source.

## Step-by-Step Hugo Integration Guide

goern.name likely runs Hugo (standard for static blogs in the Go ecosystem). Here's the complete workflow:

### 1. Set Up Self-Hosted LOOPY

```bash
cd your-hugo-site/
mkdir -p static/loopy
# Download LOOPY release files
curl -L https://github.com/ncase/loopy/archive/refs/heads/master.zip -o /tmp/loopy.zip
unzip /tmp/loopy.zip -d /tmp/loopy-src
cp -r /tmp/loopy-src/loopy-master/* static/loopy/
```

### 2. Create a Hugo Shortcode

Create `layouts/shortcodes/loopy.html`:

```html
{{ $data := .Get "data" }}
{{ $width := .Get "width" | default "100%" }}
{{ $height := .Get "height" | default "500px" }}
{{ $caption := .Get "caption" }}

<figure class="loopy-embed">
  <div style="position: relative; width: {{ $width }}; max-width: 800px; margin: 1.5em auto;">
    <iframe
      src="/loopy/index.html?embed=1&data={{ $data }}"
      style="width: 100%; height: {{ $height }}; border: 1px solid #ddd; border-radius: 4px;"
      loading="lazy"
      allowfullscreen>
    </iframe>
    {{ with $caption }}
    <figcaption style="text-align: center; font-style: italic; margin-top: 0.5em; color: #666;">
      {{ . }}
    </figcaption>
    {{ end }}
  </div>
</figure>
```

### 3. Use in Blog Posts

In any markdown blog post:

```markdown
Here's how agent access and security interact:

{{</* loopy data="[encoded-model-data-here]" caption="More access increases both usefulness and risk" */>}}

As you can see by running the simulation...
```

### 4. Creating Models for Posts

**Workflow:**
1. Visit ncase.me/loopy (or your self-hosted `/loopy/`)
2. Build the model visually — add nodes, draw relationships
3. Click share → copy the URL
4. Extract the `data=` parameter value
5. Paste into the shortcode's `data` attribute

### 5. Example: Agent Security Trade-off Model

A simple model demonstrating #B4mad concepts:

- **Node 1:** "Tool Access" (green)
- **Node 2:** "Usefulness" (blue)
- **Node 3:** "Security Risk" (red)
- **Node 4:** "User Trust" (yellow)
- **Edges:** Access→Usefulness (+), Access→Risk (+), Risk→Trust (−), Trust→Access (+)

This creates a visible feedback loop: more access → more useful but riskier → erodes trust → reduces access. Readers can experiment with the dynamics.

### 6. Jekyll Alternative

If goern.name uses Jekyll instead of Hugo:

Create `_includes/loopy.html`:
```html
<div class="loopy-embed" style="max-width: 800px; margin: 1.5em auto;">
  <iframe
    src="/loopy/index.html?embed=1&data={{ include.data }}"
    style="width: 100%; height: {{ include.height | default: '500px' }}; border: 1px solid #ddd; border-radius: 4px;"
    loading="lazy"
    allowfullscreen>
  </iframe>
  {% if include.caption %}
  <p style="text-align: center; font-style: italic; color: #666;">{{ include.caption }}</p>
  {% endif %}
</div>
```

Usage in posts:
```liquid
{% include loopy.html data="[model-data]" caption="Feedback loop visualization" %}
```

## Recommendations

1. **Self-host LOOPY** — Copy the ~200KB engine into `static/loopy/`. Zero dependency, full control, CC0 makes this frictionless.

2. **Create the Hugo shortcode** — The `{{</* loopy */>}}` shortcode reduces embedding to a one-liner per post. Takes 5 minutes to set up, saves time on every future post.

3. **Build a model library** — Create reusable models for recurring #B4mad concepts (agent dynamics, governance feedback loops, open-source sustainability). Store the data strings in a reference file.

4. **Use responsive wrappers** — The CSS approach above ensures models work on mobile without additional JavaScript.

5. **Consider LOOPY v2** — The newer version (loopy.surge.sh) adds features like adjustable simulation speed. Evaluate whether the additional capabilities justify the switch. The embedding approach is identical.

6. **Add lazy loading** — The `loading="lazy"` attribute on iframes prevents LOOPY from loading until scrolled into view, keeping page performance crisp for posts with multiple simulations.

7. **Customize for brand** — Fork LOOPY and adjust the color palette and canvas background to match goern.name's theme. This is a minor CSS/JS edit.

## References

- LOOPY source: github.com/ncase/loopy (CC0)
- Nicky Case's explorable explanations: ncase.me
- LOOPY v2: loopy.surge.sh
- Hugo shortcodes documentation: gohugo.io/templates/shortcode-templates/
- Jekyll includes documentation: jekyllrb.com/docs/includes/
- HTML5 iframe responsive patterns: developer.mozilla.org/en-US/docs/Web/HTML/Element/iframe
