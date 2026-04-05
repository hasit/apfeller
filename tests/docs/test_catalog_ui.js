const fs = require("fs");
const path = require("path");
const vm = require("vm");

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

const rootDir = path.resolve(__dirname, "..", "..");
const scriptSource = fs.readFileSync(path.join(rootDir, "docs/assets/catalog.js"), "utf8");
const sandbox = {
  globalThis: {},
  console: console
};

vm.createContext(sandbox);
vm.runInContext(scriptSource, sandbox);

const api = sandbox.globalThis.ApfellerCatalog;

assert(api, "catalog script should expose test helpers");

const cmdManifest = `
id = "cmd"
summary = "Turn natural language into a shell command."
description = "Generate a single macOS shell command from a natural language request."
command = "cmd"
kind = "ai-command"
requires_commands = ["apfel", "pbcopy"]
supported_shells = ["fish", "zsh"]

[help]
usage = 'cmd [OPTIONS] "what you want to do"'
examples = ['cmd "find all .log files modified today"', 'cmd -x "what process is using port 3000"']

[input]
mode = "rest"
required = true

[output]
mode = "shell_command"
`;

const defineManifest = `
id = "define"
summary = "Define a word or phrase."
description = "Tiny multilingual dictionary lookup."
command = "define"
kind = "ai-text"
requires_commands = ["apfel", "pbcopy"]
supported_shells = ["fish", "zsh"]

[help]
usage = "define [OPTIONS] WORD_OR_PHRASE"
examples = ["define hola", "define -o es resilience"]

[input]
mode = "rest"
required = true

[[args]]
name = "in"
type = "string"
long = "in"
short = "i"
description = "Input language"
default = "auto"

[[args]]
name = "out"
type = "string"
long = "out"
short = "o"
description = "Output language"
default = "en"

[output]
mode = "structured_text"
`;

const gitsumManifest = `
id = "gitsum"
summary = "Summarize recent git activity."
description = "Summarizes recent commits or the current working tree diff."
command = "gitsum"
kind = "ai-text"
requires_commands = ["apfel", "git"]
supported_shells = ["fish", "zsh"]

[help]
usage = "gitsum [OPTIONS]"
examples = ["gitsum", "gitsum -n 20", "gitsum --diff"]

[input]
mode = "none"
required = false

[[args]]
name = "count"
type = "integer"
long = "count"
short = "n"
description = "Number of recent commits to summarize"
default = 10

[[args]]
name = "diff"
type = "flag"
long = "diff"
short = "d"
description = "Summarize the current working tree diff instead of recent commits"
default = 0

[output]
mode = "text"
`;

const namingManifest = `
id = "naming"
summary = "Suggest names for things."
description = "Suggests concise names."
command = "naming"
kind = "ai-text"
requires_commands = ["apfel"]
supported_shells = ["fish", "zsh"]

[help]
usage = 'naming [OPTIONS] [TEXT]'
examples = ['naming "retry helper"', 'naming --style snake "release readiness dashboard"']

[input]
mode = "rest"
required = false

[[args]]
name = "style"
type = "enum"
long = "style"
short = "s"
description = "Naming style"
default = "mixed"
choices = ["mixed", "camel", "snake", "kebab", "title"]

[output]
mode = "text"
`;

const cmd = api.parseAppManifest(cmdManifest);
const define = api.parseAppManifest(defineManifest);
const gitsum = api.parseAppManifest(gitsumManifest);
const naming = api.parseAppManifest(namingManifest);

assert(cmd.help.usage === 'cmd [OPTIONS] "what you want to do"', "parser should read help usage");
assert(Array.isArray(cmd.help.examples) && cmd.help.examples.length === 2, "parser should read help examples");
assert(cmd.args.length === 0, "cmd should have no app-specific args");

assert(define.args.length === 2, "define should parse two string args");
assert(define.args[0].long === "in" && define.args[0].default === "auto", "define should parse long and default values");
assert(define.args[1].short === "o" && define.args[1].type === "string", "define should parse short flags");

assert(gitsum.args.length === 2, "gitsum should parse two app args");
assert(gitsum.args[0].type === "integer" && gitsum.args[0].default === 10, "gitsum should parse integer args");
assert(gitsum.args[1].type === "flag" && gitsum.args[1].default === 0, "gitsum should parse flag args");

assert(Array.isArray(naming.args[0].choices) && naming.args[0].choices.includes("snake"), "enum args should parse choices");

const commandFlags = api.buildBuiltinFlags("shell_command");
const textFlags = api.buildBuiltinFlags("text");
const structuredFlags = api.buildBuiltinFlags("structured_text");
const downloadTotals = api.buildDownloadTotals([
  {
    tag_name: "cmd-aaa111",
    assets: [
      { name: "cmd-aaa111.tar.gz", download_count: 4 },
      { name: "cmd-aaa111.sha256", download_count: 99 }
    ]
  },
  {
    tag_name: "cmd-bbb222",
    assets: [
      { name: "cmd-bbb222.tar.gz", download_count: 7 }
    ]
  },
  {
    tag_name: "log-digest-ccc333",
    assets: [
      { name: "log-digest-ccc333.tar.gz", download_count: 3 }
    ]
  }
]);

assert(commandFlags.length === 3, "shell_command apps should expose help, copy, and execute");
assert(commandFlags.some((flag) => flag.signature.indexOf("--execute") !== -1), "shell_command flags should include execute");
assert(textFlags.length === 2 && textFlags.some((flag) => flag.signature.indexOf("--copy") !== -1), "text apps should expose copy");
assert(structuredFlags.length === 2, "structured_text apps should expose help and copy");
assert(downloadTotals.cmd === 11, "download totals should sum bundle downloads across app revisions");
assert(downloadTotals["log-digest"] === 3, "download totals should support app ids with hyphens");
assert(typeof downloadTotals.cmd === "number" && downloadTotals.cmd !== 110, "download totals should ignore non-bundle assets");

assert(api.constants.TABLE_COLUMN_COUNT === 5, "catalog table should expose the expected number of columns");
assert(api.nextExpandedRowId("", "cmd") === "cmd", "opening a closed row should expand it");
assert(api.nextExpandedRowId("cmd", "cmd") === "", "clicking the open row should collapse it");
assert(api.nextExpandedRowId("cmd", "define") === "define", "opening a new row should replace the previous one");

const row = {
  id: "cmd",
  command: "cmd",
  summary: "Turn natural language into a shell command.",
  description: "Generate a single macOS shell command from a natural language request.",
  requires: "apfel,pbcopy",
  supported_shells: "fish,zsh",
  kind: "ai-command",
  downloads: 0
};

const headerMarkup = api.renderTableHeaderMarkup();
assert(headerMarkup.includes("catalog-col-app"), "catalog table header should include the app column");
assert(!headerMarkup.includes(">Command<"), "catalog table header should not keep the command column");
assert(!headerMarkup.includes(">Source<"), "catalog table header should not keep the source column");
assert(headerMarkup.includes(">Downloads<"), "catalog table header should include the downloads column");

const summaryCells = api.renderSummaryRowCellsMarkup(row);
assert(summaryCells.includes("catalog-row-toggle"), "collapsed rows should render a disclosure control");
assert(summaryCells.includes("aria-controls=\"catalog-details-cmd\""), "collapsed rows should point at their detail row");
assert(summaryCells.includes("Turn natural language into a shell command."), "collapsed rows should keep the short summary");
assert(summaryCells.includes("catalog-app-name"), "collapsed rows should use the app name as the disclosure control");
assert(!summaryCells.includes(row.description), "collapsed rows should not include the long description");
assert(!summaryCells.includes("catalog-command"), "collapsed rows should not include the command pill");
assert(!summaryCells.includes(">Source<"), "collapsed rows should not include the source link");
assert(!summaryCells.includes("catalog-chevron"), "collapsed rows should not include the old chevron affordance");
assert(!summaryCells.includes("apfeller install cmd"), "collapsed rows should not include the install command");

const summaryWithDownloads = api.renderSummaryRowCellsMarkup({
  id: "define",
  command: "define",
  summary: "Define a word or phrase.",
  description: "Tiny multilingual dictionary lookup.",
  requires: "apfel,pbcopy",
  supported_shells: "fish,zsh",
  kind: "ai-text",
  downloads: 12
});
assert(summaryWithDownloads.includes("12 downloads"), "collapsed rows should use generic download count copy");
assert(!summaryWithDownloads.includes("GitHub downloads"), "collapsed rows should not mention GitHub in the download text");

const detailRowMarkup = api.renderDetailRowMarkup("catalog-details-cmd", "<div>detail body</div>");
assert(detailRowMarkup.includes("catalog-detail-row"), "expanded details should render as a dedicated detail row");
assert(detailRowMarkup.includes("colspan=\"5\""), "detail rows should span the full table width");
assert(detailRowMarkup.includes("detail body"), "detail row wrapper should preserve the provided detail markup");

const cmdDetails = api.renderDetailMarkup(row, cmd, "https://github.com/hasit/apfeller-apps/tree/main/apps/cmd");
assert(cmdDetails.includes("catalog-detail-header"), "expanded details should render a dedicated header");
assert(cmdDetails.includes("catalog-detail-title"), "expanded details should render the app title prominently");
assert(cmdDetails.includes(">Source<"), "expanded details should include the source link");
assert(cmdDetails.includes("catalog-command"), "expanded details should include the command in the detail header");
assert(cmdDetails.includes("apfeller install cmd"), "expanded details should include the install command");
assert(cmdDetails.includes("cmd [OPTIONS] &quot;what you want to do&quot;"), "expanded details should include usage");
assert(cmdDetails.includes("--execute"), "expanded details should include built-in execute for command apps");
assert(cmdDetails.includes("catalog-detail-meta"), "expanded details should render compact metadata rows");
assert(!cmdDetails.includes("catalog-detail-facts"), "expanded details should not use the old fact card grid");
assert(!cmdDetails.includes("catalog-detail-fact"), "expanded details should not use the old fact card items");
assert(!cmdDetails.includes("catalog-detail-section-grid"), "expanded details should not use the old split section grid");
assert(!cmdDetails.includes("catalog-detail-title-group"), "expanded details should not use the old title-group wrapper");

const gitsumDetails = api.renderDetailMarkup({
  id: "gitsum",
  command: "gitsum",
  summary: "Summarize recent git activity.",
  description: "Summarizes recent commits or the current working tree diff.",
  requires: "apfel,git",
  supported_shells: "fish,zsh",
  kind: "ai-text"
}, gitsum, "https://github.com/hasit/apfeller-apps/tree/main/apps/gitsum");
assert(gitsumDetails.includes("-n, --count &lt;integer&gt;"), "expanded details should render integer args");
assert(gitsumDetails.includes("-d, --diff"), "expanded details should render flag args");
assert(gitsumDetails.includes("default: off"), "expanded details should describe flag defaults");

const namingDetails = api.renderDetailMarkup({
  id: "naming",
  command: "naming",
  summary: "Suggest names for things.",
  description: "Suggests concise names.",
  requires: "apfel",
  supported_shells: "fish,zsh",
  kind: "ai-text"
}, naming, "https://github.com/hasit/apfeller-apps/tree/main/apps/naming");
assert(namingDetails.includes("choices: mixed, camel, snake, kebab, title"), "expanded details should render enum choices");

const fallbackMarkup = api.renderFallbackDetailMarkup(row, "https://github.com/hasit/apfeller-apps/tree/main/apps/cmd");
assert(fallbackMarkup.includes(row.description), "fallback details should preserve the catalog description");
assert(fallbackMarkup.includes("apps/cmd"), "fallback details should point users to the app source");
assert(fallbackMarkup.includes("catalog-detail-meta"), "fallback details should reuse compact metadata rows");
assert(!fallbackMarkup.includes("catalog-detail-facts"), "fallback details should not render fact cards");
