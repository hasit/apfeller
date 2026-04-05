(function () {
  var CATALOG_URL = "https://raw.githubusercontent.com/hasit/apfeller-apps/main/catalog/latest.tsv";
  var APPS_REPO_URL = "https://github.com/hasit/apfeller-apps";
  var APP_SOURCE_BASE_URL = "https://github.com/hasit/apfeller-apps/tree/main/apps/";
  var RELEASE_API_BASE_URL = "https://api.github.com/repos/hasit/apfeller-apps/releases/tags/";
  var statusNode = document.getElementById("catalog-status");
  var gridNode = document.getElementById("catalog-grid");

  if (!statusNode || !gridNode) {
    return;
  }

  function escapeHtml(value) {
    return String(value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  function splitCsv(value) {
    if (!value) {
      return [];
    }

    return value.split(",").map(function (item) {
      return item.trim();
    }).filter(Boolean);
  }

  function setStatus(message, state) {
    statusNode.textContent = message;
    statusNode.hidden = !message;
    if (state) {
      statusNode.setAttribute("data-state", state);
    } else {
      statusNode.removeAttribute("data-state");
    }
  }

  function formatDownloads(value) {
    if (typeof value !== "number") {
      return "";
    }

    return value.toLocaleString("en-US") + " downloads";
  }

  function parseCatalog(text) {
    var lines = text.split(/\r?\n/).filter(function (line) {
      return line.trim() !== "";
    });

    if (lines.length <= 1) {
      return [];
    }

    var headers = lines[0].split("\t");
    return lines.slice(1).map(function (line) {
      var values = line.split("\t");
      var row = {};
      headers.forEach(function (header, index) {
        row[header] = values[index] || "";
      });
      return row;
    });
  }

  function renderPills(values) {
    if (!values.length) {
      return "<span class=\"catalog-pill\">none</span>";
    }

    return values.map(function (value) {
      return "<span class=\"catalog-pill\">" + escapeHtml(value) + "</span>";
    }).join("");
  }

  function renderCard(row) {
    var sourceUrl = APP_SOURCE_BASE_URL + encodeURIComponent(row.id);
    var downloads = typeof row.downloads === "number"
      ? "<span class=\"catalog-downloads\">" + escapeHtml(formatDownloads(row.downloads)) + "</span>"
      : "";
    var article = document.createElement("article");
    article.className = "catalog-card";
    article.innerHTML =
      "<div class=\"catalog-card-top\">" +
      "<div class=\"catalog-heading\">" +
      "<h3>" + escapeHtml(row.id) + "</h3>" +
      "<p class=\"catalog-summary\">" + escapeHtml(row.summary) + "</p>" +
      "</div>" +
      "<div class=\"catalog-side\">" +
      "<code class=\"catalog-command\">" + escapeHtml(row.command) + "</code>" +
      downloads +
      "</div>" +
      "</div>" +
      "<p class=\"catalog-description\">" + escapeHtml(row.description) + "</p>" +
      "<div class=\"catalog-meta\">" +
      "<div class=\"catalog-meta-row\"><strong>Requires</strong> <span class=\"catalog-pills\">" + renderPills(splitCsv(row.requires)) + "</span></div>" +
      "<div class=\"catalog-meta-row\"><strong>Shells</strong> <span class=\"catalog-pills\">" + renderPills(splitCsv(row.supported_shells)) + "</span></div>" +
      "<div class=\"catalog-meta-row catalog-install\"><strong>Install</strong> <code>apfeller install " + escapeHtml(row.id) + "</code></div>" +
      "<div class=\"catalog-meta-row\"><strong>Source</strong> <a href=\"" + sourceUrl + "\">apps/" + escapeHtml(row.id) + "</a></div>" +
      "</div>" +
      "";
    return article;
  }

  function renderEmpty() {
    gridNode.innerHTML =
      "<section class=\"catalog-empty\">" +
      "<h3>No apps are currently published.</h3>" +
      "<p>Check the raw catalog or browse apfeller-apps for the latest source.</p>" +
      "<p><a href=\"" + CATALOG_URL + "\">Open raw catalog</a> | <a href=\"" + APPS_REPO_URL + "\">Browse apfeller-apps</a></p>" +
      "</section>";
  }

  function renderFailure() {
    gridNode.innerHTML =
      "<section class=\"catalog-empty\">" +
      "<h3>Could not load the published catalog.</h3>" +
      "<p>Try the raw catalog directly or browse apfeller-apps.</p>" +
      "<p><a href=\"" + CATALOG_URL + "\">Open raw catalog</a> | <a href=\"" + APPS_REPO_URL + "\">Browse apfeller-apps</a></p>" +
      "</section>";
  }

  function renderCatalog(rows) {
    gridNode.innerHTML = "";
    rows.forEach(function (row) {
      gridNode.appendChild(renderCard(row));
    });
  }

  function loadDownloadCount(row) {
    var tag = row.id + "-" + row.revision;
    var assetName = decodeURIComponent(row.bundle_url.split("/").pop() || "");

    return fetch(RELEASE_API_BASE_URL + encodeURIComponent(tag), { cache: "no-store" })
      .then(function (response) {
        if (!response.ok) {
          return null;
        }
        return response.json();
      })
      .then(function (release) {
        var asset;

        if (!release || !release.assets || !release.assets.length) {
          return null;
        }

        asset = release.assets.find(function (entry) {
          return entry && entry.name === assetName;
        }) || release.assets[0];

        if (!asset || typeof asset.download_count !== "number") {
          return null;
        }

        return asset.download_count;
      })
      .catch(function () {
        return null;
      });
  }

  setStatus("Loading current catalog...");

  fetch(CATALOG_URL, { cache: "no-store" })
    .then(function (response) {
      if (!response.ok) {
        throw new Error("catalog fetch failed");
      }
      return response.text();
    })
    .then(function (text) {
      var rows = parseCatalog(text);
      if (!rows.length) {
        setStatus("No published apps were found in the current catalog.");
        renderEmpty();
        return null;
      }

      return Promise.all(rows.map(function (row) {
        return loadDownloadCount(row).then(function (downloads) {
          row.downloads = downloads;
          return row;
        });
      }));
    })
    .then(function (rows) {
      if (!rows) {
        return;
      }

      setStatus("");
      renderCatalog(rows);
    })
    .catch(function () {
      setStatus("Could not load the published catalog.", "error");
      renderFailure();
    });
}());
