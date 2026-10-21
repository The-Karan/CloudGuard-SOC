# CloudGuard SOC - cleansing, explainable detections, incidents and analytics
# Run after 01_generate_logs.R from the repository root: Rscript R/02_analyze_logs.R
# Uses base R only. RiskScore is a transparent heuristic, not a compromise probability.

dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)

read_required <- function(path, columns) {
  if (!file.exists(path)) stop("Required input is missing: ", path, ". Run R/01_generate_logs.R first.")
  x <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  missing <- setdiff(columns, names(x))
  if (length(missing)) stop("Schema error in ", path, ": missing ", paste(missing, collapse = ", "))
  x
}
required_event_columns <- c("EventID", "Timestamp", "EventType", "Action", "SourceIP", "UserID", "AssetID", "FailedAttempts", "BytesTransferred", "Result", "ScenarioID", "ScenarioTag", "GroundTruthAttack")
events <- read_required("data/raw/security_events.csv", required_event_columns)
users <- read_required("data/raw/users.csv", c("UserID", "Username", "Role", "Department", "IsPrivileged", "IsMFAEnabled", "HomeRegion", "AccountStatus"))
assets <- read_required("data/raw/cloud_assets.csv", c("AssetID", "AssetName", "ServiceType", "Region", "Criticality", "CloudAccount", "InternetExposed"))

if (anyDuplicated(events$EventID) || anyDuplicated(users$UserID) || anyDuplicated(assets$AssetID)) stop("Input identifiers must be unique.")
if (any(!events$UserID %in% users$UserID) || any(!events$AssetID %in% assets$AssetID)) stop("Input events contain an unknown user or asset.")
events$Timestamp <- as.POSIXct(events$Timestamp, format = "%Y-%m-%d %H:%M:%S", tz = "UTC")
if (anyNA(events$Timestamp)) stop("Timestamp parsing failed; timestamps must be UTC YYYY-MM-DD HH:MM:SS.")
events$FailedAttempts <- as.integer(events$FailedAttempts)
events$BytesTransferred <- as.numeric(events$BytesTransferred)
if (anyNA(events$FailedAttempts) | anyNA(events$BytesTransferred) | any(events$FailedAttempts < 0) | any(events$BytesTransferred < 0)) stop("FailedAttempts and BytesTransferred must be non-negative numbers.")
events <- events[order(events$Timestamp, events$EventID), ]

events$EventDate <- as.character(as.Date(events$Timestamp, tz = "UTC"))
events$HourUTC <- as.integer(format(events$Timestamp, "%H", tz = "UTC"))
events$UserName <- users$Username[match(events$UserID, users$UserID)]
events$UserRole <- users$Role[match(events$UserID, users$UserID)]
events$IsPrivilegedUser <- as.logical(users$IsPrivileged[match(events$UserID, users$UserID)])
events$AssetName <- assets$AssetName[match(events$AssetID, assets$AssetID)]
events$ServiceType <- assets$ServiceType[match(events$AssetID, assets$AssetID)]
events$Region <- assets$Region[match(events$AssetID, assets$AssetID)]
events$AssetCriticality <- assets$Criticality[match(events$AssetID, assets$AssetID)]

# Fixed UTC buckets give repeatable, interpretable aggregation results.
hour_bucket <- format(events$Timestamp, "%Y-%m-%d %H:00:00", tz = "UTC")
day_key <- paste(events$SourceIP, events$EventDate, sep = "|")
hour_key <- paste(events$SourceIP, hour_bucket, sep = "|")
failure_counts_hour <- tapply(as.integer(events$EventType == "LoginFailure"), hour_key, sum)
failure_counts_day <- tapply(as.integer(events$EventType == "LoginFailure"), day_key, sum)
deny_counts_hour <- tapply(as.integer(events$EventType == "AccessDenied"), hour_key, sum)
mfa_counts_hour <- tapply(as.integer(events$EventType == "MFAChallenge"), hour_key, sum)
events$FailedLoginsFromIPWindow <- as.integer(failure_counts_hour[hour_key]); events$FailedLoginsFromIPWindow[is.na(events$FailedLoginsFromIPWindow)] <- 0L
events$FailedLoginsFromIPPerDay <- as.integer(failure_counts_day[day_key]); events$FailedLoginsFromIPPerDay[is.na(events$FailedLoginsFromIPPerDay)] <- 0L
events$AccessDeniedFromIPWindow <- as.integer(deny_counts_hour[hour_key]); events$AccessDeniedFromIPWindow[is.na(events$AccessDeniedFromIPWindow)] <- 0L
events$MFAChallengesFromIPWindow <- as.integer(mfa_counts_hour[hour_key]); events$MFAChallengesFromIPWindow[is.na(events$MFAChallengesFromIPWindow)] <- 0L

events$AfterHours <- events$HourUTC < 6L | events$HourUTC >= 22L
events$RepeatedLoginFailures <- events$EventType == "LoginFailure" & events$FailedLoginsFromIPWindow >= 5L
events$PrivilegedAction <- events$EventType %in% c("PrivilegeChange", "SecurityGroupChange") & events$IsPrivilegedUser
events$LargeNetworkTransfer <- events$EventType == "NetworkFlow" & events$BytesTransferred >= 1500000
events$AccessDeniedBurst <- events$EventType == "AccessDenied" & events$AccessDeniedFromIPWindow >= 3L
events$SuspiciousMFA <- events$EventType == "MFAChallenge" & events$AfterHours & events$MFAChallengesFromIPWindow >= 3L
events$CriticalAssetActivity <- events$AssetCriticality == "Critical" & events$EventType %in% c("PrivilegeChange", "SecurityGroupChange", "NetworkFlow", "ObjectRead", "ObjectWrite")

# Additive components, documented in docs/DETECTION_METHODOLOGY.md; capped at 100.
score <- integer(nrow(events))
score <- score + ifelse(events$RepeatedLoginFailures, 45L, 0L)
score <- score + ifelse(events$PrivilegedAction, 35L, 0L)
score <- score + ifelse(events$LargeNetworkTransfer, 35L, 0L)
score <- score + ifelse(events$AccessDeniedBurst, 25L, 0L)
score <- score + ifelse(events$SuspiciousMFA, 25L, 0L)
score <- score + ifelse(events$AfterHours & (events$EventType %in% c("PrivilegeChange", "SecurityGroupChange", "NetworkFlow", "AccessDenied", "MFAChallenge")), 10L, 0L)
score <- score + ifelse(events$CriticalAssetActivity, 10L, ifelse(events$AssetCriticality == "High" & (events$PrivilegedAction | events$LargeNetworkTransfer), 5L, 0L))
events$RiskScore <- pmin(score, 100L)
events$IsAnomaly <- events$RiskScore >= 35L
events$RiskBand <- ifelse(events$RiskScore >= 75L, "Critical", ifelse(events$RiskScore >= 55L, "High", ifelse(events$RiskScore >= 35L, "Medium", "Low")))

reason_matrix <- cbind(
  ifelse(events$RepeatedLoginFailures, "Repeated login failures (>=5/source IP/hour)", ""),
  ifelse(events$PrivilegedAction, "Privileged configuration action", ""),
  ifelse(events$LargeNetworkTransfer, "Large network transfer (>=1.5 MB)", ""),
  ifelse(events$AccessDeniedBurst, "Access-denied burst (>=3/source IP/hour)", ""),
  ifelse(events$SuspiciousMFA, "After-hours MFA challenge sequence", ""),
  ifelse(events$AfterHours & events$RiskScore > 0, "After-hours activity", ""),
  ifelse(events$CriticalAssetActivity, "Critical-asset activity", "")
)
events$DetectionReason <- apply(reason_matrix, 1, function(x) { z <- x[nzchar(x)]; if (length(z)) paste(z, collapse = "; ") else "No rule triggered" })

events$DetectionCategory <- ifelse(events$RepeatedLoginFailures, "Brute-force / Login", ifelse(events$PrivilegedAction & events$EventType == "SecurityGroupChange", "Network Configuration", ifelse(events$PrivilegedAction, "Privilege Misuse", ifelse(events$LargeNetworkTransfer, "Unusual Data Transfer", ifelse(events$AccessDeniedBurst, "Access Abuse", ifelse(events$SuspiciousMFA, "Identity Security", "Suspicious Activity"))))))

# Related activity is deduplicated as category + source IP + asset + six-hour UTC window.
# Each anomalous event retains its IncidentID, explicitly forming a one-to-many mapping.
events$IncidentID <- ""
flagged <- which(events$IsAnomaly)
incident_bucket <- format(as.POSIXct(floor(as.numeric(events$Timestamp[flagged]) / (6 * 3600)) * (6 * 3600), origin = "1970-01-01", tz = "UTC"), "%Y-%m-%d %H:00:00", tz = "UTC")
incident_key <- paste(events$DetectionCategory[flagged], events$SourceIP[flagged], events$AssetID[flagged], incident_bucket, sep = "|")
unique_key <- unique(incident_key)
events$IncidentID[flagged] <- sprintf("INC%05d", match(incident_key, unique_key))

severity_rank <- c("Low" = 1L, "Medium" = 2L, "High" = 3L, "Critical" = 4L)
incident_rows <- lapply(seq_along(unique_key), function(i) {
  member <- flagged[incident_key == unique_key[i]]
  first_at <- min(events$Timestamp[member]); last_at <- max(events$Timestamp[member])
  max_score <- max(events$RiskScore[member])
  available_severities <- unique(events$RiskBand[member])
  severity <- names(severity_rank[available_severities])[which.max(severity_rank[available_severities])]
  # Deterministic lifecycle simulation avoids changing status and durations between reruns.
  status <- c("Resolved", "Resolved", "Resolved", "Investigating", "Open")[((i - 1L) %% 5L) + 1L]
  response_minutes <- 8L + ((i * 13L) %% 83L)
  acknowledged <- if (status == "Open") as.POSIXct(NA, origin = "1970-01-01", tz = "UTC") else first_at + response_minutes * 60
  resolution_minutes <- if (status == "Resolved") response_minutes + 55L + ((i * 29L) %% 510L) else NA_integer_
  resolved <- if (status == "Resolved") first_at + resolution_minutes * 60 else as.POSIXct(NA, origin = "1970-01-01", tz = "UTC")
  target_response <- if (severity %in% c("Critical", "High")) 30L else 60L
  target_resolution <- if (severity == "Critical") 240L else if (severity == "High") 480L else 720L
  data.frame(
    IncidentID = sprintf("INC%05d", i), RepresentativeEventID = events$EventID[member[which.max(events$RiskScore[member])]],
    CreatedAt = first_at, FirstSeenAt = first_at, LastSeenAt = last_at, IncidentDate = as.character(as.Date(first_at, tz = "UTC")),
    Severity = severity, Status = status, Category = events$DetectionCategory[member[which.max(events$RiskScore[member])]],
    UserID = events$UserID[member[1]], AssetID = events$AssetID[member[1]], SourceIP = events$SourceIP[member[1]], EventCount = length(member),
    RiskScore = max_score, RiskBand = events$RiskBand[member[which.max(events$RiskScore[member])]],
    DetectionReason = paste(unique(events$DetectionReason[member]), collapse = " | "), GroundTruthAttack = any(events$GroundTruthAttack[member]),
    ScenarioIDs = paste(unique(events$ScenarioID[member][events$GroundTruthAttack[member]]), collapse = ";"),
    AcknowledgedAt = acknowledged, ResolvedAt = resolved, ResponseMinutes = if (is.na(acknowledged)) NA_integer_ else response_minutes,
    ResolutionMinutes = resolution_minutes, ResponseTargetMinutes = target_response, ResolutionTargetMinutes = target_resolution,
    SLAStatus = if (status == "Open") "In progress" else if (response_minutes > target_response || (!is.na(resolution_minutes) && resolution_minutes > target_resolution)) "Breached" else "Met",
    stringsAsFactors = FALSE
  )
})
incidents <- do.call(rbind, incident_rows)
time_columns <- c("CreatedAt", "FirstSeenAt", "LastSeenAt", "AcknowledgedAt", "ResolvedAt")
for (col in time_columns) incidents[[col]] <- ifelse(is.na(incidents[[col]]), "", format(incidents[[col]], "%Y-%m-%d %H:%M:%S", tz = "UTC"))
incidents$ScenarioIDs[!nzchar(incidents$ScenarioIDs)] <- ""

analytics <- events[, c("EventID", "IncidentID", "RiskScore", "RiskBand", "IsAnomaly", "DetectionReason", "DetectionCategory", "GroundTruthAttack", "ScenarioID", "AfterHours", "RepeatedLoginFailures", "PrivilegedAction", "LargeNetworkTransfer", "AccessDeniedBurst", "SuspiciousMFA", "CriticalAssetActivity", "FailedLoginsFromIPWindow", "FailedLoginsFromIPPerDay", "MFAChallengesFromIPWindow")]
events_out <- events
events_out$Timestamp <- format(events_out$Timestamp, "%Y-%m-%d %H:%M:%S", tz = "UTC")

dates <- seq(as.Date(min(events$Timestamp), tz = "UTC"), as.Date(max(events$Timestamp), tz = "UTC"), by = "day")
date_table <- data.frame(Date = as.character(dates), Year = as.integer(format(dates, "%Y")), MonthNumber = as.integer(format(dates, "%m")), Month = format(dates, "%b"), YearMonth = format(dates, "%Y-%m"), Quarter = paste0("Q", ceiling(as.integer(format(dates, "%m")) / 3)), Day = as.integer(format(dates, "%d")), Weekday = format(dates, "%A"), stringsAsFactors = FALSE)

write.csv(events_out, "data/processed/SecurityEvents.csv", row.names = FALSE, na = "")
write.csv(incidents, "data/processed/Incidents.csv", row.names = FALSE, na = "")
write.csv(analytics, "data/processed/R_Analytics.csv", row.names = FALSE, na = "")
write.csv(users, "data/processed/Users.csv", row.names = FALSE, na = "")
write.csv(assets, "data/processed/CloudAssets.csv", row.names = FALSE, na = "")
write.csv(date_table, "data/processed/DateTable.csv", row.names = FALSE, na = "")

cat("Analytics complete. Events:", nrow(events_out), "| anomalous events:", sum(events_out$IsAnomaly), "| deduplicated incidents:", nrow(incidents), "\n")
cat("Processed Power BI contracts written to data/processed/.\n")

