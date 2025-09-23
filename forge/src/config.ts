import { ChalkColor } from "./chalk-utils.js";

export interface Service {
  directory: string;
  installCommand?: string;
  startCommand: string;
  port?: number;
  color?: ChalkColor;
}

export interface ValidationCommand {
  name: string;
  command: string;
  color?: ChalkColor;
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
