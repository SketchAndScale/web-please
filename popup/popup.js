const RULESET_ID = "web_mode";

const toggle = document.querySelector("#toggle");
const statusTitle = document.querySelector("#status-title");
const statusCopy = document.querySelector("#status-copy");
const statusLabel = document.querySelector("#status-label");

function renderState(state) {
  const enabled = state === "on";
  document.body.dataset.state = state;
  toggle.setAttribute("aria-checked", String(enabled));

  if (state === "error") {
    statusLabel.textContent = "Unavailable";
    statusTitle.textContent = "Web results unavailable";
    statusCopy.textContent = "Chrome could not update the search rule.";
    return;
  }

  statusLabel.textContent = enabled ? "Active" : "Paused";
  statusTitle.textContent = enabled ? "Web results are on" : "Web results are off";
  statusCopy.textContent = enabled
    ? "Ordinary searches open in Google’s Web view."
    : "Google searches behave normally.";
}

async function getEnabledState() {
  const enabledRulesets = await chrome.declarativeNetRequest.getEnabledRulesets();
  return enabledRulesets.includes(RULESET_ID);
}

function getSupportedSearch(rawUrl) {
  try {
    const url = new URL(rawUrl);
    const isGoogleSearch = /(^|\.)google\.[^/]+$/i.test(url.hostname) && url.pathname === "/search";
    const isWebView = url.searchParams.get("udm") === "14";
    const isOrdinarySearch = !url.searchParams.has("udm") && !url.searchParams.has("tbm");
    return isGoogleSearch && (isWebView || isOrdinarySearch) ? url : null;
  } catch {
    return null;
  }
}

async function syncCurrentTab(enabled) {
  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  const url = tab?.url ? getSupportedSearch(tab.url) : null;
  if (!tab?.id || !url) return;

  if (enabled) url.searchParams.set("udm", "14");
  else url.searchParams.delete("udm");

  await chrome.tabs.update(tab.id, { url: url.toString() });
}

async function setEnabledState(enabled) {
  await chrome.declarativeNetRequest.updateEnabledRulesets({
    enableRulesetIds: enabled ? [RULESET_ID] : [],
    disableRulesetIds: enabled ? [] : [RULESET_ID]
  });
  renderState(enabled ? "on" : "off");
  try {
    await syncCurrentTab(enabled);
  } catch (error) {
    console.warn("Web Please changed its setting but could not refresh this tab.", error);
  }
}

async function initialize() {
  renderState((await getEnabledState()) ? "on" : "off");

  toggle.addEventListener("click", async () => {
    toggle.disabled = true;
    try {
      await setEnabledState(!(await getEnabledState()));
    } catch (error) {
      console.error("Web Please could not update its ruleset.", error);
      renderState("error");
    } finally {
      toggle.disabled = false;
    }
  });
}

initialize().catch((error) => {
  console.error("Web Please could not initialize.", error);
  renderState("error");
  toggle.disabled = true;
});
