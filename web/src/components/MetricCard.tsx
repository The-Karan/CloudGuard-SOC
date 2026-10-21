import type { ReactNode } from "react";

export function MetricCard({ label, value, detail, tone = "blue", icon }: { label: string; value: string | number; detail?: string; tone?: "blue" | "red" | "amber" | "green"; icon?: ReactNode }) {
  return <section className={"metric-card tone-" + tone}>
    <div className="metric-top"><span>{label}</span><span className="metric-icon">{icon}</span></div>
    <strong>{value}</strong>
    {detail && <small>{detail}</small>}
  </section>;
}

