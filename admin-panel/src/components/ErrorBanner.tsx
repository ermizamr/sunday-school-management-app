import { cn } from "../components/ui/utils";
import { t } from "../i18n/t";

function humanizeErrorMessage(message: string): string {
  const trimmed = message.trim();
  if (!trimmed) return t("commonUnknownError");

  const lower = trimmed.toLowerCase();

  if (lower.includes("failed to fetch") || lower.includes("fetch failed") || lower.includes("networkerror")) {
    return t("commonNetworkError");
  }

  if (trimmed === "Invalid login credentials") {
    return t("authInvalidLoginCredentials");
  }

  if (lower.includes("email not confirmed")) {
    return t("authEmailNotConfirmed");
  }

  return trimmed;
}

export function ErrorBanner({
  title = t("commonError"),
  message,
  className,
}: {
  title?: string;
  message: string;
  className?: string;
}) {
  const displayMessage = humanizeErrorMessage(message);

  return (
    <div
      className={cn(
        "rounded-lg border border-destructive/30 bg-destructive/10 px-4 py-3 text-sm",
        className,
      )}
      role="alert"
    >
      <div className="font-semibold">{title}</div>
      <div className="text-muted-foreground">{displayMessage}</div>
    </div>
  );
}
