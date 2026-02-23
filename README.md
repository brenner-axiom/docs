# #B4mad Documentation

Public documentation for #B4mad Industries' AI agent infrastructure.

## Contents

- [Beads Technical Guide](beads-technical-guide.md) — Multi-agent task coordination architecture using [Beads](https://github.com/steveyegge/beads)
- [Beads Business Value](beads-business-value.md) — Why distributed task tracking matters for AI agent fleets

## About

#B4mad Industries builds decentralized, agent-first infrastructure powered by open source.

- **Open Standards** over walled gardens
- **Privacy-by-Design** over surveillance capitalism  
- **Community** over corporate control

Learn more: https://görn.name/

## Containerized Hugo Build Pipeline

This project uses a containerized Hugo environment for building and serving the documentation site. This ensures a consistent build environment across development and deployment.

### Prerequisites

- [Podman](https://podman.io/) (or Docker, though Podman is preferred)

### Local Development

To serve the site locally for development:

1.  Navigate to the root of the repository.
2.  Run the local server script:
    ```bash
    ./scripts/serve.sh
    ```
    The site will be available at `http://localhost:1313`.

### Building the Site

To build the static site:

1.  Navigate to the root of the repository.
2.  Run the build script:
    ```bash
    ./scripts/build.sh
    ```
    The static files will be generated in the `public/` directory.

    **Base URL Configuration**:
    The `build.sh` script supports configuring the `baseURL` for Hugo. You can set the `HUGO_BASE_URL` environment variable before running the script. For example:
    ```bash
    HUGO_BASE_URL="https://your-domain.com/" ./scripts/build.sh
    ```
    If `HUGO_BASE_URL` is not set, the site will be built with relative URLs.

### GitHub Actions Deployment

The `.github/workflows/hugo-deploy.yml` workflow automates the build and deployment process to GitHub Pages on every push to the `main` branch.

The workflow performs the following steps:
1.  Checks out the repository.
2.  Sets up Node.js (for potential future use with frontend tooling).
3.  Installs Podman.
4.  Pulls the `codeberg.org/b4mad/hugo:v1.147.2` container image.
5.  Builds the Hugo site using `scripts/build.sh`. The `baseURL` for the GitHub Pages deployment is automatically configured by the workflow.
6.  Uploads the built `public/` directory as an artifact.
7.  Deploys the artifact to GitHub Pages.

This workflow replaces any previous Jekyll-based deployment.
Test modification for Radicle patch
Additional test content for documentation
