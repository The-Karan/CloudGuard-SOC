import { describe, expect, it } from "vitest";
import { filterEvents, filterIncidents } from "./data";
import { emptyFilters, type CloudAsset, type Incident, type SecurityEvent } from "../types";

const event = { EventID: "EVT1", EventDate: "2026-10-10", RiskBand: "High", Region: "ap-south-1", ServiceType: "Storage", DetectionCategory: "Unusual Data Transfer" } as SecurityEvent;
const incident = { IncidentID: "INC1", IncidentDate: "2026-10-10", Severity: "High", Status: "Open", Category: "Unusual Data Transfer", AssetID: "AST1" } as Incident;
const asset = { AssetID: "AST1", Region: "ap-south-1", ServiceType: "Storage" } as CloudAsset;

describe("dashboard filters", () => {
  it("applies date and global dimension filters to events", () => {
    expect(filterEvents([event], { ...emptyFilters, from: "2026-10-01", to: "2026-10-20", severity: "High", region: "ap-south-1" })).toEqual([event]);
    expect(filterEvents([event], { ...emptyFilters, severity: "Critical" })).toEqual([]);
  });
  it("applies status and asset-derived region filters to incidents", () => {
    expect(filterIncidents([incident], [asset], { ...emptyFilters, status: "Open", service: "Storage" })).toEqual([incident]);
    expect(filterIncidents([incident], [asset], { ...emptyFilters, region: "eu-west-1" })).toEqual([]);
  });
});

