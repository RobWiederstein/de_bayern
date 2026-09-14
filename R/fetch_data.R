# fetch_data.R — download source route data.
# Source: Bayernnetz für Radler, Bayerische Vermessungsverwaltung (LDBV),
# via geodaten.bayern.de OpenData. License: CC BY 4.0 (attribution required).
# Reproducible: re-run to refresh. Raw downloads are gitignored; only this
# script is tracked.

dest_dir <- "data/bayernnetz_radler"
dir.create(dest_dir, showWarnings = FALSE, recursive = TRUE)

url <- "https://geodaten.bayern.de/odd/m/2/freizeitwege/bayernnetzradler/shape/bayernnetzradler_shape.zip"
zip_path <- file.path(dest_dir, "bayernnetzradler_shape.zip")

if (!file.exists(zip_path)) {
  message("Downloading Bayernnetz für Radler shapefile ...")
  download.file(url, zip_path, mode = "wb", quiet = FALSE)
} else {
  message("Zip already present: ", zip_path)
}

message("Unzipping ...")
unzip(zip_path, exdir = dest_dir, overwrite = TRUE)

cat("Contents of", dest_dir, ":\n")
print(list.files(dest_dir, recursive = TRUE))
