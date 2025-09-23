import { execa } from "execa";
import chalk from "chalk";
import concurrently from "concurrently";
import { Config, Service } from "./config.js";
import { killPortProcesses } from "./port-utils.js";
import { generateRunNodeCommand } from "./node-utils.js";
import { executeShellCommand } from "./shell-utils.js";

// Constants
const LOGS_DIR = "logs";
const PORT_CLEANUP_DELAY = 1000;

export interface StartupOptions {
  service?: string;
  config: Config;
}

async function prepareLogDirectory(
  serviceName: string,
  serviceDirectory: string
): Promise<void> {
  try {
    await execa("mkdir", ["-p", `${serviceDirectory}/${LOGS_DIR}`]);
    await execa("touch", [
      `${serviceDirectory}/${LOGS_DIR}/${serviceName}.log`,
    ]);
  } catch (error) {
    console.warn(
      chalk.yellow(`Warning: Could not prepare logs for ${serviceName}`)
    );
  }
}

function buildServiceCommand(service: Service): string {
  const installCmd = service.installCommand ? `${service.installCommand}` : "";

  let command = installCmd
    ? `${installCmd} && ${service.startCommand}`
    : service.startCommand;

  return generateRunNodeCommand({ directory: service.directory, stringCommand: command });
}

export async function startServices(options: StartupOptions): Promise<void> {
  const { service, config } = options;

  if (service) {
    await startSingleService(service, config);
  } else {
    await startAllServices(config);
  }
}

async function startSingleService(
  serviceName: string,
  config: Config
): Promise<void> {
  const service = config.services[serviceName];
  if (!service) {
    console.error(chalk.red(`❌ Unknown service: ${serviceName}`));
    console.log(
      chalk.yellow("Available services:"),
      Object.keys(config.services).join(", ")
    );
    process.exit(1);
  }

  // Kill existing processes on the port
  if (service.port) {
    await killPortProcesses([service.port]);
    await new Promise((resolve) => setTimeout(resolve, PORT_CLEANUP_DELAY));
  }

  // Install dependencies if command is provided
  if (service.installCommand) {
    console.log(chalk.blue(`📦 Installing dependencies for ${serviceName}...`));
    try {
      const installCommand = generateRunNodeCommand({
        stringCommand: service.installCommand,
      });

      await executeShellCommand(installCommand, { cwd: service.directory });
    } catch (error) {
      console.error(
        chalk.red(`Failed to install dependencies for ${serviceName}:`),
        error
      );
      throw new Error(`Dependency installation failed for ${serviceName}`);
    }
  }

  console.log(chalk.blue(`🚀 Starting ${serviceName}...`));
  try {
    await runWithLogging(serviceName, service.directory, service.startCommand);
  } catch (error) {
    console.error(chalk.red(`Failed to start ${serviceName}:`), error);
    throw new Error(`Service startup failed for ${serviceName}`);
  }
}

async function startAllServices(config: Config): Promise<void> {
  console.log(chalk.blue("🛑 Stopping any existing processes..."));

  await killPortProcesses(Object.values(config.services).map((s) => s.port));
  await new Promise((resolve) => setTimeout(resolve, PORT_CLEANUP_DELAY));

  for (const [name, service] of Object.entries(config.services)) {
    await prepareLogDirectory(name, service.directory);
  }

  console.log(chalk.blue("🚀 Starting services..."));

  const serviceCommands = Object.entries(config.services).map(
    ([name, service]) => ({
      name: name.toUpperCase(),
      command: buildServiceCommand(service),
    })
  );

  try {
    const { result } = concurrently(serviceCommands, {
      prefix: "name",
      killOthersOn: ["failure"],
      padPrefix: true,
      prefixColors: Object.values(config.services).map(
        (service) => service.color ?? "bgBlue.bold"
      ),
    });

    await result;
  } catch (error) {
    console.error(chalk.red("Failed to start services:"), error);
    throw new Error("Failed to start services");
  }
}

async function runWithLogging(
  name: string,
  directory: string,
  command: string
): Promise<void> {
  try {
    await prepareLogDirectory(name, directory);

    const fullCommand = generateRunNodeCommand({ stringCommand: command });

    await executeShellCommand(fullCommand, { cwd: directory });
  } catch (error) {
    console.error(chalk.red(`Error running ${name}:`), error);
    throw new Error(`Failed to run ${name}`);
  }
}
