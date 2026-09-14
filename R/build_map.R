# build_map.R — Bayern Radnetz Cycling Map
# OSM base tiles, view/bounds and all data layers clipped to the German state
# of Bayern (Bavaria). Output: index.html at repo root (served by GitHub Pages).
# Requires data/ populated first: run R/fetch_data.R once.

library(leaflet)
library(htmlwidgets)
library(sf)

# Read a hand-authored route file (GPX / GeoJSON / KML) as WGS84 line geometry.
# GPX stores the line in its "tracks" or "routes" layer; other formats read
# directly. Elevation (Z/M) is dropped so leaflet gets clean lng/lat lines.
load_route <- function(path) {
  ext <- tolower(tools::file_ext(path))
  g <- NULL
  if (ext == "gpx") {
    lyrs <- st_layers(path)$name
    for (cand in c("tracks", "routes")) {
      if (cand %in% lyrs) {
        gg <- suppressWarnings(st_read(path, layer = cand, quiet = TRUE))
        if (nrow(gg) > 0) { g <- gg; break }
      }
    }
  }
  if (is.null(g)) g <- suppressWarnings(st_read(path, quiet = TRUE))
  g <- st_zm(g, drop = TRUE, what = "ZM")
  g <- st_transform(g, 4326)
  g[st_geometry_type(g) %in% c("LINESTRING", "MULTILINESTRING"), ]
}

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

# --- Lodging: Bett+Bike POIs, clipped to Bayern (ADFC; private-use data) -----
lodging <- suppressWarnings(
  st_read("data/bett_bike/bettundbike-2026-06_de.gpx", layer = "waypoints", quiet = TRUE)
)
lodging <- lodging[lengths(st_intersects(lodging, bayern_geom)) > 0, ]  # in Bayern
lodging_popup <- paste0(
  "<b>", htmltools::htmlEscape(lodging$name), "</b>",
  ifelse(is.na(lodging$desc), "", paste0("<br>", htmltools::htmlEscape(lodging$desc))),
  ifelse(is.na(lodging$link1_href), "",
         paste0("<br><a href='", lodging$link1_href, "' target='_blank'>Website</a>"))
)

# --- Map -------------------------------------------------------------------
route_color <- "#c2255c"  # high-contrast magenta, reads well over OSM tiles

# The bike trails are the principal layer: shown by default. Data overlays added
# later (lodging, bike shops, POIs) should load OFF via hideGroup(). Context
# layers like the Bayern boundary may default ON since they aid orientation.
trail_group   <- "Bike trails (Bayernnetz für Radler)"
lodging_group <- "Bett+Bike lodging"
border_group  <- "Bayern boundary"

pad <- 0.2  # degrees of slack around Bayern for the pan limit

map <- leaflet(
  options = leafletOptions(minZoom = 7, maxZoom = 16)
) |>
  addTiles(
    urlTemplate = "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
    attribution = paste(
      "&copy; OpenStreetMap contributors",
      "| Radrouten: &copy; Bayerische Vermessungsverwaltung (CC BY 4.0)",
      "| Grenzen: &copy; GeoBasis-DE / BKG 2026 (dl-de/by-2-0)",
      "| Unterkünfte: Bett+Bike / ADFC"
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
  # Bett+Bike lodging: clustered markers, off by default (see hideGroup below)
  addCircleMarkers(
    data = lodging,
    radius = 5, weight = 1, color = "#ffffff", opacity = 1,
    fillColor = "#1c7ed6", fillOpacity = 0.9,
    label = ~name, popup = lodging_popup,
    clusterOptions = markerClusterOptions(),
    group = lodging_group
  )

# --- My route (optional): drawn on top if a file exists in data/my_route/ ---
# Draw the route in geojson.io / Google My Maps / brouter-web / komoot, export
# GPX/GeoJSON/KML, and save it as data/my_route/route.<ext>. It then renders as
# the star layer (bold orange, on top of the Bayernnetz), on by default.
myroute_group <- "My route"
overlay_groups <- c(trail_group, lodging_group, border_group)

route_files <- list.files("data/my_route",
                          pattern = "\\.(gpx|geojson|json|kml|kmz)$",
                          full.names = TRUE, ignore.case = TRUE)
if (length(route_files) > 0) {
  my_route <- load_route(route_files[[1]])
  map <- addPolylines(
    map, data = my_route,
    color = "#e8590c", weight = 6, opacity = 0.95,
    group = myroute_group
  )
  overlay_groups <- c(myroute_group, overlay_groups)  # list first in control
  message("Added 'My route' from ", route_files[[1]])
} else {
  message("No file in data/my_route/ yet — 'My route' layer skipped.")
}

map <- addLayersControl(
  map,
  overlayGroups = overlay_groups,
  options = layersControlOptions(collapsed = FALSE)
)
# Lodging is a data overlay: load it OFF so trails stay the default view.
map <- hideGroup(map, lodging_group)
# Groups ON by default: My route (if present), trails, Bayern boundary.
# OFF by default: Bett+Bike lodging (toggle on to plan).

# --- Export ----------------------------------------------------------------
out <- file.path(getwd(), "index.html")
saveWidget(map, out, selfcontained = TRUE, title = "Bayern Radnetz Cycling Map")
cat("Wrote", out, "with", nrow(routes), "route segments in Bayern\n")
