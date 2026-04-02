import { cn } from "../components/ui/utils";
import { t } from "../i18n/t";

export function ErrorBanner({
  title = t("commonError"),
  message,
  className,
}: {
  title?: string;
  message: string;
  className?: string;
}) {
  return (
    <div
      className={cn(
        "rounded-lg border border-destructive/30 bg-destructive/10 px-4 py-3 text-sm",
        className,
      )}
      role="alert"
    >
      <div className="font-semibold">{title}</div>
      <div className="text-muted-foreground">{message}</div>
    </div>
  );
}
