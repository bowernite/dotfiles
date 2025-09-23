import { execa } from "execa";
import chalk from "chalk";
import concurrently from "concurrently";
import { Config, Service } from "./config.js";
import { killPortProcesses } from "./port-utils.js";
import { generateRunNodeCommand } from "./node-utils.js";
import { executeShellCommand } from "./shell-utils.js";
import { wait } from "./utils.js";

// Constants
const LOGS_DIR = "logs";
const PORT_CLEANUP_DELAY = 1000;

export interface StartupOptions {
  service?: string;
  config: Config;
}

export async function startServices(options: StartupOptions): Promise<void> {
  const { service, config } = options;

  const servicesToStart = service
    ? { [service]: config.services[service] }
    : config.services;

  const ports = Object.values(servicesToStart)
    .map((svc: Service) => svc.port)
    .filter(Boolean);

  if (ports.length > 0) {
    console.log(chalk.blue("🛑 Stopping any existing processes..."));
    await killPortProcesses(ports);
    await wait(PORT_CLEANUP_DELAY);
  }

  for (const [name, service] of Object.entries(servicesToStart)) {
    await prepareLogDirectory(name, service.directory);
  }

  console.log(chalk.blue("🚀 Starting services..."));

  const serviceCommands = Object.entries(servicesToStart).map(
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
      prefixColors: Object.values(servicesToStart).map(
        (service) => service.color ?? "bgBlue.bold"
      ),
    });

    await result;
  } catch (error) {
    console.error(chalk.red("Failed to start services:"), error);
    throw new Error("Failed to start services");
  }
}

function buildServiceCommand(service: Service): string {
  const installCmd = service.installCommand;

  let command = installCmd
    ? `${installCmd} && ${service.startCommand}`
    : service.startCommand;

  return generateRunNodeCommand({
    directory: service.directory,
    stringCommand: command,
  });
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
