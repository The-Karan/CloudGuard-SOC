# CloudGuard SOC end-to-end reproducible pipeline. Run: Rscript R/run_all.R
source("R/01_generate_logs.R")
source("R/02_analyze_logs.R")
source("R/03_validate.R")
source("R/04_prepare_dashboard_data.R")
