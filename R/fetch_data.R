# fetch_data.R — download source data. Reproducible: re-run to refresh.
# Raw downloads are gitignored; only this script is tracked.
#
# Sources:
#   1. Bayernnetz für Radler — Bayerische Vermessungsverwaltung (LDBV),
#      geodaten.bayern.de OpenData. License: CC BY 4.0.
#   2. Verwaltungsgebiete VG2500 (state borders) — Bundesamt für Kartographie
#      und Geodäsie (BKG). License: Datenlizenz Deutschland – Namensnennung 2.0.

fetch_zip <- function(url, dest_dir) {
  dir.create(dest_dir, showWarnings = FALSE, recursive = TRUE)
  zip_path <- file.path(dest_dir, basename(url))
  if (!file.exists(zip_path)) {
    message("Downloading ", basename(url), " ...")
    download.file(url, zip_path, mode = "wb", quiet = FALSE)
  } else {
    message("Already present: ", zip_path)
  }
  message("Unzipping into ", dest_dir, " ...")
  unzip(zip_path, exdir = dest_dir, overwrite = TRUE)
}

# 1. Bayernnetz für Radler (route network)
fetch_zip(
  "https://geodaten.bayern.de/odd/m/2/freizeitwege/bayernnetzradler/shape/bayernnetzradler_shape.zip",
  "data/bayernnetz_radler"
)

# 2. VG2500 administrative boundaries (state borders)
fetch_zip(
  "https://daten.gdz.bkg.bund.de/produkte/vg/vg2500/aktuell/vg2500_01-01-2026.utm32s.shape.zip",
  "data/bkg_vg2500"
)

cat("\nDone.\n")
