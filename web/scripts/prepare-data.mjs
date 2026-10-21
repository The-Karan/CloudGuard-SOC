// Fallback when R/04_prepare_dashboard_data.R is unavailable.
import { copyFile, mkdir, access, writeFile } from "node:fs/promises";
import { constants } from "node:fs";
import { resolve } from "node:path";

const root = resolve(import.meta.dirname, "../..");
const names = ["SecurityEvents.csv", "Incidents.csv", "R_Analytics.csv", "Users.csv", "CloudAssets.csv", "DateTable.csv"];
const from = resolve(root, "data/processed");
const to = resolve(root, "web/public/data");
await mkdir(to, { recursive: true });
for (const name of names) {
  const source = resolve(from, name);
  await access(source, constants.R_OK);
  await copyFile(source, resolve(to, name));
}
await writeFile(resolve(to, "manifest.json"), JSON.stringify({ generatedAt: new Date().toISOString(), synthetic: true, files: names }, null, 2));
console.log("Prepared " + names.length + " dashboard data files in web/public/data.");

