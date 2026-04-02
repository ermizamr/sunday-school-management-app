import { am } from "./am";

export type I18nKey = keyof typeof am;

export function t(key: I18nKey, vars?: Record<string, string | number>): string {
  let text: string = am[key];

  if (vars) {
    for (const [name, value] of Object.entries(vars)) {
      text = text.replaceAll(`{${name}}`, String(value));
    }
  }

  return text;
}
