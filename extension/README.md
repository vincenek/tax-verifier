Payment Link Verifier — Extension (local dev)

This folder contains a small popup extension to open the verifier with the current page URL. The popup now lets you set a verifier origin (persisted) and copy a bookmarklet for quick usage.

Quick local steps for Microsoft Edge

1. Build or run the web app locally:
   - Run `flutter build web` and serve `build/web`, or use `flutter run -d web-server`.
   - Example static server: `cd build\web` then `python -m http.server 5000`.
   - Ensure the app is reachable at `http://localhost:5000/` (or update the origin in the popup UI).

2. Load the extension in Edge (Developer mode):
   - Open Edge -> Settings -> Extensions -> Enable "Developer mode".
   - Click "Load unpacked" and select this `extension/` folder.
   - The extension icon will appear in the toolbar.

3. Use the popup UI:
   - Open the extension popup and set the "Verifier origin" to your running app (for example `http://localhost:5000/`) and click "Save Origin".
   - Click "Open Verifier" to open the verifier in a new tab; the current page URL is passed as `?url=` and the app will auto-verify.
   - Click "Copy Bookmarklet" to copy a ready-to-use bookmarklet. Create a new bookmark and paste the copied value into the URL field — clicking that bookmark on any page will open the verifier for that page.

Packaging (optional)

- To produce a ZIP of this `extension/` folder on Windows, run the PowerShell helper `make_zip.ps1` included here. It creates `extension.zip` you can share for manual install.
 - To produce a ZIP of this `extension/` folder on Windows, run the PowerShell helper `make_zip.ps1` included here. It creates `extension.zip` you can share for manual install.

Integration SDK

Below is a copy-paste friendly JavaScript snippet developers can embed in any web app to open PLV with the current page or a specific URL. It gracefully falls back to opening the deployed Pages site.

```html
<script>
function openPLV(url){
   var base = 'https://vincenek.github.io/tax-verifier/';
   window.open(base + '?url=' + encodeURIComponent(url || location.href), '_blank');
}
</script>
<button onclick="openPLV()">Verify this page</button>
```

React example (copy into a component):

```jsx
import React from 'react';
export default function VerifyButton({url}){
   const open = () => window.open('https://vincenek.github.io/tax-verifier/?url='+encodeURIComponent(url||location.href),'_blank');
   return <button onClick={open}>Verify this page</button>;
}
```

Notes

- The popup uses `chrome.tabs` APIs which work in Edge (Chromium-based). No permissions beyond `tabs` are required.
- For production deployment set the saved origin to your deployed app origin (e.g., `https://verifier.example.com/`).

If you'd like, I can create screenshots of the install flow and generate an installation ZIP now.