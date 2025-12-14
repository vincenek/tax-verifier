// background service worker: create a context menu item to verify links
chrome.runtime.onInstalled.addListener(() => {
  try {
    chrome.contextMenus.create({
      id: 'plv-verify-link',
      title: 'Verify link with PLV',
      contexts: ['link']
    });
  } catch (e) {
    // ignore
  }
});

chrome.contextMenus.onClicked.addListener(async (info, tab) => {
  if (info.menuItemId !== 'plv-verify-link') return;
  const linkUrl = info.linkUrl || info.pageUrl || '';
  // get stored origin
  chrome.storage.local.get(['verifierOrigin'], (res) => {
    let origin = (res && res.verifierOrigin) ? res.verifierOrigin : 'https://vincenek.github.io/tax-verifier/';
    if (!origin.endsWith('/')) origin += '/';
    const target = origin + (origin.includes('?') ? '&' : '?') + 'url=' + encodeURIComponent(linkUrl);
    chrome.tabs.create({ url: target });
  });
});
