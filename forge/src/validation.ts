import { execa } from "execa";
import chalk from "chalk";
import {
  getBranchChangedFiles,
  getChangedFrontendFiles,
  getChangedJsTsFiles,
  showChangedFilesPreview,
  showModifiedFiles,
  commitWithLint,
} from "./git-utils.js";
import { Config, ValidationCommand } from "./config.js";

export interface ValidationOptions {
  full?: boolean;
  quick?: boolean;
  autoCommit?: boolean;
  config: Config;
}

export async function runValidation(
  options: ValidationOptions
): Promise<boolean> {
  const { full = false, quick = false, autoCommit = false, config } = options;

  const changedFiles = await getBranchChangedFiles();
  if (changedFiles.length === 0) {
    console.log(
      chalk.yellow("⚠️  No changed files found to validate. Exiting.")
    );
    return true;
  }

  console.log(chalk.blue("📦 Installing dependencies..."));
  try {
    await execa("npm", ["install"], { stdio: "inherit" });
  } catch (error) {
    console.error("Failed to install dependencies:", error);
    return false;
  }

  await showChangedFilesPreview();

  const frontendFiles = await getChangedFrontendFiles();
  const jsTsFiles = await getChangedJsTsFiles();

  const commands = config.validation.commands
    .filter((cmd) => !quick || cmd.quickMode !== false)
    .map((cmd) => ({
      name: cmd.name,
      command: cmd.command
        .replace("{files}", frontendFiles.join(" "))
        .replace("{files_js}", jsTsFiles.join(" ")),
    }));

  const success = await runConcurrentValidation(commands);

  await showModifiedFiles();

  if (success) {
    await commitWithLint(autoCommit);
  }

  return success;
}

import Spinnies from "spinnies";

// Color utility functions
function createColorMap(): Record<string, (text: string) => string> {
  return {
    blue: chalk.blue,
    green: chalk.green,
    yellow: chalk.yellow,
    magenta: chalk.magenta,
    cyan: chalk.cyan,
    red: chalk.red,
    white: chalk.white,
    gray: chalk.gray,
    grey: chalk.grey,
    black: chalk.black,
    bgBlue: chalk.bgBlue,
    bgGreen: chalk.bgGreen,
    bgYellow: chalk.bgYellow,
    bgMagenta: chalk.bgMagenta,
    bgCyan: chalk.bgCyan,
    bgRed: chalk.bgRed,
    bgWhite: chalk.bgWhite,
    bgGray: chalk.bgGray,
    bgGrey: chalk.bgGrey,
    bgBlack: chalk.bgBlack,
  };
}

function getChalkColor(colorName?: string): ((text: string) => string) | null {
  if (!colorName) return null;

  const colorMap = createColorMap();
  return colorMap[colorName] || null;
}

function getDefaultColors(): Array<(text: string) => string> {
  return [
    chalk.bgBlue,
    chalk.bgGreen,
    chalk.bgYellow,
    chalk.bgMagenta,
    chalk.bgCyan,
    chalk.bgRed,
    chalk.bgWhite,
    chalk.bgGray,
  ];
}

async function runConcurrentValidation(
  commands: ValidationCommand[]
): Promise<boolean> {
  console.log(chalk.blue("\n🚀 Running validation commands...\n"));

  const spinnies = new Spinnies();
  commands.forEach((cmd) => {
    spinnies.add(cmd.name, {
      text: `🚀 ${cmd.name}: in progress...`,
      spinnerColor: "blue",
    });
  });

  const defaultColors = getDefaultColors();
  // Find the max label width (including brackets)
  const maxLabelLength = Math.max(
    ...commands.map((cmd) => `[${cmd.name}]`.length)
  );

  function getPaddedLabelParts(cmdName: string): {
    colored: string;
    padding: string;
  } {
    const label = `[${cmdName}]`;
    const padding = " ".repeat(maxLabelLength - label.length);
    return { colored: label, padding };
  }

  const promises = commands.map((cmd, index) => {
    const labelColor =
      getChalkColor(cmd.color) || defaultColors[index % defaultColors.length];

    // Split command into parts for execa
    const [command, ...args] = cmd.command.split(" ");
    return execa(command, args, {
      stdio: "pipe", // Capture output instead of inheriting
      shell: true,
    })
      .then((result) => {
        // Process stdout and stderr with colored labels
        if (result.stdout) {
          const lines = result.stdout.split("\n");
          lines.forEach((line: string) => {
            if (line.trim()) {
              const { colored, padding } = getPaddedLabelParts(cmd.name);
              process.stdout.write(
                labelColor(colored) + padding + " " + line + "\n"
              );
            }
          });
        }
        if (result.stderr) {
          const lines = result.stderr.split("\n");
          lines.forEach((line: string) => {
            if (line.trim()) {
              const { colored, padding } = getPaddedLabelParts(cmd.name);
              process.stdout.write(
                labelColor(colored) + padding + " " + line + "\n"
              );
            }
          });
        }

        spinnies.succeed(cmd.name, { text: `✅ ${cmd.name} succeeded` });
        return { name: cmd.name, success: true };
      })
      .catch((error) => {
        // Handle error output with colored labels
        if (error.stdout) {
          const lines = error.stdout.split("\n");
          lines.forEach((line: string) => {
            if (line.trim()) {
              const { colored, padding } = getPaddedLabelParts(cmd.name);
              process.stdout.write(
                labelColor(colored) + padding + " " + line + "\n"
              );
            }
          });
        }
        if (error.stderr) {
          const lines = error.stderr.split("\n");
          lines.forEach((line: string) => {
            if (line.trim()) {
              const { colored, padding } = getPaddedLabelParts(cmd.name);
              process.stdout.write(
                labelColor(colored) + padding + " " + line + "\n"
              );
            }
          });
        }

        const errorMessage =
          error instanceof Error ? error.message : String(error);
        spinnies.fail(cmd.name, {
          text: `❌ ${cmd.name} failed: ${errorMessage}`,
        });
        return { name: cmd.name, success: false, error };
      });
  });

  const results = await Promise.all(promises);

  const failed = results.filter((r) => !r.success);

  console.log("\n========================================\n");

  if (failed.length === 0) {
    console.log(chalk.green("✅ Validation completed successfully."));
    console.log(chalk.green("Good to go."));
    return true;
  } else {
    return false;
  }
}
