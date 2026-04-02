import * as React from "react";

import { supabase } from "../lib/supabase";
import { ErrorBanner } from "../components/ErrorBanner";
import { t } from "../i18n/t";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "../components/ui/table";

type AnnouncementRow = {
  id: string;
  title?: string | null;
  message?: string | null;
  category?: string | null;
  priority?: string | null;
  created_at?: string | null;
  expires_on?: string | null;
  active?: boolean | null;
  grade_id?: string | null;
  academic_year_id?: string | null;
  created_by?: string | null;
};

type GradeRow = {
  id: string;
  name?: string | null;
  code?: string | null;
};

type AcademicYearRow = {
  id: string;
  name?: string | null;
  status?: string | null;
  created_at?: string | null;
};

type PushNotifyResponse = {
  ok?: boolean;
  sent?: number;
  success?: number;
  reason?: string;
  error?: string;
  recipients?: number;
  tokens?: number;
  errors?: unknown[];
};

export function AnnouncementsPage() {
  const [announcements, setAnnouncements] = React.useState<AnnouncementRow[]>([]);
  const [grades, setGrades] = React.useState<GradeRow[]>([]);
  const [years, setYears] = React.useState<AcademicYearRow[]>([]);

  function categoryEmoji(category: string) {
    switch (category) {
      case "urgent":
        return "🚨";
      case "grades":
        return "📊";
      case "schedule":
        return "📅";
      case "event":
        return "🎉";
      case "general":
      default:
        return "📢";
    }
  }

  function categoryLabel(category: string) {
    switch (category) {
      case "urgent":
        return t("announcementsCategoryUrgent");
      case "grades":
        return t("announcementsCategoryGrades");
      case "schedule":
        return t("announcementsCategorySchedule");
      case "event":
        return t("announcementsCategoryEvent");
      case "general":
      default:
        return t("announcementsCategoryGeneral");
    }
  }

  const gradeNameById = React.useMemo(() => {
    return new Map(
      grades.map((g) => [g.id, g.name ?? g.code ?? g.id] as const),
    );
  }, [grades]);

  const [createTitle, setCreateTitle] = React.useState("");
  const [createMessage, setCreateMessage] = React.useState("");
  const [createCategory, setCreateCategory] = React.useState("general");
  const [createPriority, setCreatePriority] = React.useState("medium");
  const [createExpiresOn, setCreateExpiresOn] = React.useState("");
  const [createGradeId, setCreateGradeId] = React.useState<string | null>(null);
  const [createAcademicYearId, setCreateAcademicYearId] = React.useState<string | null>(null);
  const [createActive, setCreateActive] = React.useState(true);

  const [isLoading, setIsLoading] = React.useState(true);
  const [isCreating, setIsCreating] = React.useState(false);
  const [deletingId, setDeletingId] = React.useState<string | null>(null);
  const [error, setError] = React.useState<string | null>(null);
  const [notice, setNotice] = React.useState<string | null>(null);

  const activeYear = React.useMemo(
    () => years.find((y) => y.status === "active") ?? null,
    [years],
  );

  const load = React.useCallback(async () => {
    setError(null);
    setIsLoading(true);

    const [{ data: yearsData, error: yearsError }, { data: gradesData, error: gradesError }, { data: announcementsData, error: announcementsError }] =
      await Promise.all([
        supabase.from("academic_years").select("*").order("created_at", { ascending: false }),
        supabase.from("grades").select("*").order("name"),
        supabase
          .from("announcements")
          .select(
            "id, title, message, category, priority, created_by, created_at, expires_on, active, grade_id, academic_year_id",
          )
          .order("created_at", { ascending: false }),
      ]);

    if (yearsError) {
      setError(yearsError.message);
      setYears([]);
    } else {
      setYears((yearsData ?? []) as AcademicYearRow[]);
    }

    if (gradesError) {
      setError(gradesError.message);
      setGrades([]);
    } else {
      setGrades((gradesData ?? []) as GradeRow[]);
    }

    if (announcementsError) {
      setError(announcementsError.message);
      setAnnouncements([]);
    } else {
      setAnnouncements((announcementsData ?? []) as AnnouncementRow[]);
    }

    setIsLoading(false);
  }, []);

  React.useEffect(() => {
    void load();
  }, [load]);

  React.useEffect(() => {
    if (!createAcademicYearId && activeYear?.id) {
      setCreateAcademicYearId(activeYear.id);
    }
  }, [activeYear?.id, createAcademicYearId]);

  async function createAnnouncement() {
    setError(null);
    setNotice(null);

    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser();
    if (userError) {
      setError(userError.message);
      return;
    }
    if (!user) {
      setError(t("announcementsMustSignIn"));
      return;
    }

    const title = createTitle.trim();
    const message = createMessage.trim();
    if (!title || !message) {
      setError(t("announcementsValidationTitleMessageRequired"));
      return;
    }

    const expires = createExpiresOn.trim();
    const validExpires = expires
      ? Number.isNaN(Date.parse(expires))
        ? null
        : expires
      : null;

    setIsCreating(true);
    try {
      const { data: insertedAnnouncement, error: insertError } = await supabase
        .from("announcements")
        .insert({
          academic_year_id: createAcademicYearId,
          grade_id: createGradeId,
          title,
          message,
          category: createCategory.trim() || "general",
          priority: createPriority.trim() || "medium",
          expires_on: validExpires,
          active: createActive,
          created_by: user.id,
        })
        .select("id")
        .single();

      if (insertError) {
        setError(insertError.message);
        return;
      }

      let pushData: unknown = null;
      if (insertedAnnouncement?.id) {
        const { data, error: pushError } = await supabase.functions.invoke("push-notify", {
          body: { event: "announcement_created", announcementId: insertedAnnouncement.id },
        });

        if (pushError) {
          setNotice(
            t("announcementsNoticePushFailed", { details: pushError.message }),
          );
        } else {
          pushData = data;
        }
      }

      // The edge function can return 200 even when nothing is sent (e.g., no tokens).
      if (pushData && typeof pushData === "object") {
        const response = pushData as PushNotifyResponse;
        if (response.ok === false) {
          setNotice(
            t("announcementsNoticePushFailed", { details: response.error ?? t("commonUnknownError") }),
          );
        }
        const sentCount =
          typeof response.sent === "number"
            ? response.sent
            : typeof response.success === "number"
              ? response.success
              : null;
        if (sentCount === 0) {
          const reason = typeof response.reason === "string" ? response.reason : t("commonUnknown");
          const firstError = Array.isArray(response.errors) ? response.errors[0] : null;
          const firstErrorText = firstError ? JSON.stringify(firstError) : null;
          setNotice(
            t("announcementsNoticeNoPushSent", {
              reason,
              recipients: String(response.recipients ?? "?"),
              tokens: String(response.tokens ?? "?"),
              firstError: firstErrorText ? `, firstError: ${firstErrorText}` : "",
            }),
          );
        }
      }

      setCreateTitle("");
      setCreateMessage("");
      setCreateCategory("general");
      setCreatePriority("medium");
      setCreateExpiresOn("");
      setCreateGradeId(null);
      setCreateActive(true);

      await load();
    } finally {
      setIsCreating(false);
    }
  }

  async function deleteAnnouncement(id: string) {
    const announcement = announcements.find((item) => item.id === id);
    if (!window.confirm(t("announcementsConfirmDelete", { title: announcement?.title ?? id }))) {
      return;
    }

    setError(null);
    setDeletingId(id);
    try {
      const { error: deleteError } = await supabase
        .from("announcements")
        .delete()
        .eq("id", id);

      if (deleteError) {
        setError(deleteError.message);
        return;
      }

      await load();
    } finally {
      setDeletingId(null);
    }
  }

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight text-foreground">{t("announcementsTitle")}</h1>
        <p className="text-muted-foreground mt-2">
          {t("announcementsSubtitle")}
        </p>
      </div>

      {error ? <ErrorBanner title={t("commonRequestFailed")} message={error} /> : null}
      {notice ? (
        <div
          className="rounded-lg border border-border bg-muted/40 px-4 py-3 text-sm"
          role="status"
        >
          <div className="font-semibold text-foreground">{t("announcementsNoticeTitle")}</div>
          <div className="text-muted-foreground">{notice}</div>
        </div>
      ) : null}

      <Card>
        <CardHeader className="border-b">
          <CardTitle>{t("announcementsCreateTitle")}</CardTitle>
        </CardHeader>
        <CardContent className="grid gap-4 md:grid-cols-2">
          <div className="grid gap-2">
            <Label htmlFor="title">{t("announcementsTitleLabel")}</Label>
            <Input id="title" value={createTitle} onChange={(e) => setCreateTitle(e.target.value)} />
          </div>

          <div className="grid gap-2">
            <Label htmlFor="grade">{t("announcementsGradeOptionalLabel")}</Label>
            <select
              id="grade"
              className="h-10 w-full rounded-md border bg-input-background px-3 text-sm outline-none focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]"
              value={createGradeId ?? ""}
              onChange={(e) => setCreateGradeId(e.target.value ? e.target.value : null)}
              disabled={isLoading}
            >
              <option value="">{t("announcementsGlobalAllGrades")}</option>
              {grades.map((g) => (
                <option key={g.id} value={g.id}>
                  {g.name ?? g.code ?? g.id}
                </option>
              ))}
            </select>
          </div>

          <div className="grid gap-2 md:col-span-2">
            <Label htmlFor="message">{t("announcementsMessageLabel")}</Label>
            <Input id="message" value={createMessage} onChange={(e) => setCreateMessage(e.target.value)} />
          </div>

          <div className="grid gap-2">
            <Label htmlFor="category">{t("announcementsCategoryLabel")}</Label>
            <select
              id="category"
              className="h-10 w-full rounded-md border bg-input-background px-3 text-sm outline-none focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]"
              value={createCategory}
              onChange={(e) => setCreateCategory(e.target.value)}
              disabled={isLoading || isCreating}
            >
              {(["general", "grades", "schedule", "event", "urgent"] as const).map((category) => (
                <option key={category} value={category}>
                  {categoryEmoji(category)} {categoryLabel(category)}
                </option>
              ))}
            </select>
          </div>

          <div className="grid gap-2">
            <Label htmlFor="priority">{t("announcementsPriorityLabel")}</Label>
            <Input id="priority" value={createPriority} onChange={(e) => setCreatePriority(e.target.value)} />
          </div>

          <div className="grid gap-2">
            <Label htmlFor="expires">{t("announcementsExpiresOptionalLabel")}</Label>
            <Input
              id="expires"
              placeholder="YYYY-MM-DD"
              value={createExpiresOn}
              onChange={(e) => setCreateExpiresOn(e.target.value)}
            />
          </div>

          <div className="grid gap-2">
            <Label htmlFor="academic-year">{t("announcementsAcademicYearLabel")}</Label>
            <select
              id="academic-year"
              className="h-10 w-full rounded-md border bg-input-background px-3 text-sm outline-none focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]"
              value={createAcademicYearId ?? ""}
              onChange={(e) => setCreateAcademicYearId(e.target.value || null)}
              disabled={isLoading}
            >
              <option value="">—</option>
              {years.map((y) => (
                <option key={y.id} value={y.id}>
                  {y.name ?? y.id}{y.status === "active" ? t("announcementsActiveSuffix") : ""}
                </option>
              ))}
            </select>
          </div>

          <div className="md:col-span-2 flex items-center justify-between gap-3">
            <label className="flex items-center gap-2 text-sm">
              <input type="checkbox" checked={createActive} onChange={(e) => setCreateActive(e.target.checked)} />
              {t("announcementsActiveLabel")}
            </label>

            <Button disabled={isLoading || isCreating} onClick={() => void createAnnouncement()}>
              {isCreating ? t("commonCreating") : t("commonCreate")}
            </Button>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="border-b">
          <CardTitle>{t("announcementsAllTitle")}</CardTitle>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="text-sm text-muted-foreground">{t("commonLoading")}</div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>{t("announcementsTableTitle")}</TableHead>
                  <TableHead>{t("announcementsTableGrade")}</TableHead>
                  <TableHead>{t("announcementsTablePriority")}</TableHead>
                  <TableHead>{t("announcementsTableActive")}</TableHead>
                  <TableHead>{t("announcementsTableCreated")}</TableHead>
                  <TableHead />
                </TableRow>
              </TableHeader>
              <TableBody>
                {announcements.map((a) => (
                  <TableRow key={a.id}>
                    <TableCell className="font-medium">
                      <div>{a.title ?? a.id}</div>
                      <div className="text-xs text-muted-foreground">
                        {a.message ?? ""}
                      </div>
                    </TableCell>
                    <TableCell className="text-muted-foreground">
                      {a.grade_id ? gradeNameById.get(a.grade_id) ?? a.grade_id : t("announcementsGlobalLabel")}
                    </TableCell>
                    <TableCell className="text-muted-foreground">
                      {a.priority ?? "—"}
                    </TableCell>
                    <TableCell className="text-muted-foreground">
                      {a.active ? t("commonYes") : t("commonNo")}
                    </TableCell>
                    <TableCell className="text-muted-foreground">
                      {a.created_at ? new Date(a.created_at).toLocaleString() : "—"}
                    </TableCell>
                    <TableCell className="text-right">
                      <Button
                        size="sm"
                        variant="destructive"
                        disabled={deletingId === a.id}
                        onClick={() => void deleteAnnouncement(a.id)}
                      >
                        {deletingId === a.id ? t("commonDeleting") : t("commonDelete")}
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
