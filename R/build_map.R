# build_map.R — Bayern Radnetz Cycling Map
# OSM base tiles, view/bounds and all data layers clipped to the German state
# of Bayern (Bavaria). Output: index.html at repo root (served by GitHub Pages).
# Requires data/ populated first: run R/fetch_data.R once.

library(leaflet)
library(htmlwidgets)
library(sf)

# --- Clip region: Bayern boundary (BKG VG2500, dl-de/by-2-0) ----------------
states <- st_read("data/bkg_vg2500/vg2500/VG2500_LAN.shp", quiet = TRUE)
states <- states[states$GF == 9, ]           # land polygons (drop water slivers)
states <- st_transform(states, 4326)
bayern <- states[states$GEN == "Bayern", ]
bayern_geom <- st_make_valid(st_union(st_geometry(bayern)))
bb <- st_bbox(bayern)                          # Bayern's extent -> view + maxBounds

# --- Route network: Bayernnetz für Radler, clipped to Bayern (LDBV, CC BY 4.0)
routes <- st_read("data/bayernnetz_radler/Bayernnetz_fuer_Radler/Bayernnetz_fuer_Radler.shp",
                  quiet = TRUE)
routes <- st_simplify(routes, dTolerance = 50, preserveTopology = TRUE)  # light file
routes <- st_transform(routes, 4326)
routes <- suppressWarnings(st_intersection(routes, bayern_geom))
routes <- routes[!st_is_empty(st_geometry(routes)), ]
routes <- suppressWarnings(st_collection_extract(routes, "LINESTRING"))

# --- Map -------------------------------------------------------------------
route_color <- "#c2255c"  # high-contrast magenta, reads well over OSM tiles

# The bike trails are the principal layer: shown by default. Data overlays added
# later (lodging, bike shops, POIs) should load OFF via hideGroup(). Context
# layers like the Bayern boundary may default ON since they aid orientation.
trail_group  <- "Bike trails (Bayernnetz für Radler)"
border_group <- "Bayern boundary"

pad <- 0.2  # degrees of slack around Bayern for the pan limit

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
  fitBounds(bb[["xmin"]], bb[["ymin"]], bb[["xmax"]], bb[["ymax"]]) |>
  setMaxBounds(bb[["xmin"]] - pad, bb[["ymin"]] - pad,
               bb[["xmax"]] + pad, bb[["ymax"]] + pad) |>
  # Bayern outline first, so the trails draw on top of it
  addPolygons(
    data = bayern,
    fill = FALSE, color = "#2b2b2b", weight = 3, opacity = 0.9,
    dashArray = "6",
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
# Both groups load ON: trails (core layer) and Bayern boundary (orientation).

# --- Export ----------------------------------------------------------------
out <- file.path(getwd(), "index.html")
saveWidget(map, out, selfcontained = TRUE, title = "Bayern Radnetz Cycling Map")
cat("Wrote", out, "with", nrow(routes), "route segments in Bayern\n")
