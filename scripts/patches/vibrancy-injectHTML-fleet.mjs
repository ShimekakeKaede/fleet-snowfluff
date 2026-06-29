function extractImportScripts(markup) {
  if (!markup) return '';
  const chunks = [];
  const re = /<script[^>]*>([\s\S]*?)<\/script>/gi;
  let match;
  while ((match = re.exec(markup))) {
    if (match[1]) chunks.push(match[1]);
  }
  return chunks.join('\n');
}

function injectHTML(window) {
  const inlineJs = extractImportScripts(scriptHTML());
  const injectPrelude = `(function(){
    const vscodeVibrancyTTP = window.trustedTypes?.getExistingPolicy?.("VscodeVibrancyContinued")
      || window.trustedTypes?.createPolicy?.("VscodeVibrancyContinued", { createHTML (v) { return v; } });

    document.getElementById("vscode-vibrancy-style")?.remove();
    const styleElement = document.createElement("div");
    styleElement.id = "vscode-vibrancy-style";
    styleElement.innerHTML = vscodeVibrancyTTP.createHTML(${JSON.stringify(
    styleHTML()
  )});
    document.body.appendChild(styleElement);

    document.getElementById("vscode-vibrancy-script")?.remove();
    const scriptHost = document.createElement("div");
    scriptHost.id = "vscode-vibrancy-script";
    document.body.appendChild(scriptHost);
    /* FLEET_SCRIPT_EXEC_PATCH inline */
`;
  const injectEpilogue = `
  })();`;

  window.webContents.executeJavaScript(injectPrelude + inlineJs + injectEpilogue);
}
