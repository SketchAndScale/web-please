const RULESET_ID = "web_mode";

const toggle = document.querySelector("#toggle");
const statusTitle = document.querySelector("#status-title");
const statusCopy = document.querySelector("#status-copy");

function setVisualState(enabled) {
  toggle.setAttribute("aria-checked", String(enabled));
  statusTitle.textContent = enabled ? "Web results" : "Normal Google";
  statusCopy.textContent = enabled
    ? "Ordinary Google searches use Web mode."
    : "Google searches behave normally.";
}

async function isEnabled() {
  const enabledRulesets = await chrome.declarativeNetRequest.getEnabledRulesets();
  return enabledRulesets.includes(RULESET_ID);
}

function isOrdinaryGoogleSearch(rawUrl) {
  try {
    const url = new URL(rawUrl);
    return /(^|\.)google\.[^/]+$/i.test(url.hostname)
      && url.pathname === "/search"
      && !url.searchParams.has("udm")
      && !url.searchParams.has("tbm");
  } catch {
    return false;
  }
}

async function updateCurrentSearch(enabled) {
  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  if (!tab?.id || !tab.url) return;

  try {
    const url = new URL(tab.url);
    if (!isOrdinaryGoogleSearch(tab.url) && !(url.searchParams.get("udm") === "14" && url.pathname === "/search")) return;

    if (enabled) url.searchParams.set("udm", "14");
    else if (url.searchParams.get("udm") === "14") url.searchParams.delete("udm");

    await chrome.tabs.update(tab.id, { url: url.toString() });
  } catch {
    // A toggle should never fail because the active tab is unusual.
  }
}

async function setEnabled(enabled) {
  await chrome.declarativeNetRequest.updateEnabledRulesets({
    enableRulesetIds: enabled ? [RULESET_ID] : [],
    disableRulesetIds: enabled ? [] : [RULESET_ID]
  });
  setVisualState(enabled);
  await updateCurrentSearch(enabled);
}

(async () => {
  const enabled = await isEnabled();
  setVisualState(enabled);
  toggle.addEventListener("click", async () => {
    toggle.disabled = true;
    try {
      await setEnabled(!(await isEnabled()));
    } finally {
      toggle.disabled = false;
    }
  });
})().catch(() => {
  setVisualState(false);
  toggle.disabled = true;
});

