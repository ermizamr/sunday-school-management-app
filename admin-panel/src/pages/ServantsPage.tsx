import * as React from "react";

import { supabase } from "../lib/supabase";
import { invokeEdgeFunction } from "../lib/invokeEdgeFunction";
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

export function ServantsPage() {
  const [profiles, setProfiles] = React.useState<ProfileRow[]>([]);
  const [grades, setGrades] = React.useState<GradeRow[]>([]);
  const [isLoading, setIsLoading] = React.useState(true);
  const [error, setError] = React.useState<string | null>(null);
  const [togglingId, setTogglingId] = React.useState<string | null>(null);
  const [deletingId, setDeletingId] = React.useState<string | null>(null);

  const [createEmail, setCreateEmail] = React.useState("");
  const [createPassword, setCreatePassword] = React.useState("");
  const [createAcademicId, setCreateAcademicId] = React.useState("");
  const [createName, setCreateName] = React.useState("");
  const [createGradeId, setCreateGradeId] = React.useState<string | null>(null);
  const [isCreating, setIsCreating] = React.useState(false);

  const gradeNameById = React.useMemo(() => {
    return new Map(
      grades.map((g) => [g.id, g.name ?? g.code ?? g.id] as const),
    );
  }, [grades]);

  const load = React.useCallback(async () => {
    setError(null);
    setIsLoading(true);

    const [{ data: gradesData, error: gradesError }, { data: profilesData, error: profilesError }] =
      await Promise.all([
        supabase.from("grades").select("*").order("name"),
        supabase
          .from("profiles")
          .select("*")
          .eq("role", "servant")
          .order("name"),
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

    setIsLoading(false);
  }, []);

  React.useEffect(() => {
    void load();
  }, [load]);

  function statusLabel(status: string): string {
    switch (status) {
      case "active":
        return t("servantsStatusActive");
      case "inactive_pending_admin":
      case "inactive":
        return t("servantsStatusInactive");
      default:
        return status;
    }
  }

  async function createServant() {
    setError(null);

    const academicId = createAcademicId.trim();
    const name = createName.trim();
    const password = createPassword.trim();
    const email = createEmail.trim();

    if (!academicId || !name || !createGradeId) {
      setError(t("servantsValidationRequired"));
      return;
    }

    setIsCreating(true);
    try {
      const body: Record<string, unknown> = {
        email: email || undefined,
        password: password || undefined,
        role: "servant",
        academic_id: academicId,
        name,
        grade_id: createGradeId,
      };

      const { data, error: invokeError } = await invokeEdgeFunction(
        "admin-create-user",
        body,
      );

      if (invokeError) {
        setError(invokeError);
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

  async function toggleAccountStatus(p: ProfileRow) {
    setError(null);
    setTogglingId(p.id);

    try {
      const current = (p.account_status ?? "active").toLowerCase();
      const isInactive = current === "inactive_pending_admin" || current === "inactive";
      const next = isInactive ? "active" : "inactive_pending_admin";
      const actionLabel = next === "active" ? t("servantsActivate") : t("servantsDeactivate");
      if (!window.confirm(t("servantsConfirmToggleStatus", { action: actionLabel, name: p.name ?? p.id }))) {
        return;
      }

      const { error: fnError } = await invokeEdgeFunction(
        "admin-set-account-status",
        { user_id: p.id, account_status: next },
      );

      if (fnError) {
        setError(fnError);
        return;
      }

      setProfiles((prev) =>
        prev.map((x) => (x.id === p.id ? { ...x, account_status: next } : x)),
      );
    } finally {
      setTogglingId(null);
    }
  }

  async function deleteServant(p: ProfileRow) {
    const name = p.name ?? p.academic_id ?? p.id;
    if (!window.confirm(t("servantsConfirmDelete", { name }))) {
      return;
    }

    setError(null);
    setDeletingId(p.id);

    try {
      const { data, error: invokeError } = await invokeEdgeFunction(
        "admin-delete-user",
        { user_id: p.id },
      );

      if (invokeError) {
        setError(invokeError);
        return;
      }

      if ((data as { error?: string } | null)?.error) {
        setError((data as { error: string }).error);
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
        <h1 className="text-2xl sm:text-3xl font-bold tracking-tight text-foreground">{t("servantsTitle")}</h1>
        <p className="text-muted-foreground mt-1.5 sm:mt-2 text-sm sm:text-base">
          {t("servantsSubtitle")}
        </p>
      </div>

      {error ? <ErrorBanner title={t("commonRequestFailed")} message={error} /> : null}

      <Card>
        <CardHeader className="border-b">
          <CardTitle>{t("servantsCreateServantTitle")}</CardTitle>
        </CardHeader>
        <CardContent className="grid gap-4 grid-cols-1 sm:grid-cols-2 lg:grid-cols-3">
          <div className="grid gap-2">
            <Label htmlFor="create-servant-academic">{t("servantsAcademicIdLabel")}</Label>
            <Input
              id="create-servant-academic"
              value={createAcademicId}
              onChange={(e) => setCreateAcademicId(e.target.value)}
              placeholder={t("servantsAcademicIdPlaceholder")}
            />
          </div>

          <div className="grid gap-2">
            <Label htmlFor="create-servant-name">{t("usersNameLabel")}</Label>
            <Input
              id="create-servant-name"
              value={createName}
              onChange={(e) => setCreateName(e.target.value)}
              placeholder={t("usersNamePlaceholder")}
            />
          </div>

          <div className="grid gap-2">
            <Label htmlFor="create-servant-password">{t("usersPasswordLabel")}</Label>
            <Input
              id="create-servant-password"
              type="password"
              value={createPassword}
              onChange={(e) => setCreatePassword(e.target.value)}
            />
          </div>

          <div className="grid gap-2">
            <Label htmlFor="create-servant-email">{t("usersEmailOptionalLabel")}</Label>
            <Input
              id="create-servant-email"
              type="email"
              value={createEmail}
              onChange={(e) => setCreateEmail(e.target.value)}
              placeholder={t("usersEmailPlaceholder")}
            />
          </div>

          <div className="grid gap-2">
            <Label htmlFor="create-servant-grade">{t("usersGradeLabel")}</Label>
            <select
              id="create-servant-grade"
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

          <div className="col-span-1 sm:col-span-2 lg:col-span-3">
            <Button className="w-full sm:w-auto" disabled={isCreating} onClick={() => void createServant()}>
              {isCreating ? t("commonCreating") : t("servantsCreateServantButton")}
            </Button>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="border-b">
          <CardTitle>{t("servantsAccountsTitle")}</CardTitle>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="text-sm text-muted-foreground">{t("commonLoading")}</div>
          ) : profiles.length === 0 ? (
            <div className="text-sm text-muted-foreground">{t("servantsNoneFound")}</div>
          ) : (
            <div className="overflow-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>{t("servantsTableName")}</TableHead>
                    <TableHead>{t("servantsTableAcademicId")}</TableHead>
                    <TableHead>{t("servantsTableGrade")}</TableHead>
                    <TableHead>{t("servantsTableStatus")}</TableHead>
                    <TableHead className="text-right">{t("servantsTableAction")}</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {profiles.map((p) => {
                    const status = (p.account_status ?? "active").toLowerCase();
                    const isInactive = status === "inactive_pending_admin" || status === "inactive";
                    return (
                      <TableRow key={p.id}>
                        <TableCell className="font-medium">
                          {p.name ?? "—"}
                        </TableCell>
                        <TableCell>{p.academic_id ?? "—"}</TableCell>
                        <TableCell>
                          {p.grade_id ? gradeNameById.get(p.grade_id) ?? p.grade_id : "—"}
                        </TableCell>
                        <TableCell>
                          <span
                            className={
                              isInactive
                                ? "text-destructive"
                                : "text-foreground"
                            }
                          >
                            {statusLabel(status)}
                          </span>
                        </TableCell>
                        <TableCell className="text-right">
                          <div className="flex flex-wrap sm:flex-nowrap justify-end gap-1.5 sm:gap-2">
                            <Button
                              variant={isInactive ? "default" : "destructive"}
                              size="sm"
                              disabled={togglingId === p.id || deletingId === p.id}
                              onClick={() => void toggleAccountStatus(p)}
                            >
                              {togglingId === p.id
                                ? t("commonWorking")
                                : isInactive
                                  ? t("servantsActivate")
                                  : t("servantsDeactivate")}
                            </Button>

                            <Button
                              variant="outline"
                              size="sm"
                              disabled={togglingId === p.id || deletingId === p.id}
                              onClick={() => void deleteServant(p)}
                            >
                              {deletingId === p.id ? t("commonDeleting") : t("commonDelete")}
                            </Button>
                          </div>
                        </TableCell>
                      </TableRow>
                    );
                  })}
                </TableBody>
              </Table>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
