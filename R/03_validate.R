# CloudGuard SOC - base-R output and data-quality validation
# Run from repository root: Rscript R/03_validate.R

required <- c("data/processed/SecurityEvents.csv", "data/processed/Incidents.csv", "data/processed/R_Analytics.csv", "data/processed/Users.csv", "data/processed/CloudAssets.csv", "data/processed/DateTable.csv")
missing <- required[!file.exists(required)]
if (length(missing)) stop("Missing outputs: ", paste(missing, collapse = ", "), ". Run R/run_all.R first.")

read_csv <- function(path) read.csv(path, stringsAsFactors = FALSE, check.names = FALSE, na.strings = "")
normalise_blank <- function(x) { x[is.na(x)] <- ""; x }
assert <- function(condition, message) if (!isTRUE(condition)) stop("VALIDATION FAILED: ", message, call. = FALSE)
assert_columns <- function(x, cols, table_name) assert(all(cols %in% names(x)), paste0(table_name, " is missing: ", paste(setdiff(cols, names(x)), collapse = ", ")))

events <- read_csv(required[1]); incidents <- read_csv(required[2]); analytics <- read_csv(required[3]); users <- read_csv(required[4]); assets <- read_csv(required[5]); dates <- read_csv(required[6])
## Blank IncidentID is the documented state for normal, non-correlated events.
## read.csv(..., na.strings = "") represents those blanks as NA, so normalise before FK checks.
events$IncidentID <- normalise_blank(events$IncidentID)
analytics$IncidentID <- normalise_blank(analytics$IncidentID)
assert_columns(events, c("EventID", "Timestamp", "EventDate", "UserID", "AssetID", "IncidentID", "RiskScore", "RiskBand", "IsAnomaly", "DetectionReason", "GroundTruthAttack"), "SecurityEvents")
assert_columns(incidents, c("IncidentID", "RepresentativeEventID", "CreatedAt", "IncidentDate", "Severity", "Status", "UserID", "AssetID", "RiskScore", "DetectionReason", "AcknowledgedAt", "ResolvedAt", "ResponseMinutes", "ResolutionMinutes"), "Incidents")
assert_columns(analytics, c("EventID", "IncidentID", "RiskScore", "IsAnomaly", "DetectionReason", "GroundTruthAttack"), "R_Analytics")

assert(nrow(events) > 0 && nrow(incidents) > 0, "event and incident outputs must contain rows")
assert(!anyDuplicated(events$EventID), "SecurityEvents[EventID] must be unique")
assert(!anyDuplicated(analytics$EventID), "R_Analytics[EventID] must be unique")
assert(!anyDuplicated(incidents$IncidentID), "Incidents[IncidentID] must be unique")
assert(!anyDuplicated(users$UserID) && !anyDuplicated(assets$AssetID) && !anyDuplicated(dates$Date), "dimension identifiers must be unique")
assert(all(events$UserID %in% users$UserID) && all(events$AssetID %in% assets$AssetID), "event foreign keys must reference dimensions")
assert(all(analytics$EventID %in% events$EventID) && nrow(analytics) == nrow(events), "analytics must have one row for each event")
assert(all(incidents$RepresentativeEventID %in% events$EventID), "incident representative events must exist")
flagged_events <- events[!is.na(events$IncidentID) & nzchar(events$IncidentID), ]
assert(all(flagged_events$IncidentID %in% incidents$IncidentID), "event IncidentIDs must exist")
assert(all(analytics$IncidentID == events$IncidentID[match(analytics$EventID, events$EventID)]), "analytics incident mapping must match events")
assert(all(events$RiskScore >= 0 & events$RiskScore <= 100) && all(incidents$RiskScore >= 0 & incidents$RiskScore <= 100), "risk scores must be bounded 0 through 100")
assert(all(!is.na(events$DetectionReason) & nzchar(events$DetectionReason)), "all event detection reasons must be populated")
assert(all(events$IsAnomaly == (events$RiskScore >= 35)), "IsAnomaly must match the documented threshold")
assert(all(events$EventDate %in% dates$Date) && all(incidents$IncidentDate %in% dates$Date), "date keys must be present in DateTable")
assert(all(as.POSIXct(events$Timestamp, format = "%Y-%m-%d %H:%M:%S", tz = "UTC") > as.POSIXct("2020-01-01", tz = "UTC")), "event timestamps must be valid")

ack <- as.POSIXct(incidents$AcknowledgedAt, format = "%Y-%m-%d %H:%M:%S", tz = "UTC")
resolved <- as.POSIXct(incidents$ResolvedAt, format = "%Y-%m-%d %H:%M:%S", tz = "UTC")
created <- as.POSIXct(incidents$CreatedAt, format = "%Y-%m-%d %H:%M:%S", tz = "UTC")
response <- as.numeric(incidents$ResponseMinutes); resolution <- as.numeric(incidents$ResolutionMinutes)
assert(all(is.na(response) | response >= 0) && all(is.na(resolution) | resolution >= 0), "response and resolution durations must be non-negative")
assert(all(is.na(ack) | ack >= created) && all(is.na(resolved) | resolved >= created), "lifecycle timestamps must follow CreatedAt")
assert(all(is.na(ack) | is.na(response) | abs(as.numeric(difftime(ack, created, units = "mins")) - response) < .01), "ResponseMinutes must agree with timestamps")
assert(all(is.na(resolved) | is.na(resolution) | abs(as.numeric(difftime(resolved, created, units = "mins")) - resolution) < .01), "ResolutionMinutes must agree with timestamps")

cat("Validation passed.\n")
cat("Events:", nrow(events), "| Anomalies:", sum(events$IsAnomaly), "| Incidents:", nrow(incidents), "| Ground-truth attack events:", sum(events$GroundTruthAttack), "\n")

