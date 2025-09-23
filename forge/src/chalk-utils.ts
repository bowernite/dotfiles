import chalk, { 
  ForegroundColorName, 
  BackgroundColorName, 
  ModifierName,
  foregroundColorNames,
  backgroundColorNames,
  modifierNames
} from "chalk";

// Create a type that includes base colors and chained combinations
// This automatically stays in sync with Chalk's supported colors
export type ChalkColor = 
  | ForegroundColorName 
  | BackgroundColorName 
  | `${BackgroundColorName}.${ModifierName}`;

// Helper function to get all valid color keys at runtime
export function getValidColorKeys(): string[] {
  const keys: string[] = [];
  
  // Add all foreground and background colors
  keys.push(...foregroundColorNames, ...backgroundColorNames);
  
  // Add chained combinations (background colors with modifiers)
  for (const bgColor of backgroundColorNames) {
    for (const modifier of modifierNames) {
      keys.push(`${bgColor}.${modifier}`);
    }
  }
  
  return keys;
}

// Color utility functions
export function createColorMap(): Record<string, (text: string) => string> {
  const colorMap: Record<string, (text: string) => string> = {};
  
  // Add all foreground colors
  for (const colorName of foregroundColorNames) {
    colorMap[colorName] = chalk[colorName as keyof typeof chalk] as (text: string) => string;
  }
  
  // Add all background colors
  for (const colorName of backgroundColorNames) {
    colorMap[colorName] = chalk[colorName as keyof typeof chalk] as (text: string) => string;
  }
  
  // Add chained combinations (background colors with modifiers)
  for (const bgColor of backgroundColorNames) {
    for (const modifier of modifierNames) {
      const key = `${bgColor}.${modifier}`;
      const bgColorFn = chalk[bgColor as keyof typeof chalk] as any;
      const modifierFn = bgColorFn[modifier];
      if (typeof modifierFn === 'function') {
        colorMap[key] = modifierFn;
      }
    }
  }
  
  return colorMap;
}

export function getChalkColor(colorName?: string): ((text: string) => string) | null {
  if (!colorName) return null;

  const colorMap = createColorMap();
  return colorMap[colorName] || null;
}
