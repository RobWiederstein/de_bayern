# de_bayern — Bayern Radnetz Cycling Map

A lightweight, mobile-friendly [Leaflet](https://leafletjs.com/) map for
cycling in Bayern (Bavaria), Germany. Built in R, exported as a single
self-contained `index.html`, and served via GitHub Pages.

**Live map:** https://robwiederstein.github.io/de_bayern/

## Current state

OpenStreetMap base tiles with the view, pan-bounds, and all data layers clipped
to the **Bayern** state boundary (BKG VG2500). Shows the full **Bayernnetz für
Radler** route network plus the Bayern outline. Lodging, bike-shop, and POI
layers to follow.

## Build

R runs inside the `rstudio` Docker container (nothing installed on the host).
First fetch the source data (once, or to refresh), then build:

```bash
docker exec --user rstudio --workdir /data/projects/r/germany rstudio \
  Rscript R/fetch_data.R      # download + unzip source data into data/
docker exec --user rstudio --workdir /data/projects/r/germany rstudio \
  Rscript R/build_map.R       # write index.html at repo root
```

Push to `main` and GitHub Pages redeploys automatically.

## Data layout

Files are organized by source: `data/<source>/<file>` (snake_case). The whole
`data/` folder is gitignored — raw data is fetched, never committed. Rebuild it
with `R/fetch_data.R`.

```
data/
  bayernnetz_radler/   # route network shapefile (LDBV Bayern OpenData, CC BY 4.0)
  bett_bike/           # lodging POIs (future)
  overpass/            # cached osmdata/Overpass pulls (future; usually queried live)
```

**Route source:** Bayernnetz für Radler, Bayerische Vermessungsverwaltung (LDBV),
via [geodaten.bayern.de OpenData](https://geodaten.bayern.de/opengeodata/OpenDataDetail.html?pn=bvv_bayernnetzradler)
— 123 named long-distance routes, CC BY 4.0 (attribution required).

## Adding your own trip route

Draw the route in an external tool and export it — the build picks it up
automatically. Save the export as `data/my_route/route.gpx` (or `.geojson` /
`.kml`), then rebuild. It renders as the **"My route"** layer: bold orange, on
top of the Bayernnetz, on by default. No file present → the layer is skipped.

Authoring tools:
- **Snapped to bike paths** (recommended for a ridable route): brouter-web.de,
  cycle.travel, or komoot → export GPX.
- **Freehand click-to-draw**: geojson.io (exports GeoJSON) or Google *My* Maps
  (exports KML). Quick, but segments are straight lines between clicks.

## Stack

R · leaflet · htmlwidgets · sf · osmdata
