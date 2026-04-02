import * as React from "react";

import { supabase } from "../lib/supabase";
import { ErrorBanner } from "../components/ErrorBanner";
import { t } from "../i18n/t";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { Input } from "../components/ui/input";
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

export function GraduatesPage() {
  const [profiles, setProfiles] = React.useState<ProfileRow[]>([]);
  const [grades, setGrades] = React.useState<GradeRow[]>([]);
  const [isLoading, setIsLoading] = React.useState(true);
  const [error, setError] = React.useState<string | null>(null);
  const [searchQuery, setSearchQuery] = React.useState("");

  const gradeNameById = React.useMemo(() => {
    return new Map(grades.map((g) => [g.id, g.name ?? g.code ?? g.id] as const));
  }, [grades]);

  const filteredProfiles = React.useMemo(() => {
    const query = searchQuery.trim().toLowerCase();
    return profiles.filter((p) => {
      if ((p.account_status ?? "").toLowerCase() !== "graduated") return false;
      if (!query) return true;
      return (
        (p.name ?? "").toLowerCase().includes(query) ||
        (p.academic_id ?? "").toLowerCase().includes(query) ||
        (p.id ?? "").toLowerCase().includes(query)
      );
    });
  }, [profiles, searchQuery]);

  const load = React.useCallback(async () => {
    setError(null);
    setIsLoading(true);

    const [{ data: gradesData, error: gradesError }, { data: profilesData, error: profilesError }] =
      await Promise.all([
        supabase.from("grades").select("*").order("name"),
        supabase
          .from("profiles")
          .select("*")
          .eq("role", "student")
          .eq("account_status", "graduated")
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

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight text-foreground">{t("graduatesTitle")}</h1>
        <p className="text-muted-foreground mt-2">
          {t("graduatesSubtitle")}
        </p>
      </div>

      {error ? <ErrorBanner title={t("commonRequestFailed")} message={error} /> : null}

      <Card>
        <CardHeader className="border-b flex flex-col gap-4 items-start sm:flex-row sm:items-center sm:justify-between py-5">
          <CardTitle>{t("graduatesAllTitle")}</CardTitle>
          <div className="w-full sm:w-72">
            <Input
              placeholder={t("graduatesSearchPlaceholder")}
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="bg-background"
            />
          </div>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="text-sm text-muted-foreground">{t("commonLoading")}</div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>{t("graduatesTableName")}</TableHead>
                  <TableHead>{t("graduatesTableAcademicId")}</TableHead>
                  <TableHead>{t("graduatesTableLastGrade")}</TableHead>
                  <TableHead>{t("graduatesTableStatus")}</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredProfiles.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={4} className="h-24 text-center text-muted-foreground">
                      {t("graduatesNoneFound")}
                    </TableCell>
                  </TableRow>
                ) : null}
                {filteredProfiles.map((p) => (
                  <TableRow key={p.id}>
                    <TableCell className="font-medium">{p.name ?? p.id}</TableCell>
                    <TableCell className="text-muted-foreground">{p.academic_id ?? "—"}</TableCell>
                    <TableCell className="text-muted-foreground">
                      {p.grade_id ? gradeNameById.get(p.grade_id) : "—"}
                    </TableCell>
                    <TableCell>
                      <span className="inline-flex rounded-full bg-primary/15 px-2 py-1 text-xs font-medium text-primary">
                        {t("graduatesStatusGraduated")}
                      </span>
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
