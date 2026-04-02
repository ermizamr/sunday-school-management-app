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

type ProfileRow = {
  id: string;
  name?: string | null;
  role?: string | null;
  grade_id?: string | null;
  academic_id?: string | null;
  account_status?: string | null;
};

type GradeRow = {
  id: string;
  name?: string | null;
  code?: string | null;
};

type Draft = {
  grade_id: string | null;
};

export function UsersPage() {
  const [profiles, setProfiles] = React.useState<ProfileRow[]>([]);
  const [grades, setGrades] = React.useState<GradeRow[]>([]);
  const [isLoading, setIsLoading] = React.useState(true);
  const [error, setError] = React.useState<string | null>(null);

  const [drafts, setDrafts] = React.useState<Record<string, Draft>>({});
  const [savingId, setSavingId] = React.useState<string | null>(null);
  const [actionId, setActionId] = React.useState<string | null>(null);

  const [createEmail, setCreateEmail] = React.useState("");
  const [createPassword, setCreatePassword] = React.useState("");
  const [createAcademicId, setCreateAcademicId] = React.useState("");
  const [createName, setCreateName] = React.useState("");
  const [createGradeId, setCreateGradeId] = React.useState<string | null>(null);
  const [isCreating, setIsCreating] = React.useState(false);
  const [searchQuery, setSearchQuery] = React.useState("");
  const [statusFilter, setStatusFilter] = React.useState<"all" | "active" | "inactive_pending_admin">("all");

  const gradeNameById = React.useMemo(() => {
    return new Map(
      grades.map((g) => [g.id, g.name ?? g.code ?? g.id] as const),
    );
  }, [grades]);

  const filteredProfiles = React.useMemo(() => {
    const query = searchQuery.trim().toLowerCase();
    return profiles.filter((p) => {
      const status = (p.account_status ?? "active").toLowerCase();
      if (status === "graduated") return false;
      const statusMatches = statusFilter === "all" ? true : status === statusFilter;
      if (!statusMatches) return false;

      if (!query) return true;
      const nameMatch = (p.name ?? "").toLowerCase().includes(query);
      const idMatch = (p.academic_id ?? "").toLowerCase().includes(query);
      const emailMatch = (p.id ?? "").toLowerCase().includes(query);
      return nameMatch || idMatch || emailMatch;
    });
  }, [profiles, searchQuery, statusFilter]);

  const load = React.useCallback(async () => {
    setError(null);
    setIsLoading(true);

    const [{ data: gradesData, error: gradesError }, { data: profilesData, error: profilesError }] =
      await Promise.all([
        supabase.from("grades").select("*").order("name"),
        supabase.from("profiles").select("*").eq("role", "student").order("name"),
      ]);

    if (gradesError) {
      setError(gradesError.message);
      setGrades([]);
    } else {
      setGrades((gradesData ?? []) as GradeRow[]);
    }

    if (profilesError) {
      setError(profilesError.message);
      setProfiles([]);
    } else {
      setProfiles((profilesData ?? []) as ProfileRow[]);
    }

    setDrafts({});
    setIsLoading(false);
  }, []);

  React.useEffect(() => {
    void load();
  }, [load]);

  function statusLabel(status: string): string {
    switch (status) {
      case "active":
        return t("usersStatusActive");
      case "inactive_pending_admin":
        return t("usersStatusInactive");
      default:
        return status;
    }
  }

  function draftFor(p: ProfileRow): Draft {
    return (
      drafts[p.id] ?? {
        grade_id: p.grade_id ?? null,
      }
    );
  }

  async function saveProfile(id: string) {
    const draft = drafts[id];
    if (!draft) return;

    setError(null);
    setSavingId(id);
    try {
      const { error: updateError } = await supabase
        .from("profiles")
        .update({
          grade_id: draft.grade_id,
        })
        .eq("id", id);

      if (updateError) {
        setError(updateError.message);
        return;
      }

      await load();
    } finally {
      setSavingId(null);
    }
  }

  async function createUser() {
    setError(null);

    const academicId = createAcademicId.trim();
    const name = createName.trim();
    const password = createPassword.trim();
    const email = createEmail.trim();

    if (!academicId || !name || !password) {
      setError(t("usersValidationRequired"));
      return;
    }

    setIsCreating(true);
    try {
      const { data, error: invokeError } = await supabase.functions.invoke(
        "admin-create-user",
        {
          body: {
            email: email || undefined,
            password,
            role: "student",
            academic_id: academicId,
            name,
            grade_id: createGradeId,
          },
        },
      );

      if (invokeError) {
        setError(invokeError.message);
        return;
      }

      if ((data as { error?: string } | null)?.error) {
        setError((data as { error: string }).error);
        return;
      }

      setCreateEmail("");
      setCreatePassword("");
      setCreateAcademicId("");
      setCreateName("");
      setCreateGradeId(null);

      await load();
    } finally {
      setIsCreating(false);
    }
  }

  async function resetPasswordFor(userId: string, displayName: string) {
    const newPassword = window.prompt(t("usersPromptNewPassword", { name: displayName }));
    if (!newPassword) return;

    setError(null);
    setActionId(userId);
    try {
      const { data, error: invokeError } = await supabase.functions.invoke(
        "admin-reset-password",
        { body: { user_id: userId, new_password: newPassword } },
      );

      if (invokeError) {
        setError(invokeError.message);
        return;
      }

      if ((data as { error?: string } | null)?.error) {
        setError((data as { error: string }).error);
        return;
      }
    } finally {
      setActionId(null);
    }
  }

  async function toggleAccountStatus(p: ProfileRow) {
    const current = (p.account_status ?? "active").toLowerCase();
    if (current === "graduated") {
      setError(t("usersGraduatedReadOnlyError"));
      return;
    }

    const next = current === "inactive_pending_admin" ? "active" : "inactive_pending_admin";
    const actionLabel = next === "active" ? t("usersActivate") : t("usersDeactivate");
    if (!window.confirm(t("usersConfirmToggleStatus", { action: actionLabel, name: p.name ?? p.id }))) {
      return;
    }

    setError(null);
    setActionId(p.id);
    try {
      const { data, error: invokeError } = await supabase.functions.invoke(
        "admin-set-account-status",
        { body: { user_id: p.id, account_status: next } },
      );

      if (invokeError) {
        setError(invokeError.message);
        return;
      }

      if ((data as { error?: string } | null)?.error) {
        setError((data as { error: string }).error);
        return;
      }

      await load();
    } finally {
      setActionId(null);
    }
  }

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight text-foreground">{t("usersTitleStudents")}</h1>
        <p className="text-muted-foreground mt-2">
          {t("usersSubtitle")}
        </p>
      </div>

      {error ? (
        <ErrorBanner title={t("commonRequestFailed")} message={error} />
      ) : null}

      <Card>
        <CardHeader className="border-b">
          <CardTitle>{t("usersCreateUserTitle")}</CardTitle>
        </CardHeader>
        <CardContent className="grid gap-4 md:grid-cols-3">
          <div className="grid gap-2">
            <Label htmlFor="create-academic">{t("usersAcademicIdLabel")}</Label>
            <Input
              id="create-academic"
              value={createAcademicId}
              onChange={(e) => setCreateAcademicId(e.target.value)}
              placeholder={t("usersAcademicIdPlaceholder")}
            />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="create-name">{t("usersNameLabel")}</Label>
            <Input
              id="create-name"
              value={createName}
              onChange={(e) => setCreateName(e.target.value)}
              placeholder={t("usersNamePlaceholder")}
            />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="create-password">{t("usersPasswordLabel")}</Label>
            <Input
              id="create-password"
              type="password"
              value={createPassword}
              onChange={(e) => setCreatePassword(e.target.value)}
            />
          </div>

          <div className="grid gap-2">
            <Label htmlFor="create-email">{t("usersEmailOptionalLabel")}</Label>
            <Input
              id="create-email"
              type="email"
              value={createEmail}
              onChange={(e) => setCreateEmail(e.target.value)}
              placeholder={t("usersEmailPlaceholder")}
            />
          </div>

          <div className="grid gap-2">
            <Label htmlFor="create-grade">{t("usersGradeLabel")}</Label>
            <select
              id="create-grade"
              className="h-10 w-full rounded-md border bg-input-background px-3 text-sm outline-none focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]"
              value={createGradeId ?? ""}
              onChange={(e) => setCreateGradeId(e.target.value ? e.target.value : null)}
            >
              <option value="">—</option>
              {grades.map((g) => (
                <option key={g.id} value={g.id}>
                  {g.name ?? g.code ?? g.id}
                </option>
              ))}
            </select>
          </div>

          <div className="md:col-span-3">
            <Button disabled={isCreating} onClick={() => void createUser()}>
              {isCreating ? t("commonCreating") : t("usersCreateUserButton")}
            </Button>
            <div className="mt-2 text-xs text-muted-foreground">
              {t("usersUsesEdgeFunctionPrefix")} <span className="font-mono">admin-create-user</span>.
            </div>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="border-b flex flex-col gap-4 items-start sm:flex-row sm:items-center sm:justify-between py-5">
          <CardTitle>{t("usersAllUsersTitle")}</CardTitle>
          <div className="w-full sm:w-auto flex flex-col gap-2 sm:flex-row sm:items-center">
            <div className="w-full sm:w-52">
              <select
                className="h-10 w-full rounded-md border bg-input-background px-3 text-sm outline-none focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]"
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value as "all" | "active" | "inactive_pending_admin")}
              >
                <option value="all">{t("usersAllStatuses")}</option>
                <option value="active">{t("usersStatusActive")}</option>
                <option value="inactive_pending_admin">{t("usersStatusInactive")}</option>
              </select>
            </div>
            <div className="w-full sm:w-72">
              <Input
                placeholder={t("usersSearchPlaceholder")}
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="bg-background"
              />
            </div>
          </div>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="text-sm text-muted-foreground">{t("commonLoading")}</div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>{t("usersTableName")}</TableHead>
                  <TableHead>{t("usersTableAcademicId")}</TableHead>
                  <TableHead>{t("usersTableGrade")}</TableHead>
                  <TableHead>{t("usersTableStatus")}</TableHead>
                  <TableHead />
                </TableRow>
              </TableHeader>
              <TableBody>
                  {filteredProfiles.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={5} className="h-24 text-center text-muted-foreground">
                        {t("usersNoMatches")}
                      </TableCell>
                    </TableRow>
                  ) : null}
                  {filteredProfiles.map((p) => {
                  const d = draftFor(p);
                  const displayName = p.name ?? p.id;
                  const status = (p.account_status ?? "active").toLowerCase();
                  return (
                    <TableRow key={p.id}>
                      <TableCell className="font-medium">
                        {displayName}
                      </TableCell>
                      <TableCell className="text-muted-foreground">
                        {p.academic_id ?? "—"}
                      </TableCell>
                      <TableCell>
                        <select
                          className="h-9 w-full rounded-md border bg-input-background px-3 text-sm outline-none focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]"
                          value={d.grade_id ?? ""}
                          onChange={(e) =>
                            setDrafts((prev) => ({
                              ...prev,
                              [p.id]: {
                                ...d,
                                grade_id: e.target.value ? e.target.value : null,
                              },
                            }))
                          }
                        >
                          <option value="">—</option>
                          {grades.map((g) => (
                            <option key={g.id} value={g.id}>
                              {g.name ?? g.code ?? g.id}
                            </option>
                          ))}
                        </select>
                        <div className="mt-1 text-xs text-muted-foreground">
                          {d.grade_id ? gradeNameById.get(d.grade_id) : t("usersNoGrade")}
                        </div>
                      </TableCell>
                      <TableCell className="text-muted-foreground">
                        <span
                          className={
                            status === "active"
                              ? "inline-flex rounded-full bg-emerald-500/15 px-2 py-1 text-xs font-medium text-emerald-700"
                              : status === "graduated"
                                ? "inline-flex rounded-full bg-primary/15 px-2 py-1 text-xs font-medium text-primary"
                                : "inline-flex rounded-full bg-amber-500/15 px-2 py-1 text-xs font-medium text-amber-700"
                          }
                        >
                          {statusLabel(status)}
                        </span>
                      </TableCell>
                      <TableCell className="text-right">
                        <div className="flex justify-end gap-2">
                          <Button
                            size="sm"
                            disabled={!drafts[p.id] || savingId === p.id}
                            onClick={() => void saveProfile(p.id)}
                          >
                            {savingId === p.id ? t("commonSaving") : t("commonSave")}
                          </Button>

                          <Button
                            size="sm"
                            variant="outline"
                            disabled={actionId === p.id}
                            onClick={() => void resetPasswordFor(p.id, displayName)}
                          >
                            {t("usersResetPassword")}
                          </Button>

                          <Button
                            size="sm"
                            variant={status === "inactive_pending_admin" ? "default" : "destructive"}
                            disabled={actionId === p.id || status === "graduated"}
                            onClick={() => void toggleAccountStatus(p)}
                          >
                            {actionId === p.id
                              ? t("commonWorking")
                              : status === "inactive_pending_admin"
                                ? t("usersActivate")
                                : t("usersDeactivate")}
                          </Button>
                        </div>
                      </TableCell>
                    </TableRow>
                  );
                })}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
