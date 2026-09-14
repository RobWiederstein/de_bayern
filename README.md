# de_bayern — Munich Radnetz Cycling Map

A lightweight, mobile-friendly [Leaflet](https://leafletjs.com/) map for a
cycling trip around Munich, Bavaria. Built in R, exported as a single
self-contained `index.html`, and served via GitHub Pages.

**Live map:** https://robwiederstein.github.io/de_bayern/

## Current state

OpenStreetMap base tiles + a ~250 km bounding box around Munich (center
48.137 N, 11.575 E), with the **Bayernnetz für Radler** route network clipped
to the box. Lodging, bike-shop, and POI layers to follow.

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

## Stack

R · leaflet · htmlwidgets · sf · osmdata
