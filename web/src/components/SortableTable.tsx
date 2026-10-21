import { useMemo, useState } from "react";
import { ArrowDownUp } from "lucide-react";

export interface Column<T> { key: keyof T | string; label: string; cell?: (row: T) => React.ReactNode; align?: "right" | "left"; }
export function SortableTable<T extends object>({ rows, columns, onRowClick, empty = "No records match the current filters." }: { rows: T[]; columns: Column<T>[]; onRowClick?: (row: T) => void; empty?: string }) {
  const [sort, setSort] = useState<{ key: string; asc: boolean }>({ key: String(columns[0]?.key ?? ""), asc: true });
  const sorted = useMemo(() => [...rows].sort((a, b) => {
    const av = String((a as Record<string, unknown>)[sort.key] ?? ""); const bv = String((b as Record<string, unknown>)[sort.key] ?? "");
    const result = av.localeCompare(bv, undefined, { numeric: true });
    return sort.asc ? result : -result;
  }), [rows, sort]);
  const changeSort = (key: string) => setSort(current => ({ key, asc: current.key === key ? !current.asc : true }));
  return <div className="table-wrap"><table><thead><tr>{columns.map(column => <th key={String(column.key)} className={column.align === "right" ? "align-right" : ""}><button onClick={() => changeSort(String(column.key))}>{column.label}<ArrowDownUp size={12} /></button></th>)}</tr></thead>
    <tbody>{sorted.length ? sorted.map((row, i) => <tr key={String((row as Record<string, unknown>)[String(columns[0].key)] ?? i)} onClick={() => onRowClick?.(row)} className={onRowClick ? "clickable-row" : ""}>{columns.map(column => <td key={String(column.key)} className={column.align === "right" ? "align-right" : ""}>{column.cell ? column.cell(row) : String((row as Record<string, unknown>)[String(column.key)] ?? "—")}</td>)}</tr>) : <tr><td colSpan={columns.length} className="empty-cell">{empty}</td></tr>}</tbody>
  </table></div>;
}

