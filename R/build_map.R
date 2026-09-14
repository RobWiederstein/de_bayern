# build_map.R — Munich Radnetz Cycling Map
# Milestone 1: OSM standard tiles + bounding box around Munich.
# Output: index.html at repo root (served by GitHub Pages).

library(leaflet)
library(htmlwidgets)

# --- Munich center + 250 km (per-side) bounding box ------------------------
munich_lat <- 48.137
munich_lng <- 11.575

# Approved bounding box (±125 km from center)
bbox <- list(
  south = 47.01, west = 9.89,
  north = 49.26, east = 13.26
)

# --- Map -------------------------------------------------------------------
map <- leaflet(
  options = leafletOptions(minZoom = 7, maxZoom = 16)
) |>
  addTiles(
    urlTemplate = "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
    attribution = "&copy; OpenStreetMap contributors"
  ) |>
  setView(lng = munich_lng, lat = munich_lat, zoom = 9) |>
  setMaxBounds(
    lng1 = bbox$west, lat1 = bbox$south,
    lng2 = bbox$east, lat2 = bbox$north
  )

# --- Export ----------------------------------------------------------------
out <- file.path(getwd(), "index.html")
saveWidget(map, out, selfcontained = TRUE, title = "Munich Radnetz Cycling Map")
cat("Wrote", out, "\n")
