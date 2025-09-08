# Digital Print Estimator — Split Project

This project was auto-split from the monolithic HTML into modular sources.

## Structure
```
printing_estimator_split/
  build.sh
  src/
    index.template.html
    css/
      style.css
    js/
      app.js
    partials/
      header.html
      tabs_setup.html
      tabs_job.html
      tabs_parts.html
      tabs_templates.html
      tabs_pricing.html
      tabs_inventory.html
      tabs_quote.html
  dist/
    printing_estimator.build.html  (generated)
```

## Build
```
cd printing_estimator_split
./build.sh
```

The build writes **dist/printing_estimator.build.html** which is a single-file bundle you can drop into Docker or open locally.

## Notes
- Inline CSS and JS from the original were consolidated to **src/css/style.css** and **src/js/app.js**.
- External `<script src=...>` tags were preserved and appended near the end of `<body>` in the template.
- Tabs were split by searching for elements whose **id** contained one of:
  setup, job, parts, templates, pricing, inventory, quote.
  Sections not found were created as **placeholders**.
- You can further split `app.js` into multiple logical files (state.js, pricing.js, etc.) at any time; just add more `// @@include:` lines in the `<script>` area of **index.template.html**.

---
This is a first pass. If any tab HTML landed in `header.html` or a placeholder, tell me which ids/classes mark the sections and I can refine the extractor.
