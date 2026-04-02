import * as React from "react";

import { supabase } from "../lib/supabase";
import { ErrorBanner } from "../components/ErrorBanner";
import { t } from "../i18n/t";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
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
  const [actionId, setActionId] = React.useState<string | null>(null);

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

  async function toggleAccountStatus(p: ProfileRow) {
    setError(null);
    setActionId(p.id);

    try {
      const current = (p.account_status ?? "active").toLowerCase();
      const isInactive = current === "inactive_pending_admin" || current === "inactive";
      const next = isInactive ? "active" : "inactive_pending_admin";
      const actionLabel = next === "active" ? t("usersActivate") : t("usersDeactivate");
      if (!window.confirm(t("servantsConfirmToggleStatus", { action: actionLabel, name: p.name ?? p.id }))) {
        return;
      }

      const { error: fnError } = await supabase.functions.invoke(
        "admin-set-account-status",
        { body: { user_id: p.id, account_status: next } },
      );

      if (fnError) {
        setError(fnError.message);
        return;
      }

      setProfiles((prev) =>
        prev.map((x) => (x.id === p.id ? { ...x, account_status: next } : x)),
      );
    } finally {
      setActionId(null);
    }
  }

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight text-foreground">{t("servantsTitle")}</h1>
        <p className="text-muted-foreground mt-2">
          {t("servantsSubtitle")}
        </p>
      </div>

      {error ? <ErrorBanner title={t("commonRequestFailed")} message={error} /> : null}

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
                          <Button
                            variant={isInactive ? "default" : "destructive"}
                            size="sm"
                            disabled={actionId === p.id}
                            onClick={() => void toggleAccountStatus(p)}
                          >
                            {actionId === p.id
                              ? t("commonWorking")
                              : isInactive
                                ? t("usersActivate")
                                : t("usersDeactivate")}
                          </Button>
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
