import { execa } from "execa";

export async function getNodeBinRunner(binName: string): Promise<string> {
  if (await isRunnerAvailable("npx")) {
    return `npx ${binName}`;
  }

  if (await isRunnerAvailable("bun")) {
    return `bun ${binName}`;
  }

  // Fallback to npx if neither is detected
  return `npx ${binName}`;

  async function isRunnerAvailable(cmd: string) {
    try {
      await execa(cmd, ["--version"], { stdio: "ignore" });
      return true;
    } catch {
      return false;
    }
  }
}

export function generateRunNodeCommand({
  directory,
  stringCommand,
}: {
  directory?: string;
  stringCommand: string;
}): string {
  return `zsh -c '${runWithFnm(
    `${directory ? `cd ${directory} && ` : ""}${stringCommand}`
  )}'`;
}

/**
 * Wraps a command to run with fnm environment and automatic Node.js version detection
 * @param command - The command to execute
 * @returns The wrapped command that will use fnm for Node.js version management
 */
function runWithFnm(command: string): string {
  return `eval "$(fnm env --use-on-cd --version-file-strategy=recursive --shell zsh)" && ${command}`;
}

/**
 * Creates a shell command that changes to a directory and runs a command with fnm
 * @param directory - The directory to change to
 * @param command - The command to execute
 * @returns A complete shell command with fnm environment setup
 */
export function runInDirectoryWithFnm(
  directory: string,
  command: string
): string {
  return `zsh -c '${runWithFnm(`cd ${directory} && ${command}`)}'`;
}
