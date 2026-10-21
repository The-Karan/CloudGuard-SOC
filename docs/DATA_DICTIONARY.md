# Data dictionary

All records are synthetic. Values labelled GroundTruthAttack are controlled demonstration labels, not production findings.

## SecurityEvents.csv

One row per cloud telemetry event. Key fields include EventID (unique key), Timestamp and EventDate (UTC), EventType, Action, SourceIP, UserID, AssetID, Result, FailedAttempts, BytesTransferred, ScenarioID, ScenarioTag, GroundTruthAttack, joined UserName/UserRole and asset Region/ServiceType/Criticality.

Analytics fields: FailedLoginsFromIPWindow, FailedLoginsFromIPPerDay, AccessDeniedFromIPWindow, MFAChallengesFromIPWindow, AfterHours, RepeatedLoginFailures, PrivilegedAction, LargeNetworkTransfer, AccessDeniedBurst, SuspiciousMFA, CriticalAssetActivity, RiskScore, RiskBand, IsAnomaly, DetectionReason, DetectionCategory and IncidentID.

## Incidents.csv

One row per correlated incident. IncidentID is unique; RepresentativeEventID points to SecurityEvents. CreatedAt, FirstSeenAt, LastSeenAt, IncidentDate, Severity, Status, Category, UserID, AssetID, SourceIP, EventCount, RiskScore, RiskBand and DetectionReason describe the detection. GroundTruthAttack and ScenarioIDs support synthetic evaluation.

AcknowledgedAt, ResolvedAt, ResponseMinutes, ResolutionMinutes, ResponseTargetMinutes, ResolutionTargetMinutes and SLAStatus support response analytics. Blank lifecycle timestamps and durations mean they are not yet applicable.

## R_Analytics.csv

A one-to-one event analytics extension keyed by EventID. It preserves IncidentID, risk, anomaly, ground-truth, detection category/reason, all rule indicators, and failed-login aggregate values.

## Users.csv

Synthetic identity dimension keyed by UserID: Username, Role, Department, IsPrivileged, IsMFAEnabled, HomeRegion and AccountStatus.

## CloudAssets.csv

Synthetic asset dimension keyed by AssetID: AssetName, ServiceType, Region, Criticality, CloudAccount and InternetExposed.

## DateTable.csv

Contiguous UTC calendar keyed by Date with Year, MonthNumber, Month, YearMonth, Quarter, Day and Weekday.

