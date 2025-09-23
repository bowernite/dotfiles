import { execa } from "execa";

/**
 * Executes a shell command with stdio set to inherit
 */
export async function executeShellCommand(
  command: string,
  options?: import("execa").Options
): Promise<void> {
  await execa("sh", ["-c", command], {
    ...options,
    stdio: "inherit",
  });
}
