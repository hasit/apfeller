---
layout: default
title: apfeller
description: apfeller is a small app manager for local shell apps built around apfel.
permalink: /
page_id: home
section_nav:
  - id: install-once
    label: install
  - id: try-it
    label: try it
  - id: use-this-for
    label: use this for
  - id: how-it-works
    label: how it works
---

<span class="hero-kicker">local shell apps</span>

# apfeller

<p class="hero-lede"><code>apfeller</code> is a small app manager for local shell apps built around <a href="https://apfel.franzai.com/">apfel</a>: install the manager once, browse the catalog, and keep the tools you want fully local with zero API cost.</p>

<div class="command-rail" data-copy-text="curl -fsSL https://raw.githubusercontent.com/hasit/apfeller/main/install.sh | sh">
  <code>curl -fsSL https://raw.githubusercontent.com/hasit/apfeller/main/install.sh | sh</code>
</div>

<div class="hero-actions">
  <a class="button-link button-link-primary" href="catalog/">browse the catalog</a>
  <a class="button-link" href="install/">install guide</a>
  <a class="button-link" href="write-an-app/">write an app</a>
</div>

## Install Once

<div id="install-once"></div>

Run one install command, then use the manager to inspect what is available before you commit to any app.

```sh
curl -fsSL https://raw.githubusercontent.com/hasit/apfeller/main/install.sh | sh
apfeller doctor
apfeller list
apfeller info <app>
apfeller install <app>
```

<p class="small-note">Fish and zsh get shell integration automatically. App-specific requirements still stay visible on the catalog page before you install.</p>

## Try It

<div id="try-it"></div>

<p class="section-lede">The happy path is intentionally short: inspect, install, run, and update from the command line without any hosted control plane.</p>

<div class="feature-grid">
  <section class="feature-card">
    <h3>Inspect what is published</h3>
    <p>Use the catalog or <code>apfeller info &lt;app&gt;</code> to check what command an app provides, which shells it supports, and which local tools it expects.</p>
  </section>
  <section class="feature-card">
    <h3>Install only what you want</h3>
    <p>The manager installs exact app bundles from the published catalog instead of shipping a giant default bundle up front.</p>
  </section>
  <section class="feature-card">
    <h3>Keep usage familiar</h3>
    <p>Installed apps show up as normal shell commands, so the experience stays close to the terminal workflows you already use every day.</p>
  </section>
  <section class="feature-card">
    <h3>Update on your schedule</h3>
    <p>Refresh the manager or your installed apps with explicit commands instead of a background daemon or browser-only UI.</p>
  </section>
</div>

## Use This For

<div id="use-this-for"></div>

<div class="split-layout">
  <section class="split-callout">
    <span class="section-kicker">for everyday use</span>
    <h3>Keep small shell helpers organized</h3>
    <p>Reach for <code>apfeller</code> when you want installable local tools that feel lightweight, discoverable, and easy to keep in sync across machines.</p>
  </section>
  <div class="stack-list">
    <section class="stack-list-item">
      <strong>Personal command sets</strong>
      <p>Ship one focused command at a time without turning your shell profile into a giant pile of custom functions.</p>
    </section>
    <section class="stack-list-item">
      <strong>Local AI helpers</strong>
      <p>Wrap tiny prompts and workflows around <code>apfel</code> while keeping execution fully local on your Mac.</p>
    </section>
    <section class="stack-list-item">
      <strong>Reusable team utilities</strong>
      <p>Package a small command, publish the bundle, and let teammates install it through the same manager instead of hand-copying scripts.</p>
    </section>
  </div>
</div>

## How It Works

<div id="how-it-works"></div>

<div class="summary-grid">
  <section class="note-card">
    <h3>Small manager, live catalog</h3>
    <p>The docs site and <code>apfeller list</code> both point at the published catalog in <a href="https://github.com/hasit/apfeller-apps">hasit/apfeller-apps</a>, so newly released apps can appear without rebuilding this repo.</p>
  </section>
  <section class="note-card">
    <h3>Exact bundle downloads</h3>
    <p>The manager installs the exact app bundle URLs listed in that catalog, which keeps the runtime small and the installation story easy to reason about.</p>
  </section>
  <section class="note-card">
    <h3>Zero API cost</h3>
    <p>The app logic runs locally on your Mac. There is no hosted billing layer, API key setup flow, or cloud round-trip in the manager itself.</p>
  </section>
  <section class="note-card">
    <h3>Authoring stays separate</h3>
    <p>Published app definitions live in the separate <a href="https://github.com/hasit/apfeller-apps">apfeller-apps</a> repo, while this repo stays focused on the manager, packaging helpers, and docs.</p>
  </section>
</div>

## Guides

- [Install apfeller](install/)
- [Browse the catalog](catalog/)
- [Use apfeller](usage/)
- [Write an app](write-an-app/)
