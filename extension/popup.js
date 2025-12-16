// Helper: read/save origin from chrome.storage
const DEFAULT_ORIGIN = 'https://vincenek.github.io/tax-verifier/';

async function getSavedOrigin() {
  return new Promise((resolve) => {
    if (!chrome || !chrome.storage) return resolve(DEFAULT_ORIGIN);
    chrome.storage.local.get(['verifierOrigin'], (res) => {
      resolve(res && res.verifierOrigin ? res.verifierOrigin : DEFAULT_ORIGIN);
    });
  });
}

function saveOrigin(value) {
  if (!chrome || !chrome.storage) return;
  chrome.storage.local.set({ verifierOrigin: value });
}

document.getElementById('open').addEventListener('click', async () => {
  const btn = document.getElementById('open');
  try {
    btn.disabled = true;
    btn.textContent = 'Opening...';
    btn.style.transform = 'scale(0.98)';
    const tabs = await chrome.tabs.query({ active: true, currentWindow: true });
    const url = tabs[0].url;
    const appOrigin = await getSavedOrigin();
    const target = appOrigin + (appOrigin.includes('?') ? '&' : '?') + 'url=' + encodeURIComponent(url);
    chrome.tabs.create({ url: target }, () => {
      btn.textContent = 'Opened';
      setTimeout(() => { btn.textContent = 'Open Verifier'; btn.disabled = false; btn.style.transform = ''; }, 900);
    });
  } catch (e) {
    console.error(e);
    btn.textContent = 'Failed';
    setTimeout(() => { btn.textContent = 'Open Verifier'; btn.disabled = false; btn.style.transform = ''; }, 1200);
  }
});

// UI wiring: load saved origin into input, save button, copy bookmarklet
window.addEventListener('DOMContentLoaded', async () => {
  const input = document.getElementById('appOrigin');
  const saveBtn = document.getElementById('saveOrigin');
  const copyBtn = document.getElementById('copyBookmarklet');
  const origin = await getSavedOrigin();
  input.value = origin;

  saveBtn.addEventListener('click', () => {
    let v = input.value.trim();
    if (!v) v = DEFAULT_ORIGIN;
    // ensure trailing slash
    if (!v.endsWith('/')) v += '/';
    saveOrigin(v);
    saveBtn.textContent = 'Saved';
    setTimeout(() => (saveBtn.textContent = 'Save Origin'), 1200);
  });

  copyBtn.addEventListener('click', async () => {
    let v = input.value.trim() || DEFAULT_ORIGIN;
    if (!v.endsWith('/')) v += '/';
    const bookmarklet = `javascript:(function(){window.open('${v}?url='+encodeURIComponent(location.href),'_blank');})();`;
    try {
      await navigator.clipboard.writeText(bookmarklet);
      copyBtn.textContent = 'Copied';
      setTimeout(() => (copyBtn.textContent = 'Copy Bookmarklet'), 1200);
    } catch (e) {
      console.error('copy failed', e);
      copyBtn.textContent = 'Copy Failed';
      setTimeout(() => (copyBtn.textContent = 'Copy Bookmarklet'), 1200);
    }
  });
});
