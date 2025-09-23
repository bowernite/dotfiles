import chalk from "chalk";

export interface Service {
  directory: string;
  installCommand?: string;
  startCommand: string;
  port?: number;
}

export interface ValidationCommand {
  name: string;
  command: string;
  color?: keyof typeof chalk;
  quickMode?: boolean;
}

export interface FilePatterns {
  frontend: string;
  jsTs: string;
}

export interface Validation {
  commands: ValidationCommand[];
}

export interface Config {
  services: Record<string, Service>;
  validation: Validation;
}
