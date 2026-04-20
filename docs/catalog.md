---
layout: default
title: Catalog
description: Browse the currently published apfeller apps, inspect install details, and copy example commands.
permalink: /catalog/
page_id: catalog
---

<link rel="stylesheet" href="../assets/catalog.css">

# Catalog

This page shows the apps that are installable right now. It loads the published catalog from `hasit/apfeller-apps`, so newly published apps appear here without editing this site.

<div class="button-row">
  <a class="button-link button-link-primary" href="../install/">install apfeller</a>
  <a class="button-link" href="https://raw.githubusercontent.com/hasit/apfeller-apps/main/catalog/latest.tsv">open raw catalog</a>
</div>

<p class="small-note">Select an app row to see install details, examples, and flags below. Install <code>apfeller</code> first, then pick an app and run <code>apfeller install &lt;app&gt;</code>.</p>

## Published Apps

<p class="catalog-status" id="catalog-status">Loading current catalog...</p>
<div class="catalog-grid" id="catalog-grid"></div>
<noscript>
  <p>
    This page needs JavaScript to load the live catalog. You can open the
    <a href="https://raw.githubusercontent.com/hasit/apfeller-apps/main/catalog/latest.tsv">raw catalog</a>
    or browse
    <a href="https://github.com/hasit/apfeller-apps">apfeller-apps</a>
    directly.
  </p>
</noscript>

<script src="../assets/catalog.js"></script>

## Guides

- [Install apfeller](../install/)
- [Browse the catalog](../catalog/)
- [Use apfeller](../usage/)
- [Write an app](../write-an-app/)
