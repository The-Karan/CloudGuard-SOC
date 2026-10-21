export function Badge({ value }: { value: string }) {
  const key = value.toLowerCase().replace(/ /g, "-");
  return <span className={"badge badge-" + key}>{value}</span>;
}

