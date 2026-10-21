import { describe, expect, it } from "vitest";
import { navigationPages } from "./navigation";

describe("dashboard navigation", () => {
  it("exposes each of the six dashboard pages exactly once", () => {
    expect(navigationPages.map(page => page.id)).toEqual(["overview", "incidents", "threats", "identity", "assets", "response"]);
    expect(new Set(navigationPages.map(page => page.id)).size).toBe(6);
  });
});
