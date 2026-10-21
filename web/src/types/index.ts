export type PageId = "overview" | "incidents" | "threats" | "identity" | "assets" | "response";

export type Severity = "Critical" | "High" | "Medium" | "Low";
export type IncidentStatus = "Open" | "Investigating" | "Resolved";

export interface SecurityEvent {
  EventID: string;
  Timestamp: string;
  EventDate: string;
  EventType: string;
  Action: string;
  SourceIP: string;
  UserID: string;
  UserName: string;
  UserRole: string;
  AssetID: string;
  AssetName: string;
  ServiceType: string;
  Region: string;
  AssetCriticality: string;
  Result: string;
  IncidentID: string;
  RiskScore: number;
  RiskBand: Severity;
  IsAnomaly: boolean;
  DetectionReason: string;
  DetectionCategory: string;
  GroundTruthAttack: boolean;
  ScenarioID: string;
  FailedLoginsFromIPWindow: number;
  FailedLoginsFromIPPerDay: number;
  BytesTransferred: number;
  AfterHours: boolean;
  PrivilegedAction: boolean;
  LargeNetworkTransfer: boolean;
  AccessDeniedBurst: boolean;
}

export interface Incident {
  IncidentID: string;
  RepresentativeEventID: string;
  CreatedAt: string;
  FirstSeenAt: string;
  LastSeenAt: string;
  IncidentDate: string;
  Severity: Severity;
  Status: IncidentStatus;
  Category: string;
  UserID: string;
  AssetID: string;
  SourceIP: string;
  EventCount: number;
  RiskScore: number;
  RiskBand: Severity;
  DetectionReason: string;
  GroundTruthAttack: boolean;
  ScenarioIDs: string;
  AcknowledgedAt: string;
  ResolvedAt: string;
  ResponseMinutes: number | null;
  ResolutionMinutes: number | null;
  ResponseTargetMinutes: number;
  ResolutionTargetMinutes: number;
  SLAStatus: string;
}

export interface User {
  UserID: string;
  Username: string;
  Role: string;
  Department: string;
  IsPrivileged: boolean;
  IsMFAEnabled: boolean;
  HomeRegion: string;
  AccountStatus: string;
}

export interface CloudAsset {
  AssetID: string;
  AssetName: string;
  ServiceType: string;
  Region: string;
  Criticality: string;
  CloudAccount: string;
  InternetExposed: boolean;
}

export interface DashboardData {
  events: SecurityEvent[];
  incidents: Incident[];
  users: User[];
  assets: CloudAsset[];
  generatedAt: string | null;
}

export interface Filters {
  from: string;
  to: string;
  severity: string;
  status: string;
  region: string;
  service: string;
  category: string;
}

export const emptyFilters: Filters = { from: "", to: "", severity: "", status: "", region: "", service: "", category: "" };

