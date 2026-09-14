# de_bayern — Munich Radnetz Cycling Map

A lightweight, mobile-friendly [Leaflet](https://leafletjs.com/) map for a
cycling trip around Munich, Bavaria. Built in R, exported as a single
self-contained `index.html`, and served via GitHub Pages.

**Live map:** https://robwiederstein.github.io/de_bayern/

## Current state

Milestone 1: OpenStreetMap base tiles + a ~250 km bounding box around Munich
(center 48.137 N, 11.575 E). Route, lodging, bike-shop, and POI layers to follow.

## Build

R runs inside the `rstudio` Docker container (nothing installed on the host):

```bash
docker exec --user rstudio --workdir /data/projects/r/germany rstudio \
  Rscript R/build_map.R
```

This writes `index.html` at the repo root. Push to `main` and GitHub Pages
redeploys automatically.

## Data layout

Files are organized by source: `data/<source>/<file>` (snake_case source folders).

```
data/
  waymarked_trails/route.gpx      # cycling route (Waymarked Trails GPX export)
  bett_bike/lodging.gpx           # lodging POIs (Bett+Bike GPX export)
  overpass/                       # optional cached osmdata/Overpass pulls (shops, POIs)
```

Bike-shop and POI layers are normally queried live via `osmdata`/Overpass at
build time; `overpass/` is only for cached snapshots.

## Stack

R · leaflet · htmlwidgets · sf · osmdata
