Noto Sans (recommended)

This folder should contain a Unicode-capable TTF font file used by the PDF exporter to render em-dashes, smart quotes, and non-Latin characters.

Recommended: Noto Sans Regular
- Download from Google Fonts: https://fonts.google.com/specimen/Noto+Sans
- Place the TTF as `assets/fonts/NotoSans-Regular.ttf`

After adding the file, run:

flutter pub get

Then exported PDFs will use the embedded font. If no font is found, ShieldPay will fall back to sanitized ASCII replacements.
