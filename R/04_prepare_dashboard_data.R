# Copies validated CSV contracts into the browser-safe Vite public directory.
# Run after validation: Rscript R/04_prepare_dashboard_data.R

source_files <- c("SecurityEvents.csv", "Incidents.csv", "R_Analytics.csv", "Users.csv", "CloudAssets.csv", "DateTable.csv")
from <- file.path("data", "processed", source_files)
if (any(!file.exists(from))) stop("Validated processed files are missing. Run R/run_all.R from the repository root.")
to_dir <- file.path("web", "public", "data")
dir.create(to_dir, recursive = TRUE, showWarnings = FALSE)
copied <- file.copy(from, to_dir, overwrite = TRUE)
if (!all(copied)) stop("Could not copy every dashboard data contract into ", to_dir)
generated_at <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
writeLines(paste0('{"generatedAt":"', generated_at, '","synthetic":true,"files":["', paste(source_files, collapse = '","'), '"]}'), file.path(to_dir, "manifest.json"), useBytes = TRUE)
cat("Dashboard-safe CSV data copied to web/public/data/. Generated at", generated_at, "UTC.\n")
