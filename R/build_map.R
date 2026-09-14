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

# --- Map -------------------------------------------------------------------
route_color <- "#c2255c"  # high-contrast magenta, reads well over OSM tiles

# The bike trails are the principal layer: shown by default. Future overlays
# (lodging, bike shops, POIs) should be added as their own groups and switched
# OFF at load with hideGroup(), so the trails remain the default view.
trail_group <- "Bike trails (Bayernnetz für Radler)"

map <- leaflet(
  options = leafletOptions(minZoom = 7, maxZoom = 16)
) |>
  addTiles(
    urlTemplate = "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
    attribution = paste(
      "&copy; OpenStreetMap contributors",
      "| Radrouten: &copy; Bayerische Vermessungsverwaltung (CC BY 4.0)"
    )
  ) |>
  setView(lng = munich_lng, lat = munich_lat, zoom = 9) |>
  setMaxBounds(
    lng1 = bbox$west, lat1 = bbox$south,
    lng2 = bbox$east, lat2 = bbox$north
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
    overlayGroups = trail_group,
    options = layersControlOptions(collapsed = FALSE)
  )
# Note: no hideGroup(trail_group) — trails stay ON by default (project's core layer).

# --- Export ----------------------------------------------------------------
out <- file.path(getwd(), "index.html")
saveWidget(map, out, selfcontained = TRUE, title = "Munich Radnetz Cycling Map")
cat("Wrote", out, "with", nrow(routes), "route segments in box\n")
