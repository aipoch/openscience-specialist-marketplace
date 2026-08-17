export function assertSafeRelativePath(value, label = "path") {
  if (typeof value !== "string" || value.length === 0) {
    throw new Error(`${label} must be a non-empty relative POSIX path`);
  }
  if (
    value.startsWith("/") ||
    /^[A-Za-z]:/.test(value) ||
    value.includes("\\") ||
    value.includes("\0")
  ) {
    throw new Error(`unsafe ${label}: ${value}`);
  }
  const segments = value.split("/");
  if (
    segments.some((segment) => !segment || segment === "." || segment === "..")
  ) {
    throw new Error(`unsafe ${label}: ${value}`);
  }
  return value;
}
