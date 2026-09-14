# build_map.R — Munich Radnetz Cycling Map
# Base map (OSM tiles + Munich bounding box) with the Bayernnetz für Radler
# route network clipped to the box. Output: index.html at repo root (GitHub Pages).
# Requires data/ populated first: run R/fetch_data.R once.

library(leaflet)
library(htmlwidgets)
library(sf)

# --- Munich center + 250 km (per-side) bounding box ------------------------
munich_lat <- 48.137
munich_lng <- 11.575

# Approved bounding box (±125 km from center)
bbox <- list(
  south = 47.01, west = 9.89,
  north = 49.26, east = 13.26
)

# --- Route network: Bayernnetz für Radler (LDBV Bayern, CC BY 4.0) ----------
shp <- "data/bayernnetz_radler/Bayernnetz_fuer_Radler/Bayernnetz_fuer_Radler.shp"
routes <- st_read(shp, quiet = TRUE)

# Simplify in native UTM (tolerance in metres) for a light, mobile-friendly file
routes <- st_simplify(routes, dTolerance = 50, preserveTopology = TRUE)

# Reproject to WGS84, then clip to the Munich box
routes <- st_transform(routes, 4326)
routes <- suppressWarnings(
  st_crop(routes, c(xmin = bbox$west, ymin = bbox$south,
                    xmax = bbox$east, ymax = bbox$north))
)

# --- State borders: VG2500 Länder (BKG, dl-de/by-2-0) ----------------------
states <- st_read("data/bkg_vg2500/vg2500/VG2500_LAN.shp", quiet = TRUE)
states <- states[states$GF == 9, ]          # drop water-area slivers (GF 8)
states <- st_transform(states, 4326)
# Keep only states touching the box; draw full outlines (no artificial clip edges)
box_ll <- st_as_sfc(st_bbox(c(xmin = bbox$west, ymin = bbox$south,
                              xmax = bbox$east, ymax = bbox$north), crs = 4326))
states <- states[lengths(st_intersects(states, box_ll)) > 0, ]

# --- Map -------------------------------------------------------------------
route_color <- "#c2255c"  # high-contrast magenta, reads well over OSM tiles

# The bike trails are the principal layer: shown by default. Data overlays added
# later (lodging, bike shops, POIs) should load OFF via hideGroup(). Context
# layers like state borders may default ON since they aid orientation.
trail_group  <- "Bike trails (Bayernnetz für Radler)"
border_group <- "State borders"

map <- leaflet(
  options = leafletOptions(minZoom = 7, maxZoom = 16)
) |>
  addTiles(
    urlTemplate = "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
    attribution = paste(
      "&copy; OpenStreetMap contributors",
      "| Radrouten: &copy; Bayerische Vermessungsverwaltung (CC BY 4.0)",
      "| Grenzen: &copy; GeoBasis-DE / BKG 2026 (dl-de/by-2-0)"
    )
  ) |>
  setView(lng = munich_lng, lat = munich_lat, zoom = 9) |>
  setMaxBounds(
    lng1 = bbox$west, lat1 = bbox$south,
    lng2 = bbox$east, lat2 = bbox$north
  ) |>
  # State borders first, so the trails draw on top of them
  addPolygons(
    data = states,
    fill = FALSE, color = "#555555", weight = 1.5, opacity = 0.6,
    dashArray = "4",
    label = ~GEN,
    group = border_group
  ) |>
  addPolylines(
    data = routes,
    color = route_color, weight = 3, opacity = 0.85,
    label = ~Name,
    highlightOptions = highlightOptions(
      weight = 5, color = "#7a0f3d", opacity = 1, bringToFront = TRUE
    ),
    group = trail_group
  ) |>
  addLayersControl(
    overlayGroups = c(trail_group, border_group),
    options = layersControlOptions(collapsed = FALSE)
  )
# Both groups load ON: trails (core layer) and state borders (orientation context).

# --- Export ----------------------------------------------------------------
out <- file.path(getwd(), "index.html")
saveWidget(map, out, selfcontained = TRUE, title = "Munich Radnetz Cycling Map")
cat("Wrote", out, "with", nrow(routes), "route segments in box\n")
