import { Link, Navigate, useParams } from "react-router";
import ReactMarkdown, { type Components } from "react-markdown";
import remarkGfm from "remark-gfm";

import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { Button } from "../components/ui/button";
import { t } from "../i18n/t";

import amGuide from "../../docs/ADMIN_DASHBOARD_GUIDE_AM.md?raw";
import enGuide from "../../docs/ADMIN_DASHBOARD_GUIDE.md?raw";

type DocLanguage = "am" | "en";

function normalizeLanguage(value?: string): DocLanguage | null {
  if (!value) return null;

  const v = value.trim().toLowerCase();
  if (v === "am" || v === "amharic" || v === "amh" || v === "አማርኛ") return "am";
  if (v === "en" || v === "english" || v === "eng") return "en";

  return null;
}

function ignoreMarkdownNode(_node: unknown): void {
  void _node;
}

const markdownComponents: Components = {
  h1({ node: _node, ...props }) {
    ignoreMarkdownNode(_node);
    return (
      <h1
        className="mt-8 first:mt-0 text-3xl font-extrabold tracking-tight text-foreground"
        {...props}
      />
    );
  },
  h2({ node: _node, ...props }) {
    ignoreMarkdownNode(_node);
    return (
      <h2
        className="mt-8 first:mt-0 text-2xl font-bold tracking-tight text-foreground"
        {...props}
      />
    );
  },
  h3({ node: _node, ...props }) {
    ignoreMarkdownNode(_node);
    return (
      <h3
        className="mt-6 first:mt-0 text-xl font-semibold tracking-tight text-foreground"
        {...props}
      />
    );
  },
  p({ node: _node, ...props }) {
    ignoreMarkdownNode(_node);
    return <p className="text-muted-foreground leading-relaxed" {...props} />;
  },
  a({ node: _node, ...props }) {
    ignoreMarkdownNode(_node);
    return (
      <a
        className="text-primary underline underline-offset-4 hover:opacity-90"
        target="_blank"
        rel="noreferrer"
        {...props}
      />
    );
  },
  ul({ node: _node, ...props }) {
    ignoreMarkdownNode(_node);
    return (
      <ul
        className="list-disc pl-6 space-y-1 text-muted-foreground"
        {...props}
      />
    );
  },
  ol({ node: _node, ...props }) {
    ignoreMarkdownNode(_node);
    return (
      <ol
        className="list-decimal pl-6 space-y-1 text-muted-foreground"
        {...props}
      />
    );
  },
  li({ node: _node, ...props }) {
    ignoreMarkdownNode(_node);
    return <li className="text-muted-foreground" {...props} />;
  },
  hr({ node: _node, ...props }) {
    ignoreMarkdownNode(_node);
    return <hr className="my-6 border-border/60" {...props} />;
  },
  blockquote({ node: _node, ...props }) {
    ignoreMarkdownNode(_node);
    return (
      <blockquote
        className="border-l-4 border-border/60 pl-4 italic text-muted-foreground"
        {...props}
      />
    );
  },
  code({ node: _node, className, children, ...props }) {
    ignoreMarkdownNode(_node);
    const text = Array.isArray(children) ? children.join("") : String(children ?? "");
    const looksInline = !className && !text.includes("\n");

    if (looksInline) {
      return (
        <code
          className="rounded bg-muted px-1 py-0.5 font-mono text-[0.925em] text-foreground"
          {...props}
        >
          {children}
        </code>
      );
    }

    return (
      <code
        className={["block font-mono text-sm text-foreground", className]
          .filter(Boolean)
          .join(" ")}
        {...props}
      >
        {children}
      </code>
    );
  },
  pre({ node: _node, ...props }) {
    ignoreMarkdownNode(_node);
    return (
      <pre
        className="my-4 overflow-x-auto rounded-xl border border-border/60 bg-muted p-4"
        {...props}
      />
    );
  },
  table({ node: _node, ...props }) {
    ignoreMarkdownNode(_node);
    return (
      <div className="my-4 overflow-x-auto">
        <table
          className="w-full border-collapse text-sm border border-border/60 rounded-xl"
          {...props}
        />
      </div>
    );
  },
  th({ node: _node, ...props }) {
    ignoreMarkdownNode(_node);
    return (
      <th
        className="border border-border/60 bg-secondary px-3 py-2 text-left font-semibold text-foreground"
        {...props}
      />
    );
  },
  td({ node: _node, ...props }) {
    ignoreMarkdownNode(_node);
    return (
      <td
        className="border border-border/60 px-3 py-2 align-top text-muted-foreground"
        {...props}
      />
    );
  },
};

export function DocumentsPage() {
  const { language } = useParams();
  const lang = normalizeLanguage(language);

  if (language && !lang) {
    return <Navigate to="/admin/documents" replace />;
  }

  if (!lang) {
    return (
      <div className="space-y-8 max-w-4xl mx-auto pb-10">
        <div>
          <h1 className="text-4xl font-extrabold tracking-tight text-foreground">{t("documentsTitle")}</h1>
          <p className="text-muted-foreground mt-2 text-lg">{t("documentsSubtitle")}</p>
        </div>

        <Card className="shadow-sm">
          <CardHeader>
            <CardTitle className="text-xl">{t("documentsChooseLanguage")}</CardTitle>
          </CardHeader>
          <CardContent className="flex flex-col gap-3 sm:flex-row">
            <Button asChild className="w-full sm:w-auto">
              <Link to="/admin/documents/amharic">{t("documentsLanguageAmharic")}</Link>
            </Button>
            <Button asChild variant="outline" className="w-full sm:w-auto">
              <Link to="/admin/documents/english">{t("documentsLanguageEnglish")}</Link>
            </Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  const docTitle = lang === "am" ? t("documentsLanguageAmharic") : t("documentsLanguageEnglish");
  const markdown = lang === "am" ? amGuide : enGuide;

  return (
    <div className="space-y-6 max-w-4xl mx-auto pb-10">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <h1 className="text-3xl font-extrabold tracking-tight text-foreground">
            {t("documentsTitle")} — {docTitle}
          </h1>
          <p className="text-muted-foreground mt-2">{t("documentsViewerHint")}</p>
        </div>

        <Button asChild variant="outline" className="shrink-0">
          <Link to="/admin/documents">{t("documentsBack")}</Link>
        </Button>
      </div>

      <Card className="shadow-sm">
        <CardContent className="p-6">
          <article className="space-y-4">
            <ReactMarkdown
              remarkPlugins={[remarkGfm]}
              components={markdownComponents}
            >
              {markdown}
            </ReactMarkdown>
          </article>
        </CardContent>
      </Card>
    </div>
  );
}
