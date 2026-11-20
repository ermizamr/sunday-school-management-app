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

type GradeRow = {
  id: string;
  name?: string | null;
  code?: string | null;
  sort_order?: number | null;
};

export function GradesPage() {
  const [grades, setGrades] = React.useState<GradeRow[]>([]);
  const [isLoading, setIsLoading] = React.useState(true);
  const [error, setError] = React.useState<string | null>(null);

  const [newName, setNewName] = React.useState("");
  const [newCode, setNewCode] = React.useState("");
  const [newSortOrder, setNewSortOrder] = React.useState("");
  const [isCreating, setIsCreating] = React.useState(false);

  const [drafts, setDrafts] = React.useState<Record<string, GradeRow>>({});
  const [savingId, setSavingId] = React.useState<string | null>(null);

  const load = React.useCallback(async () => {
    setError(null);
    setIsLoading(true);

    const { data, error: loadError } = await supabase
      .from("grades")
      .select("*")
      .order("sort_order", { ascending: true })
      .order("name", { ascending: true });

    if (loadError) {
      setError(loadError.message);
      setGrades([]);
      setIsLoading(false);
      return;
    }

    setGrades((data ?? []) as GradeRow[]);
    setDrafts({});
    setIsLoading(false);
  }, []);

  React.useEffect(() => {
    void load();
  }, [load]);

  async function createGrade(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setIsCreating(true);

    try {
      const name = newName.trim();
      const code = newCode.trim();
      const sortOrder = newSortOrder.trim();

      const payload: Record<string, unknown> = { name };
      if (code) payload.code = code;
      if (sortOrder) payload.sort_order = Number(sortOrder);

      const { error: insertError } = await supabase.from("grades").insert(payload);
      if (insertError) {
        setError(insertError.message);
        return;
      }

      setNewName("");
      setNewCode("");
      setNewSortOrder("");
      await load();
    } finally {
      setIsCreating(false);
    }
  }

  async function saveGrade(id: string) {
    const draft = drafts[id];
    if (!draft) return;

    setError(null);
    setSavingId(id);
    try {
      const { error: updateError } = await supabase
        .from("grades")
        .update({
          name: (draft.name ?? "").trim() || null,
          code: (draft.code ?? "").trim() || null,
          sort_order:
            draft.sort_order === null || draft.sort_order === undefined
              ? null
              : Number(draft.sort_order),
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

  function draftFor(g: GradeRow): GradeRow {
    return drafts[g.id] ?? g;
  }

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-2xl sm:text-3xl font-bold tracking-tight text-foreground">{t("gradesTitle")}</h1>
        <p className="text-muted-foreground mt-1.5 sm:mt-2 text-sm sm:text-base">
          {t("gradesSubtitle")}
        </p>
      </div>

      {error ? (
        <ErrorBanner title={t("commonRequestFailed")} message={error} />
      ) : null}

      <Card>
        <CardHeader className="border-b">
          <CardTitle>{t("gradesAddGradeTitle")}</CardTitle>
        </CardHeader>
        <CardContent>
          <form className="grid gap-3 grid-cols-1 sm:grid-cols-2 md:grid-cols-3" onSubmit={createGrade}>
            <div className="grid gap-2">
              <Label htmlFor="gradeName">{t("gradesNameLabel")}</Label>
              <Input
                id="gradeName"
                value={newName}
                onChange={(e) => setNewName(e.target.value)}
                required
              />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="gradeCode">{t("gradesCodeLabel")}</Label>
              <Input
                id="gradeCode"
                value={newCode}
                onChange={(e) => setNewCode(e.target.value)}
              />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="gradeSort">{t("gradesSortOrderLabel")}</Label>
              <Input
                id="gradeSort"
                type="number"
                value={newSortOrder}
                onChange={(e) => setNewSortOrder(e.target.value)}
              />
            </div>
            <div className="col-span-1 sm:col-span-2 md:col-span-3">
              <Button className="w-full sm:w-auto" type="submit" disabled={isCreating}>
                {isCreating ? t("commonCreating") : t("commonCreate")}
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="border-b">
          <CardTitle>{t("gradesAllGradesTitle")}</CardTitle>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="text-sm text-muted-foreground">{t("commonLoading")}</div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="min-w-[140px]">{t("gradesNameLabel")}</TableHead>
                  <TableHead className="min-w-[120px]">{t("gradesCodeLabel")}</TableHead>
                  <TableHead className="min-w-[100px]">{t("gradesTableSort")}</TableHead>
                  <TableHead className="text-right" />
                </TableRow>
              </TableHeader>
              <TableBody>
                {grades.map((g) => {
                  const d = draftFor(g);
                  return (
                    <TableRow key={g.id}>
                      <TableCell className="min-w-[140px]">
                        <Input
                          value={d.name ?? ""}
                          onChange={(e) =>
                            setDrafts((prev) => ({
                              ...prev,
                              [g.id]: { ...d, name: e.target.value },
                            }))
                          }
                        />
                      </TableCell>
                      <TableCell className="min-w-[120px]">
                        <Input
                          value={d.code ?? ""}
                          onChange={(e) =>
                            setDrafts((prev) => ({
                              ...prev,
                              [g.id]: { ...d, code: e.target.value },
                            }))
                          }
                        />
                      </TableCell>
                      <TableCell className="min-w-[100px]">
                        <Input
                          type="number"
                          value={d.sort_order ?? ""}
                          onChange={(e) =>
                            setDrafts((prev) => ({
                              ...prev,
                              [g.id]: {
                                ...d,
                                sort_order:
                                  e.target.value === ""
                                    ? null
                                    : Number(e.target.value),
                              },
                            }))
                          }
                        />
                      </TableCell>
                      <TableCell className="text-right">
                        <Button
                          size="sm"
                          disabled={!drafts[g.id] || savingId === g.id}
                          onClick={() => void saveGrade(g.id)}
                        >
                          {savingId === g.id ? t("commonSaving") : t("commonSave")}
                        </Button>
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
