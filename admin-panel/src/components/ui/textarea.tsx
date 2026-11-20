import * as React from "react";

import { cn } from "./utils";

function Textarea({ className, ...props }: React.ComponentProps<"textarea">) {
  return (
    <textarea
      data-slot="textarea"
      className={cn(
        "placeholder:text-muted-foreground selection:bg-primary selection:text-primary-foreground dark:bg-input/30 border-input flex min-h-[140px] w-full rounded-xl border px-4 py-3 text-base bg-input-background shadow-sm transition-[color,box-shadow,transform] outline-none disabled:pointer-events-none disabled:cursor-not-allowed disabled:opacity-50 md:text-sm hover:border-border/80 focus:translate-y-[-1px] resize-y leading-relaxed",
        "focus-visible:border-ring focus-visible:ring-ring/30 focus-visible:ring-[4px]",
        "aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 aria-invalid:border-destructive",
        className,
      )}
      {...props}
    />
  );
}

export { Textarea };
