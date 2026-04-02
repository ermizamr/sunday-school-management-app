import * as React from "react";

import { supabase } from "../lib/supabase";
import { ErrorBanner } from "../components/ErrorBanner";
import { t } from "../i18n/t";
import { Button } from "../components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "../components/ui/card";
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

type SubjectRow = {
  id: string;
  name?: string | null;
  grade_id?: string | null;
  passing_grade?: number | null;
  weight?: number | null;
  active?: boolean | null;
};

type GradeRow = {
  id: string;
  name?: string | null;
  code?: string | null;
};

type SubjectPrerequisiteRow = {
  subject_id: string;
  prerequisite_subject_id: string;
  minimum_score?: number | null;
};

type Draft = {
  name: string;
  grade_id: string | null;
  passing_grade: string;
  weight: string;
  active: boolean;
};

function toNumberOrNull(value: string): number | null {
  const trimmed = value.trim();
  if (!trimmed) return null;
  const n = Number(trimmed);
  if (Number.isNaN(n)) return null;
  return n;
}

export function SubjectsPage() {
  const [subjects, setSubjects] = React.useState<SubjectRow[]>([]);
  const [grades, setGrades] = React.useState<GradeRow[]>([]);
  const [prerequisites, setPrerequisites] = React.useState<SubjectPrerequisiteRow[]>([]);
  const [drafts, setDrafts] = React.useState<Record<string, Draft>>({});
  const [prerequisiteDrafts, setPrerequisiteDrafts] = React.useState<
    Record<string, { prerequisite_subject_id: string | null; minimum_score: string }>
  >({});

  const [filterGradeId, setFilterGradeId] = React.useState<string | null>(null);

  const [isLoading, setIsLoading] = React.useState(true);
  const [error, setError] = React.useState<string | null>(null);

  const [createName, setCreateName] = React.useState("");
  const [createGradeId, setCreateGradeId] = React.useState<string | null>(null);
  const [createPassing, setCreatePassing] = React.useState("");
  const [createWeight, setCreateWeight] = React.useState("");
  const [createActive, setCreateActive] = React.useState(true);
  const [createIsPrerequisite, setCreateIsPrerequisite] = React.useState(false);

  const [isCreating, setIsCreating] = React.useState(false);
  const [savingId, setSavingId] = React.useState<string | null>(null);

  const gradeNameById = React.useMemo(() => {
    return new Map(
      grades.map((g) => [g.id, g.name ?? g.code ?? g.id] as const),
    );
  }, [grades]);

  const visibleSubjects = React.useMemo(() => {
    if (!filterGradeId) return subjects;
    return subjects.filter((s) => s.grade_id === filterGradeId);
  }, [subjects, filterGradeId]);

  const load = React.useCallback(async () => {
    setError(null);
    setIsLoading(true);

    const [
      { data: gradesData, error: gradesError },
      { data: subjectsData, error: subjectsError },
      { data: prereqData, error: prereqError },
    ] =
      await Promise.all([
        supabase.from("grades").select("*").order("name"),
        supabase.from("subjects").select("*").order("name"),
        supabase
          .from("subject_prerequisites")
          .select("subject_id, prerequisite_subject_id, minimum_score"),
      ]);

    if (gradesError) {
      setError(gradesError.message);
      setGrades([]);
    } else {
      setGrades((gradesData ?? []) as GradeRow[]);
    }

    if (subjectsError) {
      setError(subjectsError.message);
      setSubjects([]);
    } else {
      setSubjects((subjectsData ?? []) as SubjectRow[]);
    }

    if (prereqError) {
      setError(prereqError.message);
      setPrerequisites([]);
    } else {
      setPrerequisites((prereqData ?? []) as SubjectPrerequisiteRow[]);
    }

    setDrafts({});
    setPrerequisiteDrafts({});
    setIsLoading(false);
  }, []);

  React.useEffect(() => {
    void load();
  }, [load]);

  function draftFor(s: SubjectRow): Draft {
    return (
      drafts[s.id] ?? {
        name: s.name ?? "",
        grade_id: s.grade_id ?? null,
        passing_grade:
          s.passing_grade === null || s.passing_grade === undefined
            ? ""
            : String(s.passing_grade),
        weight: s.weight === null || s.weight === undefined ? "" : String(s.weight),
        active: s.active ?? true,
      }
    );
  }

  function prerequisiteDraftFor(subjectId: string): {
    prerequisite_subject_id: string | null;
    minimum_score: string;
  } {
    const current = prerequisites.find((p) => p.subject_id === subjectId) ?? null;
    return (
      prerequisiteDrafts[subjectId] ?? {
        prerequisite_subject_id: current?.prerequisite_subject_id ?? null,
        minimum_score:
          current?.minimum_score === null || current?.minimum_score === undefined
            ? ""
            : String(current.minimum_score),
      }
    );
  }

  async function createSubject() {
    setError(null);
    const name = createName.trim();
    const passingGrade = toNumberOrNull(createPassing);
    if (!name) {
      setError(t("subjectsValidationNameRequired"));
      return;
    }
    if (passingGrade === null) {
      setError(t("subjectsValidationPassingRequired"));
      return;
    }

    setIsCreating(true);
    try {
      const { error: insertError } = await supabase
        .from("subjects")
        .insert({
          name,
          grade_id: createGradeId,
          passing_grade: passingGrade,
          weight: toNumberOrNull(createWeight),
          active: createActive,
        })
        .select("id")
        .single();

      if (insertError) {
        setError(insertError.message);
        return;
      }

      setCreateName("");
      setCreateGradeId(null);
      setCreatePassing("");
      setCreateWeight("");
      setCreateActive(true);
      setCreateIsPrerequisite(false);

      await load();
    } finally {
      setIsCreating(false);
    }
  }

  async function saveSubject(id: string) {
    const d = drafts[id];
    const p = prerequisiteDraftFor(id);
    if (!d && !prerequisiteDrafts[id]) return;

    setError(null);
    setSavingId(id);
    try {
      if (d) {
        const passingGrade = toNumberOrNull(d.passing_grade);
        if (passingGrade === null) {
          setError(t("subjectsValidationPassingRequired"));
          return;
        }

        const { error: updateError } = await supabase
          .from("subjects")
          .update({
            name: d.name.trim() || null,
            grade_id: d.grade_id,
            passing_grade: passingGrade,
            weight: toNumberOrNull(d.weight),
            active: d.active,
          })
          .eq("id", id);

        if (updateError) {
          setError(updateError.message);
          return;
        }
      }

      const prerequisiteSubjectId = p.prerequisite_subject_id;
      const minimumScore = toNumberOrNull(p.minimum_score);

      const { error: clearError } = await supabase
        .from("subject_prerequisites")
        .delete()
        .eq("subject_id", id);

      if (clearError) {
        setError(clearError.message);
        return;
      }

      if (prerequisiteSubjectId) {
        const { error: insertError } = await supabase
          .from("subject_prerequisites")
          .insert({
            subject_id: id,
            prerequisite_subject_id: prerequisiteSubjectId,
            minimum_score: minimumScore,
          });

        if (insertError) {
          setError(insertError.message);
          return;
        }
      }

      await load();
    } finally {
      setSavingId(null);
    }
  }

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight text-foreground">{t("subjectsTitle")}</h1>
        <p className="text-muted-foreground mt-2">
          {t("subjectsSubtitle")}
        </p>
      </div>

      {error ? (
        <ErrorBanner title={t("commonRequestFailed")} message={error} />
      ) : null}

      <Card>
        <CardHeader className="border-b">
          <CardTitle>{t("subjectsCreateTitle")}</CardTitle>
          <CardDescription>{t("subjectsSchemaNote")}</CardDescription>
        </CardHeader>
        <CardContent className="grid gap-4 md:grid-cols-5">
          <div className="md:col-span-2">
            <Label htmlFor="create-name">{t("subjectsNameLabel")}</Label>
            <Input
              id="create-name"
              placeholder={t("subjectsNamePlaceholder")}
              value={createName}
              onChange={(e) => setCreateName(e.target.value)}
            />
          </div>

          <div>
            <Label htmlFor="create-grade">{t("subjectsGradeLabel")}</Label>
            <select
              id="create-grade"
              className="mt-2 h-10 w-full rounded-md border bg-input-background px-3 text-sm outline-none focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]"
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

          <div>
            <Label htmlFor="create-passing">{t("subjectsPassingLabel")}</Label>
            <Input
              id="create-passing"
              placeholder="50"
              value={createPassing}
              onChange={(e) => setCreatePassing(e.target.value)}
            />
          </div>

          <div>
            <Label htmlFor="create-weight">{t("subjectsWeightLabel")}</Label>
            <Input
              id="create-weight"
              placeholder="1"
              value={createWeight}
              onChange={(e) => setCreateWeight(e.target.value)}
            />
          </div>

          <div className="md:col-span-5 flex items-center justify-between gap-3">
            <div className="flex flex-wrap items-center gap-4">
              <label className="flex items-center gap-2 text-sm">
                <input
                  type="checkbox"
                  checked={createIsPrerequisite}
                  onChange={(e) => setCreateIsPrerequisite(e.target.checked)}
                />
                {t("subjectsIsPrerequisite")}
              </label>
              {createIsPrerequisite ? (
                <div className="text-xs text-muted-foreground">
                  {t("subjectsPrereqHint")}
                </div>
              ) : null}
            </div>

            <label className="flex items-center gap-2 text-sm">
              <input
                type="checkbox"
                checked={createActive}
                onChange={(e) => setCreateActive(e.target.checked)}
              />
              {t("subjectsActiveLabel")}
            </label>

            <Button disabled={isCreating} onClick={() => void createSubject()}>
              {isCreating ? t("commonCreating") : t("commonCreate")}
            </Button>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="border-b">
          <CardTitle>{t("subjectsAllTitle")}</CardTitle>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="text-sm text-muted-foreground">{t("commonLoading")}</div>
          ) : (
            <div className="grid gap-3">
              <div className="grid gap-2 sm:max-w-sm">
                <Label htmlFor="filter-grade">{t("subjectsFilterByGrade")}</Label>
                <select
                  id="filter-grade"
                  className="h-10 w-full rounded-md border bg-input-background px-3 text-sm outline-none focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]"
                  value={filterGradeId ?? ""}
                  onChange={(e) => setFilterGradeId(e.target.value ? e.target.value : null)}
                >
                  <option value="">{t("subjectsAllGradesOption")}</option>
                  {grades.map((g) => (
                    <option key={g.id} value={g.id}>
                      {g.name ?? g.code ?? g.id}
                    </option>
                  ))}
                </select>
              </div>

              <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>{t("subjectsTableName")}</TableHead>
                  <TableHead>{t("subjectsTableGrade")}</TableHead>
                  <TableHead>{t("subjectsTablePrerequisite")}</TableHead>
                  <TableHead>{t("subjectsTablePrereqMin")}</TableHead>
                  <TableHead>{t("subjectsTablePassing")}</TableHead>
                  <TableHead>{t("subjectsTableWeight")}</TableHead>
                  <TableHead>{t("subjectsTableActive")}</TableHead>
                  <TableHead />
                </TableRow>
              </TableHeader>
              <TableBody>
                {visibleSubjects.map((s) => {
                  const d = draftFor(s);
                  const p = prerequisiteDraftFor(s.id);
                  const subjectsInSameGrade = subjects.filter(
                    (opt) => opt.id !== s.id && opt.grade_id === (d.grade_id ?? s.grade_id ?? null),
                  );
                  return (
                    <TableRow key={s.id}>
                      <TableCell>
                        <Input
                          value={d.name}
                          onChange={(e) =>
                            setDrafts((prev) => ({
                              ...prev,
                              [s.id]: {
                                ...d,
                                name: e.target.value,
                              },
                            }))
                          }
                        />
                      </TableCell>
                      <TableCell>
                        <select
                          className="h-10 w-full rounded-md border bg-input-background px-3 text-sm outline-none focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]"
                          value={d.grade_id ?? ""}
                          onChange={(e) =>
                            setDrafts((prev) => ({
                              ...prev,
                              [s.id]: {
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
                          {d.grade_id ? gradeNameById.get(d.grade_id) : t("subjectsNoGrade")}
                        </div>
                      </TableCell>
                      <TableCell>
                        <select
                          className="h-10 w-full rounded-md border bg-input-background px-3 text-sm outline-none focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]"
                          value={p.prerequisite_subject_id ?? ""}
                          disabled={subjectsInSameGrade.length === 0}
                          onChange={(e) =>
                            setPrerequisiteDrafts((prev) => ({
                              ...prev,
                              [s.id]: {
                                ...p,
                                prerequisite_subject_id: e.target.value ? e.target.value : null,
                              },
                            }))
                          }
                        >
                          <option value="">{t("subjectsNoneOption")}</option>
                          {subjectsInSameGrade.map((opt) => (
                            <option key={opt.id} value={opt.id}>
                              {opt.name ?? opt.id}
                            </option>
                          ))}
                        </select>
                      </TableCell>
                      <TableCell>
                        <Input
                          inputMode="decimal"
                          placeholder={t("subjectsPrereqMinPlaceholder")}
                          value={p.minimum_score}
                          onChange={(e) =>
                            setPrerequisiteDrafts((prev) => ({
                              ...prev,
                              [s.id]: {
                                ...p,
                                minimum_score: e.target.value,
                              },
                            }))
                          }
                        />
                      </TableCell>
                      <TableCell>
                        <Input
                          inputMode="decimal"
                          value={d.passing_grade}
                          onChange={(e) =>
                            setDrafts((prev) => ({
                              ...prev,
                              [s.id]: {
                                ...d,
                                passing_grade: e.target.value,
                              },
                            }))
                          }
                        />
                      </TableCell>
                      <TableCell>
                        <Input
                          inputMode="decimal"
                          value={d.weight}
                          onChange={(e) =>
                            setDrafts((prev) => ({
                              ...prev,
                              [s.id]: {
                                ...d,
                                weight: e.target.value,
                              },
                            }))
                          }
                        />
                      </TableCell>
                      <TableCell>
                        <label className="flex items-center gap-2 text-sm">
                          <input
                            type="checkbox"
                            checked={d.active}
                            onChange={(e) =>
                              setDrafts((prev) => ({
                                ...prev,
                                [s.id]: {
                                  ...d,
                                  active: e.target.checked,
                                },
                              }))
                            }
                          />
                          {d.active ? t("commonYes") : t("commonNo")}
                        </label>
                      </TableCell>
                      <TableCell className="text-right">
                        <Button
                          size="sm"
                          disabled={(!drafts[s.id] && !prerequisiteDrafts[s.id]) || savingId === s.id}
                          onClick={() => void saveSubject(s.id)}
                        >
                          {savingId === s.id ? t("commonSaving") : t("commonSave")}
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
