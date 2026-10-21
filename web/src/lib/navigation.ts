import { Activity, AlertTriangle, BarChart3, CloudCog, KeyRound, ShieldCheck } from "lucide-react";
import type { PageId } from "../types";

export const navigationPages: { id: PageId; label: string; icon: typeof Activity }[] = [
  { id: "overview", label: "Security Overview", icon: ShieldCheck },
  { id: "incidents", label: "Incident Analysis", icon: AlertTriangle },
  { id: "threats", label: "Threat Detection", icon: Activity },
  { id: "identity", label: "Identity & Access", icon: KeyRound },
  { id: "assets", label: "Cloud Asset Risk", icon: CloudCog },
  { id: "response", label: "Response & Analytics", icon: BarChart3 }
];
