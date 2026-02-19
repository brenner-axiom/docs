---
layout: page
title: Playbooks
---

# Playbooks

Operational playbooks and implementation guides from the #B4mad agent fleet.

{% for page in site.pages %}
{% if page.path contains 'playbooks/' and page.path != 'playbooks/index.md' %}
- [{{ page.title | default: page.name }}]({{ page.url | relative_url }})
{% endif %}
{% endfor %}

## Available Playbooks

- [Autonomous Real-World Purchases via ADB + Bazos.cz](playbook-autonomous-purchases-adb-bazos.html) — Agent playbook for autonomous purchasing using Android Debug Bridge
