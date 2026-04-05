(function (root) {
  var CATALOG_URL = "https://raw.githubusercontent.com/hasit/apfeller-apps/main/catalog/latest.tsv";
  var APPS_REPO_URL = "https://github.com/hasit/apfeller-apps";
  var APP_SOURCE_BASE_URL = "https://github.com/hasit/apfeller-apps/tree/main/apps/";
  var APP_MANIFEST_BASE_URL = "https://raw.githubusercontent.com/hasit/apfeller-apps/main/apps/";
  var RELEASES_API_URL = "https://api.github.com/repos/hasit/apfeller-apps/releases?per_page=100";
  var TABLE_COLUMN_COUNT = 7;

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

  function formatDownloads(value) {
    if (typeof value !== "number") {
      return "";
    }

    if (value === 1) {
      return "1 download";
    }

    return value.toLocaleString("en-US") + " downloads";
  }

  function appIdFromReleaseTag(tagName) {
    var separatorIndex;

    if (!tagName) {
      return "";
    }

    separatorIndex = tagName.lastIndexOf("-");
    if (separatorIndex <= 0) {
      return "";
    }

    return tagName.slice(0, separatorIndex);
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

  function parseTomlString(raw) {
    var quote = raw.charAt(0);
    var body = raw.slice(1, -1);

    if (quote === "'") {
      return body;
    }

    return body.replace(/\\(["\\bfnrt])/g, function (_, escaped) {
      switch (escaped) {
        case "b":
          return "\b";
        case "f":
          return "\f";
        case "n":
          return "\n";
        case "r":
          return "\r";
        case "t":
          return "\t";
        default:
          return escaped;
      }
    });
  }

  function splitTomlArray(raw) {
    var items = [];
    var current = "";
    var quote = "";
    var escaping = false;
    var index;
    var char;

    for (index = 0; index < raw.length; index += 1) {
      char = raw.charAt(index);

      if (quote) {
        current += char;
        if (escaping) {
          escaping = false;
        } else if (quote === '"' && char === "\\") {
          escaping = true;
        } else if (char === quote) {
          quote = "";
        }
        continue;
      }

      if (char === '"' || char === "'") {
        quote = char;
        current += char;
        continue;
      }

      if (char === ",") {
        if (current.trim()) {
          items.push(current.trim());
        }
        current = "";
        continue;
      }

      current += char;
    }

    if (current.trim()) {
      items.push(current.trim());
    }

    return items;
  }

  function parseTomlValue(raw) {
    var value = raw.trim();

    if (!value) {
      return "";
    }

    if ((value.charAt(0) === '"' && value.charAt(value.length - 1) === '"') ||
        (value.charAt(0) === "'" && value.charAt(value.length - 1) === "'")) {
      return parseTomlString(value);
    }

    if (value.charAt(0) === "[" && value.charAt(value.length - 1) === "]") {
      return splitTomlArray(value.slice(1, -1)).map(parseTomlValue);
    }

    if (value === "true") {
      return true;
    }

    if (value === "false") {
      return false;
    }

    if (/^-?\d+$/.test(value)) {
      return parseInt(value, 10);
    }

    return value;
  }

  function parseAppManifest(text) {
    var manifest = {
      args: [],
      help: {},
      input: {},
      output: {}
    };
    var currentSection = "";
    var currentArg = null;

    text.split(/\r?\n/).forEach(function (line) {
      var trimmed = line.trim();
      var match;
      var key;
      var value;

      if (!trimmed || trimmed.charAt(0) === "#") {
        return;
      }

      if (trimmed === "[[args]]") {
        currentArg = {};
        manifest.args.push(currentArg);
        currentSection = "args";
        return;
      }

      match = trimmed.match(/^\[([a-z_]+)\]$/i);
      if (match) {
        currentSection = match[1];
        currentArg = null;
        if (!manifest[currentSection]) {
          manifest[currentSection] = {};
        }
        return;
      }

      match = trimmed.match(/^([A-Za-z0-9_]+)\s*=\s*(.+)$/);
      if (!match) {
        return;
      }

      key = match[1];
      value = parseTomlValue(match[2]);

      if (currentSection === "args" && currentArg) {
        currentArg[key] = value;
        return;
      }

      if (currentSection) {
        manifest[currentSection][key] = value;
        return;
      }

      manifest[key] = value;
    });

    return manifest;
  }

  function buildBuiltinFlags(outputMode) {
    var flags = [
      {
        signature: "-h, --help",
        description: "Show this help"
      }
    ];

    switch (outputMode) {
      case "shell_command":
        flags.push({
          signature: "-c, --copy",
          description: "Copy the generated command to the clipboard"
        });
        flags.push({
          signature: "-x, --execute",
          description: "Run the generated command after confirmation"
        });
        break;
      case "text":
      case "structured_text":
        flags.push({
          signature: "-c, --copy",
          description: "Copy the response to the clipboard"
        });
        break;
    }

    return flags;
  }

  function nextExpandedRowId(currentId, targetId) {
    if (currentId === targetId) {
      return "";
    }

    return targetId;
  }

  function detailIdForRow(row) {
    return "catalog-details-" + String(row.id).replace(/[^A-Za-z0-9_-]/g, "-");
  }

  function sourceUrlForRow(row) {
    return APP_SOURCE_BASE_URL + encodeURIComponent(row.id);
  }

  function manifestUrlForRow(row) {
    return APP_MANIFEST_BASE_URL + encodeURIComponent(row.id) + "/app.toml";
  }

  function renderInlineList(values) {
    return escapeHtml(values.length ? values.join(", ") : "none");
  }

  function renderTableHeaderMarkup() {
    return (
      "<thead>" +
      "<tr>" +
      "<th scope=\"col\" class=\"catalog-col-app\">App</th>" +
      "<th scope=\"col\" class=\"catalog-col-command\">Command</th>" +
      "<th scope=\"col\" class=\"catalog-col-summary\">Summary</th>" +
      "<th scope=\"col\" class=\"catalog-col-requires\">Requires</th>" +
      "<th scope=\"col\" class=\"catalog-col-shells\">Shells</th>" +
      "<th scope=\"col\" class=\"catalog-col-downloads\">Downloads</th>" +
      "<th scope=\"col\" class=\"catalog-col-source\">Source</th>" +
      "</tr>" +
      "</thead>"
    );
  }

  function renderSummaryRowCellsMarkup(row) {
    var detailId = detailIdForRow(row);
    var downloads = row.downloads > 0 ? escapeHtml(formatDownloads(row.downloads)) : "";

    return (
      "<td class=\"catalog-col-app\">" +
      "<button class=\"catalog-row-toggle\" type=\"button\" aria-expanded=\"false\" aria-controls=\"" + detailId + "\" aria-label=\"Show details for " + escapeHtml(row.id) + "\">" +
      "<span class=\"catalog-chevron\" aria-hidden=\"true\">▾</span>" +
      "<span class=\"catalog-app-name\">" + escapeHtml(row.id) + "</span>" +
      "</button>" +
      "</td>" +
      "<td class=\"catalog-col-command\"><code class=\"catalog-command\">" + escapeHtml(row.command) + "</code></td>" +
      "<td class=\"catalog-col-summary\"><span class=\"catalog-summary\" title=\"" + escapeHtml(row.summary) + "\">" + escapeHtml(row.summary) + "</span></td>" +
      "<td class=\"catalog-col-requires\"><span class=\"catalog-inline-list\">" + renderInlineList(splitCsv(row.requires)) + "</span></td>" +
      "<td class=\"catalog-col-shells\"><span class=\"catalog-inline-list\">" + renderInlineList(splitCsv(row.supported_shells)) + "</span></td>" +
      "<td class=\"catalog-col-downloads\">" + (downloads ? "<span class=\"catalog-downloads\">" + downloads + "</span>" : "") + "</td>" +
      "<td class=\"catalog-col-source\"><a class=\"catalog-source-link\" href=\"" + sourceUrlForRow(row) + "\">Source</a></td>"
    );
  }

  function renderDetailRowCellsMarkup(detailMarkup) {
    return (
      "<td colspan=\"" + TABLE_COLUMN_COUNT + "\">" +
      "<div class=\"catalog-detail-inner\">" + detailMarkup + "</div>" +
      "</td>"
    );
  }

  function renderDetailRowMarkup(detailId, detailMarkup) {
    return (
      "<tr class=\"catalog-detail-row\" id=\"" + detailId + "\">" +
      renderDetailRowCellsMarkup(detailMarkup) +
      "</tr>"
    );
  }

  function formatOptionDefault(option) {
    if (typeof option.default === "undefined" || option.default === "" || option.default === null) {
      return "";
    }

    if (option.type === "flag") {
      return option.default === 1 || option.default === true ? "on" : "off";
    }

    return String(option.default);
  }

  function renderOptionSignature(option) {
    var names = [];
    var suffix = "";

    if (option.short) {
      names.push("-" + option.short);
    }

    if (option.long) {
      names.push("--" + option.long);
    }

    if (option.type && option.type !== "flag") {
      if (option.type === "integer") {
        suffix = " <integer>";
      } else {
        suffix = " <value>";
      }
    }

    return names.join(", ") + suffix;
  }

  function renderFlagListMarkup(flags) {
    return (
      "<ul class=\"catalog-option-list\">" +
      flags.map(function (flag) {
        var meta = [];

        if (flag.type) {
          meta.push(flag.type);
        }

        if (typeof flag.default !== "undefined" && flag.default !== "" && flag.default !== null) {
          meta.push("default: " + formatOptionDefault(flag));
        }

        if (Array.isArray(flag.choices) && flag.choices.length) {
          meta.push("choices: " + flag.choices.join(", "));
        }

        return (
          "<li class=\"catalog-option-item\">" +
          "<code class=\"catalog-option-signature\">" + escapeHtml(flag.signature) + "</code>" +
          "<div class=\"catalog-option-copy\">" +
          "<p class=\"catalog-option-description\">" + escapeHtml(flag.description || "") + "</p>" +
          (meta.length ? "<p class=\"catalog-option-meta\">" + escapeHtml(meta.join(" · ")) + "</p>" : "") +
          "</div>" +
          "</li>"
        );
      }).join("") +
      "</ul>"
    );
  }

  function renderExamplesMarkup(examples) {
    if (!examples.length) {
      return "<p class=\"catalog-detail-empty\">No examples listed.</p>";
    }

    return (
      "<ul class=\"catalog-example-list\">" +
      examples.map(function (example) {
        return "<li><code>" + escapeHtml(example) + "</code></li>";
      }).join("") +
      "</ul>"
    );
  }

  function renderDetailMarkup(row, manifest, sourceUrl) {
    var requires = Array.isArray(manifest.requires_commands) && manifest.requires_commands.length
      ? manifest.requires_commands
      : splitCsv(row.requires);
    var shells = Array.isArray(manifest.supported_shells) && manifest.supported_shells.length
      ? manifest.supported_shells
      : splitCsv(row.supported_shells);
    var description = manifest.description || row.description;
    var usage = manifest.help && manifest.help.usage ? manifest.help.usage : "";
    var examples = manifest.help && Array.isArray(manifest.help.examples) ? manifest.help.examples : [];
    var outputMode = manifest.output && manifest.output.mode ? manifest.output.mode : "";
    var builtinFlags = buildBuiltinFlags(outputMode);
    var appFlags = (manifest.args || []).map(function (arg) {
      return {
        signature: renderOptionSignature(arg),
        description: arg.description || "",
        type: arg.type || "",
        default: arg.default,
        choices: arg.choices || []
      };
    });

    return (
      "<div class=\"catalog-detail-panel\">" +
      "<p class=\"catalog-detail-description\">" + escapeHtml(description) + "</p>" +
      "<div class=\"catalog-detail-grid\">" +
      "<div class=\"catalog-detail-block\">" +
      "<span class=\"catalog-detail-label\">Install</span>" +
      "<code class=\"catalog-detail-code\">apfeller install " + escapeHtml(row.id) + "</code>" +
      "</div>" +
      (usage ? (
        "<div class=\"catalog-detail-block\">" +
        "<span class=\"catalog-detail-label\">Usage</span>" +
        "<code class=\"catalog-detail-code\">" + escapeHtml(usage) + "</code>" +
        "</div>"
      ) : "") +
      "<div class=\"catalog-detail-block\">" +
      "<span class=\"catalog-detail-label\">Kind</span>" +
      "<span class=\"catalog-detail-value\">" + escapeHtml((manifest.kind || row.kind) + (outputMode ? " · " + outputMode : "")) + "</span>" +
      "</div>" +
      "<div class=\"catalog-detail-block\">" +
      "<span class=\"catalog-detail-label\">Requires</span>" +
      "<span class=\"catalog-detail-value\">" + renderInlineList(requires) + "</span>" +
      "</div>" +
      "<div class=\"catalog-detail-block\">" +
      "<span class=\"catalog-detail-label\">Shells</span>" +
      "<span class=\"catalog-detail-value\">" + renderInlineList(shells) + "</span>" +
      "</div>" +
      "</div>" +
      "<div class=\"catalog-detail-section\">" +
      "<span class=\"catalog-detail-label\">Examples</span>" +
      renderExamplesMarkup(examples) +
      "</div>" +
      "<div class=\"catalog-detail-section\">" +
      "<span class=\"catalog-detail-label\">Built-in flags</span>" +
      renderFlagListMarkup(builtinFlags) +
      "</div>" +
      "<div class=\"catalog-detail-section\">" +
      "<span class=\"catalog-detail-label\">App flags</span>" +
      (appFlags.length
        ? renderFlagListMarkup(appFlags)
        : "<p class=\"catalog-detail-empty\">No app-specific flags.</p>") +
      "</div>" +
      "<p class=\"catalog-detail-source\">More detail: <a href=\"" + sourceUrl + "\">apps/" + escapeHtml(row.id) + "</a></p>" +
      "</div>"
    );
  }

  function renderFallbackDetailMarkup(row, sourceUrl) {
    return (
      "<div class=\"catalog-detail-panel\">" +
      "<p class=\"catalog-detail-description\">" + escapeHtml(row.description) + "</p>" +
      "<div class=\"catalog-detail-grid\">" +
      "<div class=\"catalog-detail-block\">" +
      "<span class=\"catalog-detail-label\">Install</span>" +
      "<code class=\"catalog-detail-code\">apfeller install " + escapeHtml(row.id) + "</code>" +
      "</div>" +
      "<div class=\"catalog-detail-block\">" +
      "<span class=\"catalog-detail-label\">Requires</span>" +
      "<span class=\"catalog-detail-value\">" + renderInlineList(splitCsv(row.requires)) + "</span>" +
      "</div>" +
      "<div class=\"catalog-detail-block\">" +
      "<span class=\"catalog-detail-label\">Shells</span>" +
      "<span class=\"catalog-detail-value\">" + renderInlineList(splitCsv(row.supported_shells)) + "</span>" +
      "</div>" +
      "</div>" +
      "<p class=\"catalog-detail-empty\">Could not load the full app manifest right now.</p>" +
      "<p class=\"catalog-detail-source\">Open the source for usage, examples, and app flags: <a href=\"" + sourceUrl + "\">apps/" + escapeHtml(row.id) + "</a></p>" +
      "</div>"
    );
  }

  function renderEmpty(hostNode) {
    hostNode.innerHTML =
      "<section class=\"catalog-empty\">" +
      "<h3>No apps are currently published.</h3>" +
      "<p>Check the raw catalog or browse apfeller-apps for the latest source.</p>" +
      "<p><a href=\"" + CATALOG_URL + "\">Open raw catalog</a> | <a href=\"" + APPS_REPO_URL + "\">Browse apfeller-apps</a></p>" +
      "</section>";
  }

  function renderFailure(hostNode) {
    hostNode.innerHTML =
      "<section class=\"catalog-empty\">" +
      "<h3>Could not load the published catalog.</h3>" +
      "<p>Try the raw catalog directly or browse apfeller-apps.</p>" +
      "<p><a href=\"" + CATALOG_URL + "\">Open raw catalog</a> | <a href=\"" + APPS_REPO_URL + "\">Browse apfeller-apps</a></p>" +
      "</section>";
  }

  function buildDownloadTotals(releases) {
    var totals = {};

    if (!Array.isArray(releases)) {
      return totals;
    }

    releases.forEach(function (release) {
      var tagName = release && release.tag_name;
      var appId = appIdFromReleaseTag(tagName);
      var expectedAssetName;

      if (!appId || !Array.isArray(release.assets)) {
        return;
      }

      expectedAssetName = tagName + ".tar.gz";

      release.assets.forEach(function (asset) {
        if (!asset || asset.name !== expectedAssetName || typeof asset.download_count !== "number") {
          return;
        }

        totals[appId] = (totals[appId] || 0) + asset.download_count;
      });
    });

    return totals;
  }

  function loadDownloadTotals(fetchFn) {
    return fetchFn(RELEASES_API_URL, { cache: "no-store" })
      .then(function (response) {
        if (!response.ok) {
          return {};
        }
        return response.json();
      })
      .then(function (releases) {
        return buildDownloadTotals(releases);
      })
      .catch(function () {
        return {};
      });
  }

  function createCatalogApp(env) {
    var documentRef = env.document;
    var fetchFn = env.fetch;
    var statusNode = env.statusNode;
    var hostNode = env.hostNode;
    var detailCache = Object.create(null);
    var expandedId = "";
    var expandedSummaryRow = null;
    var expandedDetailRow = null;
    var detailToken = 0;

    function setStatus(message, state) {
      statusNode.textContent = message;
      statusNode.hidden = !message;
      if (state) {
        statusNode.setAttribute("data-state", state);
      } else {
        statusNode.removeAttribute("data-state");
      }
    }

    function loadAppDetails(row) {
      if (detailCache[row.id]) {
        return detailCache[row.id];
      }

      detailCache[row.id] = fetchFn(manifestUrlForRow(row), { cache: "no-store" })
        .then(function (response) {
          if (!response.ok) {
            return null;
          }
          return response.text();
        })
        .then(function (text) {
          if (!text) {
            return null;
          }

          try {
            return parseAppManifest(text);
          } catch (error) {
            return null;
          }
        })
        .catch(function () {
          return null;
        });

      return detailCache[row.id];
    }

    function setSummaryExpandedState(summaryRow, isExpanded) {
      var toggle = summaryRow.querySelector(".catalog-row-toggle");
      var row = summaryRow.__catalogRow;

      if (isExpanded) {
        summaryRow.setAttribute("data-expanded", "true");
        toggle.setAttribute("aria-expanded", "true");
        toggle.setAttribute("aria-label", "Hide details for " + row.id);
      } else {
        summaryRow.removeAttribute("data-expanded");
        toggle.setAttribute("aria-expanded", "false");
        toggle.setAttribute("aria-label", "Show details for " + row.id);
      }
    }

    function removeExpandedRow() {
      if (expandedSummaryRow) {
        setSummaryExpandedState(expandedSummaryRow, false);
      }

      if (expandedDetailRow && expandedDetailRow.parentNode) {
        expandedDetailRow.parentNode.removeChild(expandedDetailRow);
      }

      expandedId = "";
      expandedSummaryRow = null;
      expandedDetailRow = null;
    }

    function createDetailRow(row, detailMarkup) {
      var detailRow = documentRef.createElement("tr");
      detailRow.className = "catalog-detail-row";
      detailRow.id = detailIdForRow(row);
      detailRow.innerHTML = renderDetailRowCellsMarkup(detailMarkup);
      return detailRow;
    }

    function expandSummaryRow(summaryRow) {
      var row = summaryRow.__catalogRow;
      var sourceUrl = sourceUrlForRow(row);
      var token = String(detailToken += 1);

      if (expandedSummaryRow && expandedSummaryRow !== summaryRow) {
        removeExpandedRow();
      }

      setSummaryExpandedState(summaryRow, true);
      expandedId = row.id;
      expandedSummaryRow = summaryRow;
      expandedDetailRow = createDetailRow(row, "<p class=\"catalog-detail-loading\">Loading details...</p>");
      expandedDetailRow.setAttribute("data-detail-token", token);
      summaryRow.parentNode.insertBefore(expandedDetailRow, summaryRow.nextSibling);

      loadAppDetails(row).then(function (manifest) {
        var detailMarkup;

        if (!expandedDetailRow || expandedId !== row.id || expandedDetailRow.getAttribute("data-detail-token") !== token) {
          return;
        }

        if (manifest) {
          detailMarkup = renderDetailMarkup(row, manifest, sourceUrl);
        } else {
          detailMarkup = renderFallbackDetailMarkup(row, sourceUrl);
        }

        expandedDetailRow.innerHTML = renderDetailRowCellsMarkup(detailMarkup);
      });
    }

    function toggleSummaryRow(summaryRow) {
      var nextId = nextExpandedRowId(expandedId, summaryRow.getAttribute("data-app-id"));

      if (!nextId) {
        removeExpandedRow();
        return;
      }

      expandSummaryRow(summaryRow);
    }

    function createSummaryRow(row) {
      var summaryRow = documentRef.createElement("tr");
      var toggle;
      var sourceLink;

      summaryRow.className = "catalog-row";
      summaryRow.setAttribute("data-app-id", row.id);
      summaryRow.__catalogRow = row;
      summaryRow.innerHTML = renderSummaryRowCellsMarkup(row);

      toggle = summaryRow.querySelector(".catalog-row-toggle");
      sourceLink = summaryRow.querySelector(".catalog-source-link");

      toggle.addEventListener("click", function (event) {
        event.stopPropagation();
        toggleSummaryRow(summaryRow);
      });

      if (sourceLink) {
        sourceLink.addEventListener("click", function (event) {
          event.stopPropagation();
        });
      }

      summaryRow.addEventListener("click", function (event) {
        if (event.target && event.target.closest && event.target.closest("a,button")) {
          return;
        }
        toggleSummaryRow(summaryRow);
      });

      return summaryRow;
    }

    function renderCatalog(rows) {
      var tbody;

      removeExpandedRow();
      hostNode.innerHTML =
        "<div class=\"catalog-table-shell\">" +
        "<div class=\"catalog-table-frame\">" +
        "<table class=\"catalog-table\">" +
        renderTableHeaderMarkup() +
        "<tbody></tbody>" +
        "</table>" +
        "</div>" +
        "</div>";

      tbody = hostNode.querySelector("tbody");
      rows.forEach(function (row) {
        tbody.appendChild(createSummaryRow(row));
      });
    }

    function start() {
      setStatus("Loading current catalog...");

      return fetchFn(CATALOG_URL, { cache: "no-store" })
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
            renderEmpty(hostNode);
            return null;
          }

          return loadDownloadTotals(fetchFn).then(function (downloadTotals) {
            rows.forEach(function (row) {
              row.downloads = downloadTotals[row.id] || 0;
            });
            return rows;
          });
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
          renderFailure(hostNode);
        });
    }

    return {
      start: start
    };
  }

  root.ApfellerCatalog = {
    parseCatalog: parseCatalog,
    parseAppManifest: parseAppManifest,
    buildDownloadTotals: buildDownloadTotals,
    buildBuiltinFlags: buildBuiltinFlags,
    nextExpandedRowId: nextExpandedRowId,
    renderTableHeaderMarkup: renderTableHeaderMarkup,
    renderSummaryRowCellsMarkup: renderSummaryRowCellsMarkup,
    renderDetailRowMarkup: renderDetailRowMarkup,
    renderDetailMarkup: renderDetailMarkup,
    renderFallbackDetailMarkup: renderFallbackDetailMarkup,
    createCatalogApp: createCatalogApp,
    constants: {
      CATALOG_URL: CATALOG_URL,
      APP_SOURCE_BASE_URL: APP_SOURCE_BASE_URL,
      APP_MANIFEST_BASE_URL: APP_MANIFEST_BASE_URL,
      RELEASES_API_URL: RELEASES_API_URL,
      TABLE_COLUMN_COUNT: TABLE_COLUMN_COUNT
    }
  };

  if (!root.document || !root.fetch) {
    return;
  }

  var statusNode = root.document.getElementById("catalog-status");
  var hostNode = root.document.getElementById("catalog-grid");

  if (!statusNode || !hostNode) {
    return;
  }

  createCatalogApp({
    document: root.document,
    fetch: root.fetch.bind(root),
    statusNode: statusNode,
    hostNode: hostNode
  }).start();
}(typeof window !== "undefined" ? window : globalThis));
