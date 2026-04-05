(function (root) {
  var CATALOG_URL = "https://raw.githubusercontent.com/hasit/apfeller-apps/main/catalog/latest.tsv";
  var APPS_REPO_URL = "https://github.com/hasit/apfeller-apps";
  var APP_SOURCE_BASE_URL = "https://github.com/hasit/apfeller-apps/tree/main/apps/";
  var APP_MANIFEST_BASE_URL = "https://raw.githubusercontent.com/hasit/apfeller-apps/main/apps/";
  var RELEASES_API_URL = "https://api.github.com/repos/hasit/apfeller-apps/releases?per_page=100";

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

  function nextExpandedCardId(currentId, targetId) {
    if (currentId === targetId) {
      return "";
    }

    return targetId;
  }

  function renderPills(values) {
    if (!values.length) {
      return "<span class=\"catalog-pill\">none</span>";
    }

    return values.map(function (value) {
      return "<span class=\"catalog-pill\">" + escapeHtml(value) + "</span>";
    }).join("");
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

  function renderCollapsedCardMarkup(row) {
    var downloads = row.downloads > 0
      ? "<span class=\"catalog-downloads\">" + escapeHtml(formatDownloads(row.downloads)) + "</span>"
      : "";

    return (
      "<div class=\"catalog-card-top\">" +
      "<div class=\"catalog-title-row\">" +
      "<h3>" + escapeHtml(row.id) + "</h3>" +
      "<div class=\"catalog-title-side\">" +
      "<code class=\"catalog-command\">" + escapeHtml(row.command) + "</code>" +
      "<span class=\"catalog-chevron\" aria-hidden=\"true\">▾</span>" +
      "</div>" +
      "</div>" +
      downloads +
      "</div>" +
      "<p class=\"catalog-summary\">" + escapeHtml(row.summary) + "</p>" +
      "<div class=\"catalog-meta\">" +
      "<div class=\"catalog-meta-block\">" +
      "<span class=\"catalog-meta-label\">Requires</span>" +
      "<span class=\"catalog-pills\">" + renderPills(splitCsv(row.requires)) + "</span>" +
      "</div>" +
      "<div class=\"catalog-meta-block\">" +
      "<span class=\"catalog-meta-label\">Shells</span>" +
      "<span class=\"catalog-pills\">" + renderPills(splitCsv(row.supported_shells)) + "</span>" +
      "</div>" +
      "</div>"
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
      "<span class=\"catalog-pills\">" + renderPills(requires) + "</span>" +
      "</div>" +
      "<div class=\"catalog-detail-block\">" +
      "<span class=\"catalog-detail-label\">Shells</span>" +
      "<span class=\"catalog-pills\">" + renderPills(shells) + "</span>" +
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
      "</div>" +
      "<p class=\"catalog-detail-empty\">Could not load the full app manifest right now.</p>" +
      "<p class=\"catalog-detail-source\">Open the source for usage, examples, and app flags: <a href=\"" + sourceUrl + "\">apps/" + escapeHtml(row.id) + "</a></p>" +
      "</div>"
    );
  }

  function renderEmpty(gridNode) {
    gridNode.innerHTML =
      "<section class=\"catalog-empty\">" +
      "<h3>No apps are currently published.</h3>" +
      "<p>Check the raw catalog or browse apfeller-apps for the latest source.</p>" +
      "<p><a href=\"" + CATALOG_URL + "\">Open raw catalog</a> | <a href=\"" + APPS_REPO_URL + "\">Browse apfeller-apps</a></p>" +
      "</section>";
  }

  function renderFailure(gridNode) {
    gridNode.innerHTML =
      "<section class=\"catalog-empty\">" +
      "<h3>Could not load the published catalog.</h3>" +
      "<p>Try the raw catalog directly or browse apfeller-apps.</p>" +
      "<p><a href=\"" + CATALOG_URL + "\">Open raw catalog</a> | <a href=\"" + APPS_REPO_URL + "\">Browse apfeller-apps</a></p>" +
      "</section>";
  }

  function loadDownloadIndex(fetchFn) {
    return fetchFn(RELEASES_API_URL, { cache: "no-store" })
      .then(function (response) {
        if (!response.ok) {
          return {};
        }
        return response.json();
      })
      .then(function (releases) {
        var index = {};

        if (!Array.isArray(releases)) {
          return index;
        }

        releases.forEach(function (release) {
          var tagName = release && release.tag_name;
          if (!tagName || !Array.isArray(release.assets)) {
            return;
          }

          release.assets.forEach(function (asset) {
            if (!asset || !asset.name || typeof asset.download_count !== "number") {
              return;
            }
            index[tagName + "/" + asset.name] = asset.download_count;
          });
        });

        return index;
      })
      .catch(function () {
        return {};
      });
  }

  function createCatalogApp(env) {
    var documentRef = env.document;
    var fetchFn = env.fetch;
    var statusNode = env.statusNode;
    var gridNode = env.gridNode;
    var detailCache = Object.create(null);
    var expandedCard = null;
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

    function collapseCard(card) {
      var button = card.querySelector(".catalog-card-toggle");
      var details = card.querySelector(".catalog-card-details");
      var row = card.__catalogRow;

      button.setAttribute("aria-expanded", "false");
      button.setAttribute("aria-label", "Show details for " + row.id);
      card.removeAttribute("data-expanded");
      details.hidden = true;
      details.innerHTML = "";
      details.removeAttribute("data-detail-token");
    }

    function expandCard(card) {
      var button = card.querySelector(".catalog-card-toggle");
      var details = card.querySelector(".catalog-card-details");
      var row = card.__catalogRow;
      var sourceUrl = sourceUrlForRow(row);
      var token = String(detailToken += 1);

      button.setAttribute("aria-expanded", "true");
      button.setAttribute("aria-label", "Hide details for " + row.id);
      card.setAttribute("data-expanded", "true");
      details.hidden = false;
      details.setAttribute("data-detail-token", token);
      details.innerHTML = "<p class=\"catalog-detail-loading\">Loading details...</p>";

      loadAppDetails(row).then(function (manifest) {
        if (details.getAttribute("data-detail-token") !== token) {
          return;
        }

        if (manifest) {
          details.innerHTML = renderDetailMarkup(row, manifest, sourceUrl);
        } else {
          details.innerHTML = renderFallbackDetailMarkup(row, sourceUrl);
        }
      });
    }

    function toggleCard(card) {
      var currentId = expandedCard ? expandedCard.getAttribute("data-app-id") : "";
      var targetId = card.getAttribute("data-app-id");
      var nextId = nextExpandedCardId(currentId, targetId);

      if (!nextId) {
        collapseCard(card);
        expandedCard = null;
        return;
      }

      if (expandedCard && expandedCard !== card) {
        collapseCard(expandedCard);
      }

      expandCard(card);
      expandedCard = card;
    }

    function createCard(row) {
      var article = documentRef.createElement("article");
      var sourceUrl = sourceUrlForRow(row);
      var detailId = detailIdForRow(row);
      var button;

      article.className = "catalog-card";
      article.setAttribute("data-app-id", row.id);
      article.__catalogRow = row;
      article.innerHTML =
        "<button class=\"catalog-card-toggle\" type=\"button\" aria-expanded=\"false\" aria-controls=\"" + detailId + "\" aria-label=\"Show details for " + escapeHtml(row.id) + "\">" +
        renderCollapsedCardMarkup(row) +
        "</button>" +
        "<div class=\"catalog-card-footer\">" +
        "<a class=\"catalog-source-link\" href=\"" + sourceUrl + "\">Source</a>" +
        "</div>" +
        "<div class=\"catalog-card-details\" id=\"" + detailId + "\" hidden></div>";

      button = article.querySelector(".catalog-card-toggle");
      button.addEventListener("click", function () {
        toggleCard(article);
      });

      return article;
    }

    function renderCatalog(rows) {
      expandedCard = null;
      gridNode.innerHTML = "";
      rows.forEach(function (row) {
        gridNode.appendChild(createCard(row));
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
            renderEmpty(gridNode);
            return null;
          }

          return loadDownloadIndex(fetchFn).then(function (downloadIndex) {
            rows.forEach(function (row) {
              var tag = row.id + "-" + row.revision;
              var assetName = decodeURIComponent(row.bundle_url.split("/").pop() || "");
              var key = tag + "/" + assetName;
              row.downloads = downloadIndex[key];
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
          renderFailure(gridNode);
        });
    }

    return {
      start: start
    };
  }

  root.ApfellerCatalog = {
    parseCatalog: parseCatalog,
    parseAppManifest: parseAppManifest,
    buildBuiltinFlags: buildBuiltinFlags,
    nextExpandedCardId: nextExpandedCardId,
    renderCollapsedCardMarkup: renderCollapsedCardMarkup,
    renderDetailMarkup: renderDetailMarkup,
    renderFallbackDetailMarkup: renderFallbackDetailMarkup,
    createCatalogApp: createCatalogApp,
    constants: {
      CATALOG_URL: CATALOG_URL,
      APP_SOURCE_BASE_URL: APP_SOURCE_BASE_URL,
      APP_MANIFEST_BASE_URL: APP_MANIFEST_BASE_URL,
      RELEASES_API_URL: RELEASES_API_URL
    }
  };

  if (!root.document || !root.fetch) {
    return;
  }

  var statusNode = root.document.getElementById("catalog-status");
  var gridNode = root.document.getElementById("catalog-grid");

  if (!statusNode || !gridNode) {
    return;
  }

  createCatalogApp({
    document: root.document,
    fetch: root.fetch.bind(root),
    statusNode: statusNode,
    gridNode: gridNode
  }).start();
}(typeof window !== "undefined" ? window : globalThis));
