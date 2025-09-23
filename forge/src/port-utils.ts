import { execa } from "execa";
import chalk from "chalk";

export async function killPortProcesses(ports: (number | undefined)[]): Promise<void> {
  for (const port of ports) {
    try {
      console.log(chalk.yellow(`Killing processes on port ${port}...`));

      // Find processes on the port
      const { stdout } = await execa("lsof", ["-i", `:${port}`], {
        reject: false,
      });
      const lines = stdout
        .split("\n")
        .filter((line) => line.includes("LISTEN"));

      if (lines.length > 0) {
        const pids = lines.map((line) => line.split(/\s+/)[1]).filter(Boolean);
        if (pids.length > 0) {
          await execa("kill", ["-9", ...pids], { reject: false });
        }
      }
    } catch (error) {
      // Ignore errors - port might not be in use
    }
  }
}
