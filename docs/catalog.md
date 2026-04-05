---
title: Catalog
permalink: /catalog/
---

<link rel="stylesheet" href="../assets/catalog.css">

# Catalog

This page shows the apps that are installable right now. It loads the published
catalog from `hasit/apfeller-apps`, so newly published apps appear here without
editing this site.

Install `apfeller` first, then pick an app below and run
`apfeller install <app>`.

## Guides

- [Install](../install/)
- [Catalog](../catalog/)
- [Use apfeller](../usage/)
- [Write an app](../write-an-app/)

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
