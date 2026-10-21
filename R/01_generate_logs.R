# CloudGuard SOC - deterministic synthetic cloud telemetry generator
# Run from the repository root: Rscript R/01_generate_logs.R
# Uses base R only. All values, identities, IP addresses and activity are synthetic.

set.seed(20261021)

dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)
dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)

make_id <- function(prefix, n, width) sprintf(paste0(prefix, "%0", width, "d"), seq_len(n))
utc_string <- function(x) format(x, "%Y-%m-%d %H:%M:%S", tz = "UTC")

n_users <- 54L
n_assets <- 24L
n_baseline_events <- 5200L

roles <- c("Developer", "Security Analyst", "Cloud Admin", "Finance Analyst", "Data Engineer", "Read Only", "Service Account")
users <- data.frame(
  UserID = make_id("USR", n_users, 3),
  Username = sprintf("%s.%02d", c("alex", "sam", "jordan", "casey", "riley", "morgan")[rep(seq_len(6), length.out = n_users)], seq_len(n_users)),
  Role = sample(roles, n_users, replace = TRUE, prob = c(.22, .12, .10, .12, .18, .16, .10)),
  Department = sample(c("Engineering", "Security", "Finance", "Operations", "Data", "Platform"), n_users, replace = TRUE),
  IsPrivileged = FALSE,
  IsMFAEnabled = sample(c(TRUE, FALSE), n_users, replace = TRUE, prob = c(.91, .09)),
  HomeRegion = sample(c("ap-south-1", "ap-southeast-1", "us-east-1", "eu-west-1"), n_users, replace = TRUE),
  AccountStatus = "Active",
  stringsAsFactors = FALSE
)
privileged <- unique(c(which(users$Role == "Cloud Admin"), sample(seq_len(n_users), 7)))
users$IsPrivileged[privileged] <- TRUE
users$Role[privileged] <- "Cloud Admin"

asset_names <- c("prod-api-01", "prod-api-02", "auth-service", "billing-db", "customer-db", "analytics-bucket", "backup-bucket", "web-frontend", "worker-01", "worker-02", "admin-console", "logging-store", "dev-api-01", "test-db", "queue-service", "vpn-gateway", "secrets-vault", "monitoring-node", "payments-api", "data-lake", "ci-runner", "identity-provider", "edge-firewall", "kubernetes-control")
service_types <- c("Compute", "Compute", "Identity", "Database", "Database", "Storage", "Storage", "Compute", "Compute", "Compute", "Identity", "Storage", "Compute", "Database", "Messaging", "Network", "Secrets", "Monitoring", "Compute", "Storage", "Compute", "Identity", "Network", "Container")
assets <- data.frame(
  AssetID = make_id("AST", n_assets, 3),
  AssetName = asset_names,
  ServiceType = service_types,
  Region = rep(c("ap-south-1", "ap-southeast-1", "us-east-1", "eu-west-1"), length.out = n_assets),
  Criticality = sample(c("Critical", "High", "Medium", "Low"), n_assets, replace = TRUE, prob = c(.18, .30, .34, .18)),
  CloudAccount = rep(c("CG-Production", "CG-Shared", "CG-Development"), length.out = n_assets),
  InternetExposed = service_types %in% c("Compute", "Network", "Identity"),
  stringsAsFactors = FALSE
)
assets$Criticality[assets$AssetName %in% c("customer-db", "secrets-vault", "identity-provider")] <- "Critical"

# Baseline business activity favours working hours but still contains ordinary overnight operations.
start_time <- as.POSIXct("2026-09-21 00:00:00", tz = "UTC")
day_offsets <- sample(0:29, n_baseline_events, replace = TRUE)
hours <- sample(0:23, n_baseline_events, replace = TRUE,
                prob = c(rep(1, 6), rep(5, 12), rep(2, 4), rep(1, 2)))
event_times <- start_time + day_offsets * 86400 + hours * 3600 + sample(0:3599, n_baseline_events, replace = TRUE)
event_types <- sample(c("LoginSuccess", "LoginFailure", "AccessDenied", "PrivilegeChange", "ObjectRead", "ObjectWrite", "NetworkFlow", "SecurityGroupChange", "KeyRotation", "MFAChallenge"),
                      n_baseline_events, replace = TRUE,
                      prob = c(.27, .12, .08, .025, .17, .10, .11, .018, .04, .04))
user_index <- sample(seq_len(n_users), n_baseline_events, replace = TRUE)
asset_index <- sample(seq_len(n_assets), n_baseline_events, replace = TRUE)
normal_ip_pool <- c("10.20.14.11", "10.20.14.12", "10.20.15.21", "10.21.4.18", "172.16.20.8", "172.16.21.9", "198.51.100.20", "198.51.100.31")

baseline <- data.frame(
  Timestamp = event_times,
  EventType = event_types,
  SourceIP = sample(normal_ip_pool, n_baseline_events, replace = TRUE),
  UserID = users$UserID[user_index],
  AssetID = assets$AssetID[asset_index],
  FailedAttempts = ifelse(event_types == "LoginFailure", sample(1:3, n_baseline_events, replace = TRUE), 0L),
  BytesTransferred = ifelse(event_types == "NetworkFlow", round(rlnorm(n_baseline_events, log(260000), .72)), sample(0:9000, n_baseline_events, replace = TRUE)),
  Result = ifelse(event_types == "LoginFailure", "Failure", ifelse(event_types == "AccessDenied", "Denied", "Success")),
  Action = ifelse(event_types == "ObjectRead", "GetObject", ifelse(event_types == "ObjectWrite", "PutObject", ifelse(event_types == "NetworkFlow", "Network connection", event_types))),
  ScenarioID = "NORMAL",
  ScenarioTag = "Normal baseline activity",
  GroundTruthAttack = FALSE,
  stringsAsFactors = FALSE
)

scenario_rows <- function(times, type, ip, user_id, asset_id, attempts = 0L, bytes = 0L, action = type, scenario_id, scenario_tag) {
  n <- length(times)
  data.frame(
    Timestamp = times, EventType = rep(type, n), SourceIP = rep(ip, n), UserID = rep(user_id, n), AssetID = rep(asset_id, n),
    FailedAttempts = rep(attempts, n), BytesTransferred = rep(bytes, n),
    Result = ifelse(type == "LoginFailure", "Failure", ifelse(type == "AccessDenied", "Denied", "Success")), Action = rep(action, n),
    ScenarioID = rep(scenario_id, n), ScenarioTag = rep(scenario_tag, n), GroundTruthAttack = TRUE, stringsAsFactors = FALSE
  )
}

# Injected scenarios are kept as ground-truth labels, independently of detection rules.
brute_times <- as.POSIXct("2026-10-08 02:10:00", tz = "UTC") + c(0, 85, 170, 245, 330, 415, 515, 650, 760, 870, 980, 1080)
brute <- scenario_rows(brute_times, "LoginFailure", "203.0.113.42", users$UserID[4], assets$AssetID[22], 6L, scenario_id = "SCN-BRUTE-01", scenario_tag = "Injected credential-stuffing campaign")
brute2_times <- as.POSIXct("2026-10-16 23:15:00", tz = "UTC") + seq(0, 720, by = 80)
brute2 <- scenario_rows(brute2_times, "LoginFailure", "185.77.21.14", users$UserID[16], assets$AssetID[16], 7L, scenario_id = "SCN-BRUTE-02", scenario_tag = "Injected repeated VPN login failures")
priv_times <- as.POSIXct("2026-10-11 01:20:00", tz = "UTC") + seq(0, 300, by = 60)
privilege <- scenario_rows(priv_times, "PrivilegeChange", "91.204.18.77", users$UserID[privileged[1]], assets$AssetID[17], action = "AttachAdministratorPolicy", scenario_id = "SCN-PRIV-01", scenario_tag = "Injected privileged role escalation")
exfil_times <- as.POSIXct("2026-10-13 03:40:00", tz = "UTC") + seq(0, 420, by = 70)
exfil <- scenario_rows(exfil_times, "NetworkFlow", "198.18.0.44", users$UserID[12], assets$AssetID[20], bytes = 7900000L, action = "Large outbound data transfer", scenario_id = "SCN-EXFIL-01", scenario_tag = "Injected unusual data transfer")
sg_times <- as.POSIXct("2026-10-18 00:35:00", tz = "UTC") + seq(0, 240, by = 60)
sg <- scenario_rows(sg_times, "SecurityGroupChange", "203.0.113.89", users$UserID[privileged[2]], assets$AssetID[23], action = "AuthorizeSecurityGroupIngress", scenario_id = "SCN-NET-01", scenario_tag = "Injected firewall rule weakening")
denied_times <- as.POSIXct("2026-10-05 22:40:00", tz = "UTC") + seq(0, 300, by = 60)
denied <- scenario_rows(denied_times, "AccessDenied", "192.0.2.56", users$UserID[28], assets$AssetID[5], action = "Access customer records denied", scenario_id = "SCN-ACCESS-01", scenario_tag = "Injected access-probing activity")
mfa_times <- as.POSIXct("2026-10-19 02:05:00", tz = "UTC") + seq(0, 240, by = 60)
mfa <- scenario_rows(mfa_times, "MFAChallenge", "198.18.0.77", users$UserID[33], assets$AssetID[22], action = "Repeated MFA challenge", scenario_id = "SCN-MFA-01", scenario_tag = "Injected unusual MFA challenge sequence")

events <- do.call(rbind, list(baseline, brute, brute2, privilege, exfil, sg, denied, mfa))
events <- events[order(events$Timestamp), ]
events$EventID <- make_id("EVT", nrow(events), 6)
events <- events[, c("EventID", "Timestamp", "EventType", "Action", "SourceIP", "UserID", "AssetID", "FailedAttempts", "BytesTransferred", "Result", "ScenarioID", "ScenarioTag", "GroundTruthAttack")]
events$Timestamp <- utc_string(events$Timestamp)

write.csv(events, "data/raw/security_events.csv", row.names = FALSE, na = "")
write.csv(users, "data/raw/users.csv", row.names = FALSE, na = "")
write.csv(assets, "data/raw/cloud_assets.csv", row.names = FALSE, na = "")

cat("Generated", nrow(events), "synthetic cloud-security events.\n")
cat("Injected scenarios:", length(unique(events$ScenarioID[events$GroundTruthAttack])), "| labeled attack events:", sum(events$GroundTruthAttack), "\n")
cat("Raw data written to data/raw/. All records are synthetic.\n")

