# Detection and incident methodology

## Rule scoring

RiskScore is an additive, capped (0–100) heuristic—not a probability of compromise.

| Signal | Points | Trigger |
|---|---:|---|
| Repeated login failures | 45 | LoginFailure and at least 5 failures from a source IP in a UTC hour |
| Privileged configuration action | 35 | Privileged user performs PrivilegeChange or SecurityGroupChange |
| Large network transfer | 35 | NetworkFlow transfers at least 1,500,000 bytes |
| Access-denied burst | 25 | At least 3 AccessDenied events from a source IP in a UTC hour |
| Suspicious MFA | 25 | At least 3 after-hours MFA challenges from a source IP in a UTC hour |
| After-hours context | 10 | 22:00–05:59 UTC for a security-sensitive action |
| Critical-asset context | 10 | Defined activity on a critical asset |
| High-asset context | 5 | Privileged action or large transfer on a high asset |

Events at 35 or higher are anomalous. Bands: Low 0–34, Medium 35–54, High 55–74, Critical 75–100. DetectionReason records every contributing rule in plain language.

## Correlation and lifecycle

An incident groups anomalous events with the same detection category, source IP, asset, and six-hour UTC time bucket. This prevents a separate arbitrary incident for every matching event. Each anomalous event includes its IncidentID; each incident carries a representative event and evidence count.

Status, acknowledgement, and resolution values are deterministic synthetic workflow data. Targets are 30 minutes response for critical/high incidents and 60 minutes otherwise; resolution targets are 4 hours for critical, 8 for high, and 12 for all other severities.

## Ground truth evaluation

The generator labels injected scenarios using GroundTruthAttack and ScenarioID. Precision is detected labeled events divided by all detected events; recall is detected labeled events divided by all labeled attack events. This is event-level exact matching and evaluates only the synthetic dataset. Rule-generated detections are leads, not confirmed compromises.

