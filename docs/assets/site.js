(function (root) {
  var COPY_RESET_DELAY_MS = 1800;

  function trimTrailingNewline(value) {
    return String(value).replace(/\n$/, "");
  }

  function isShellCodeNode(codeNode) {
    var className = (codeNode && codeNode.className) || "";
    var wrapper = codeNode && codeNode.closest ? codeNode.closest("[class*='language-'], .highlighter-rouge") : null;
    var wrapperClassName = wrapper && wrapper.className ? wrapper.className : "";
    var combined = className + " " + wrapperClassName;

    return /language-(sh|shell|bash|zsh|fish)\b/.test(combined);
  }

  function copyText(value) {
    var text = String(value);

    if (root.navigator && root.navigator.clipboard && typeof root.navigator.clipboard.writeText === "function") {
      return root.navigator.clipboard.writeText(text);
    }

    return new Promise(function (resolve, reject) {
      var textArea = root.document.createElement("textarea");

      textArea.value = text;
      textArea.setAttribute("readonly", "readonly");
      textArea.style.position = "fixed";
      textArea.style.top = "-9999px";
      root.document.body.appendChild(textArea);
      textArea.select();

      try {
        if (!root.document.execCommand("copy")) {
          reject(new Error("copy failed"));
          return;
        }
      } catch (error) {
        reject(error);
        return;
      } finally {
        root.document.body.removeChild(textArea);
      }

      resolve();
    });
  }

  function setCopyState(button, state) {
    var nextLabel;

    if (!button) {
      return;
    }

    nextLabel = button.getAttribute("data-label-default") || "Copy";

    if (state === "copied") {
      nextLabel = button.getAttribute("data-label-copied") || "Copied";
    } else if (state === "error") {
      nextLabel = button.getAttribute("data-label-error") || "Press Cmd+C";
    }

    button.textContent = nextLabel;
    button.setAttribute("data-copy-state", state || "idle");
  }

  function createCopyButton(copyTextValue, label) {
    var button = root.document.createElement("button");

    button.type = "button";
    button.className = "copy-button";
    button.textContent = label || "Copy";
    button.setAttribute("data-copy-state", "idle");
    button.setAttribute("data-copy-text", copyTextValue);
    button.setAttribute("data-label-default", label || "Copy");
    button.setAttribute("data-label-copied", "Copied");
    button.setAttribute("data-label-error", "Press Cmd+C");
    button.setAttribute("aria-label", "Copy command");

    button.addEventListener("click", function () {
      copyText(button.getAttribute("data-copy-text")).then(function () {
        setCopyState(button, "copied");
        root.setTimeout(function () {
          setCopyState(button, "idle");
        }, COPY_RESET_DELAY_MS);
      }).catch(function () {
        setCopyState(button, "error");
        root.setTimeout(function () {
          setCopyState(button, "idle");
        }, COPY_RESET_DELAY_MS);
      });
    });

    return button;
  }

  function enhanceCommandRails(scopeNode) {
    var rails = scopeNode.querySelectorAll(".command-rail[data-copy-text], .catalog-copyable[data-copy-text]");

    Array.prototype.forEach.call(rails, function (rail) {
      var text;

      if (rail.getAttribute("data-copy-ready") === "true") {
        return;
      }

      text = rail.getAttribute("data-copy-text");
      if (!text) {
        return;
      }

      rail.appendChild(createCopyButton(text, "Copy"));
      rail.setAttribute("data-copy-ready", "true");
    });
  }

  function enhanceShellBlocks(scopeNode) {
    var codeNodes = scopeNode.querySelectorAll("code");

    Array.prototype.forEach.call(codeNodes, function (codeNode) {
      var container;
      var codeText;

      if (!isShellCodeNode(codeNode)) {
        return;
      }

      container = codeNode.closest(".highlighter-rouge") || codeNode.closest("pre");
      if (!container || container.getAttribute("data-copy-ready") === "true") {
        return;
      }

      codeText = trimTrailingNewline(codeNode.textContent || "");
      if (!codeText) {
        return;
      }

      container.classList.add("site-shell-block");
      container.appendChild(createCopyButton(codeText, "Copy"));
      container.setAttribute("data-copy-ready", "true");
    });
  }

  function enhanceCopyables(scopeNode) {
    if (!scopeNode || !scopeNode.querySelectorAll) {
      return;
    }

    enhanceCommandRails(scopeNode);
    enhanceShellBlocks(scopeNode);
  }

  root.ApfellerSite = {
    copyText: copyText,
    createCopyButton: createCopyButton,
    enhanceCopyables: enhanceCopyables
  };

  if (!root.document) {
    return;
  }

  root.document.addEventListener("DOMContentLoaded", function () {
    enhanceCopyables(root.document);
  });
}(typeof window !== "undefined" ? window : globalThis));
