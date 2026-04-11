import * as React from "react";

import { supabase } from "../lib/supabase";
import { ErrorBanner } from "../components/ErrorBanner";
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

type AcademicYearRow = {
  id: string;
  name?: string | null;
  status?: string | null;
  created_at?: string | null;
};

type GradeRow = {
  id: string;
  name?: string | null;
  code?: string | null;
  sort_order?: number | null;
};

type SubjectRow = {
  id: string;
  name?: string | null;
  grade_id?: string | null;
  active?: boolean | null;
};

type GradeSummaryRow = {
  gradeId: string;
  gradeName: string;
  runId: string;
  totalStudents: number;
  eligible: number;
  atRisk: number;
  notEligible: number;
  graduated: number;
};

type AllGradesSummary = {
  academicYearId: string;
  totalGrades: number;
  totalStudents: number;
  eligible: number;
  atRisk: number;
  notEligible: number;
  graduated: number;
  gradeSummaries: GradeSummaryRow[];
};

export function PromotionsPage() {
  const [years, setYears] = React.useState<AcademicYearRow[]>([]);
  const [grades, setGrades] = React.useState<GradeRow[]>([]);
  const [selectedYearId, setSelectedYearId] = React.useState<string | null>(null);
  const [selectedGradeId, setSelectedGradeId] = React.useState<string | null>(null);
  const [notes, setNotes] = React.useState("");
  const [subjects, setSubjects] = React.useState<SubjectRow[]>([]);
  const [isSubjectsFallback, setIsSubjectsFallback] = React.useState(false);
  const [subjectMinimumGrades, setSubjectMinimumGrades] = React.useState<Record<string, string>>({});
  const [subjectAttendanceDays, setSubjectAttendanceDays] = React.useState<Record<string, string>>({});

  const [minimumOverallAverage, setMinimumOverallAverage] = React.useState("70");
  const minimumSubjectGrade = "60";
  const minimumAttendance = "75";

  const [isLoading, setIsLoading] = React.useState(true);
  const [isRunning, setIsRunning] = React.useState(false);
  const [error, setError] = React.useState<string | null>(null);
  const [result, setResult] = React.useState<unknown>(null);
  const [criteriaSaving, setCriteriaSaving] = React.useState(false);

  const activeYear = React.useMemo(
    () => years.find((y) => y.status === "active") ?? null,
    [years],
  );

  const promotionSummary = React.useMemo<AllGradesSummary | null>(() => {
    if (!result || typeof result !== "object") return null;
    const row = result as Record<string, unknown>;
    const academicYearId = typeof row.academic_year_id === "string" ? row.academic_year_id : null;
    if (!academicYearId) return null;

    const gradeSummariesSource = Array.isArray(row.grade_summaries) ? row.grade_summaries : [];
    const gradeSummaries: GradeSummaryRow[] = gradeSummariesSource
      .filter((item): item is Record<string, unknown> => typeof item === "object" && item !== null)
      .map((item) => ({
        gradeId: typeof item.grade_id === "string" ? item.grade_id : "",
      gradeName: typeof item.grade_name === "string" ? item.grade_name : "Unknown grade",
      runId: typeof item.run_id === "string" ? item.run_id : "Preview",
        totalStudents: typeof item.total_students === "number" ? item.total_students : 0,
        eligible: typeof item.eligible === "number" ? item.eligible : 0,
        atRisk: typeof item.at_risk === "number" ? item.at_risk : 0,
        notEligible: typeof item.not_eligible === "number" ? item.not_eligible : 0,
        graduated: typeof item.graduated === "number" ? item.graduated : 0,
      }));

    return {
      academicYearId,
      totalGrades: typeof row.total_grades === "number" ? row.total_grades : gradeSummaries.length,
      totalStudents: typeof row.total_students === "number" ? row.total_students : 0,
      eligible: typeof row.eligible === "number" ? row.eligible : 0,
      atRisk: typeof row.at_risk === "number" ? row.at_risk : 0,
      notEligible: typeof row.not_eligible === "number" ? row.not_eligible : 0,
      graduated: typeof row.graduated === "number" ? row.graduated : 0,
      gradeSummaries,
    };
  }, [result]);

  function toNumberOrDefault(v: string, fallback: number): number {
    const n = Number(v);
    return Number.isFinite(n) ? n : fallback;
  }

  const load = React.useCallback(async () => {
    setError(null);
    setIsLoading(true);

    const [{ data: yearsData, error: yearsError }, { data: gradesData, error: gradesError }] =
      await Promise.all([
        supabase.from("academic_years").select("*").order("created_at", { ascending: false }),
        supabase.from("grades").select("*").order("sort_order", { ascending: true }).order("name", { ascending: true }),
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

    setIsLoading(false);
  }, []);

  React.useEffect(() => {
    void load();
  }, [load]);

  React.useEffect(() => {
    if (!selectedYearId && activeYear?.id) {
      setSelectedYearId(activeYear.id);
    }
  }, [activeYear?.id, selectedYearId]);

  React.useEffect(() => {
    if (!selectedGradeId && grades.length > 0) {
      setSelectedGradeId(grades[0].id);
    }
  }, [grades, selectedGradeId]);

  React.useEffect(() => {
    async function loadSubjects() {
      if (!selectedGradeId) {
        setSubjects([]);
        setIsSubjectsFallback(false);
        setSubjectMinimumGrades({});
        setSubjectAttendanceDays({});
        return;
      }

      const { data, error: subjectsError } = await supabase
        .from("subjects")
        .select("id,name,grade_id,active")
        .order("active", { ascending: false })
        .order("name", { ascending: true });

      if (subjectsError) {
        setError(subjectsError.message);
        setSubjects([]);
        setIsSubjectsFallback(false);
        setSubjectMinimumGrades({});
        setSubjectAttendanceDays({});
        return;
      }

      const rows = (data ?? []) as SubjectRow[];
      const forSelectedGrade = rows.filter((row) => row.grade_id === selectedGradeId);

      if (forSelectedGrade.length > 0) {
        setSubjects(forSelectedGrade);
        setIsSubjectsFallback(false);
        setSubjectMinimumGrades({});
        setSubjectAttendanceDays({});
      } else {
        setSubjects(rows);
        setIsSubjectsFallback(rows.length > 0);
        setSubjectMinimumGrades({});
        setSubjectAttendanceDays({});
      }
    }

    void loadSubjects();
  }, [selectedGradeId]);

  React.useEffect(() => {
    async function loadCriteria() {
      if (!selectedYearId || !selectedGradeId) return;

      const { data, error: loadError } = await supabase
        .from("promotion_criteria_sets")
        .select("*")
        .eq("academic_year_id", selectedYearId)
        .eq("grade_id", selectedGradeId)
        .maybeSingle();

      if (loadError || !data) return;

      const row = data as Record<string, unknown>;

      const moa = row["minimum_overall_average"];
      setMinimumOverallAverage(
        moa === null || moa === undefined ? "70" : String(moa),
      );

      const criteriaSetId = row["id"];
      if (criteriaSetId === null || criteriaSetId === undefined) {
        setSubjectMinimumGrades({});
        setSubjectAttendanceDays({});
        return;
      }

      const { data: subjectsCriteria, error: subjectCriteriaError } = await supabase
        .from("promotion_criteria_subjects")
        .select("subject_id,minimum_grade,minimum_attendance_days")
        .eq("criteria_set_id", String(criteriaSetId));

      if (subjectCriteriaError) {
        setError(subjectCriteriaError.message);
        return;
      }

      const minimumGradeMap: Record<string, string> = {};
      const attendanceDaysMap: Record<string, string> = {};
      for (const item of subjectsCriteria ?? []) {
        const subjectId = String(item.subject_id);
        const minimumGrade = item.minimum_grade;
        const attendanceDays = item.minimum_attendance_days;
        minimumGradeMap[subjectId] = minimumGrade === null || minimumGrade === undefined ? "" : String(minimumGrade);
        attendanceDaysMap[subjectId] = attendanceDays === null || attendanceDays === undefined ? "" : String(attendanceDays);
      }
      setSubjectMinimumGrades(minimumGradeMap);
      setSubjectAttendanceDays(attendanceDaysMap);
    }

    void loadCriteria();
  }, [selectedYearId, selectedGradeId]);

  async function saveCriteria() {
    setError(null);

    if (!selectedYearId || !selectedGradeId) {
      setError("Choose an academic year and grade before saving criteria.");
      return;
    }

    setCriteriaSaving(true);
    try {
      if (subjects.length === 0) {
        setError("No subjects found for the selected grade. Add subjects before saving promotion criteria.");
        return;
      }

      const missingSubjects = subjects.filter((subject) => {
        const raw = (subjectAttendanceDays[subject.id] ?? "").trim();
        return raw === "";
      });

      if (missingSubjects.length > 0) {
        setError("Enter minimum present days for every subject before saving criteria.");
        return;
      }

      const payload = {
        academic_year_id: selectedYearId,
        grade_id: selectedGradeId,
        minimum_overall_average: toNumberOrDefault(minimumOverallAverage, 70),
        minimum_subject_grade: toNumberOrDefault(minimumSubjectGrade, 60),
        minimum_attendance: toNumberOrDefault(minimumAttendance, 75),
      };

      const { data: criteriaSet, error: upsertError } = await supabase
        .from("promotion_criteria_sets")
        .upsert(payload, { onConflict: "academic_year_id,grade_id" })
        .select("id")
        .single();

      if (upsertError) {
        setError(
          `Failed to save criteria. Details: ${upsertError.message}`,
        );
        return;
      }

      const criteriaSetId = criteriaSet?.id;
      if (!criteriaSetId) {
        setError("Failed to save criteria subjects because criteria set id was not returned.");
        return;
      }

      const { data: existingRows, error: existingRowsError } = await supabase
        .from("promotion_criteria_subjects")
        .select("subject_id,required,minimum_grade,weight")
        .eq("criteria_set_id", criteriaSetId);

      if (existingRowsError) {
        setError(`Failed to load existing subject criteria. Details: ${existingRowsError.message}`);
        return;
      }

      const existingBySubject = new Map<string, {
        required: boolean | null;
        minimum_grade: number | null;
        weight: number | null;
      }>();

      for (const row of existingRows ?? []) {
        existingBySubject.set(String(row.subject_id), {
          required: row.required,
          minimum_grade: row.minimum_grade,
          weight: row.weight,
        });
      }

      const subjectRows = subjects.map((subject) => {
        const existing = existingBySubject.get(subject.id);
        const minimumGradeRaw = (subjectMinimumGrades[subject.id] ?? "").trim();
        const minimumGradeNum =
          minimumGradeRaw === ""
            ? null
            : toNumberOrDefault(minimumGradeRaw, 0);
        const minimumGrade =
          minimumGradeNum !== null && minimumGradeNum > 0
            ? minimumGradeNum
            : null;
        const raw = (subjectAttendanceDays[subject.id] ?? "").trim();
        return {
          criteria_set_id: criteriaSetId,
          subject_id: subject.id,
          required: existing?.required ?? true,
          minimum_grade: minimumGrade,
          weight: existing?.weight ?? null,
          minimum_attendance_days: toNumberOrDefault(raw, 0),
        };
      });

      if (subjectRows.length > 0) {
        const { error: upsertSubjectsError } = await supabase
          .from("promotion_criteria_subjects")
          .upsert(subjectRows, { onConflict: "criteria_set_id,subject_id" });

        if (upsertSubjectsError) {
          setError(`Failed to save subject attendance-day rules. Details: ${upsertSubjectsError.message}`);
          return;
        }
      }
    } finally {
      setCriteriaSaving(false);
    }
  }

  function buildPromotionNotes(): string | null {
    const trimmed = notes.trim();
    const config = {
      promotion_basis: "average_of_two_semester_averages",
      minimum_thresholds: {
        minimum_overall_average: minimumOverallAverage.trim() || null,
        minimum_subject_grade: minimumSubjectGrade,
        minimum_attendance: minimumAttendance.trim() || null,
      },
      subject_minimum_grades: subjects
        .map((subject) => {
          const raw = (subjectMinimumGrades[subject.id] ?? "").trim();
          if (!raw) return null;
          return {
            subject_id: subject.id,
            subject_name: subject.name ?? subject.id,
            minimum_grade: toNumberOrDefault(raw, 0),
          };
        })
        .filter((item): item is { subject_id: string; subject_name: string; minimum_grade: number } => item !== null),
      subject_minimum_attendance_days: subjects
        .map((subject) => {
          const raw = (subjectAttendanceDays[subject.id] ?? "").trim();
          if (!raw) return null;
          return {
            subject_id: subject.id,
            subject_name: subject.name ?? subject.id,
            minimum_attendance_days: toNumberOrDefault(raw, 0),
          };
        })
        .filter((item): item is { subject_id: string; subject_name: string; minimum_attendance_days: number } => item !== null),
    };

    if (!trimmed) return JSON.stringify({ config });
    return JSON.stringify({ notes: trimmed, config });
  }

  async function runPromotion() {
    setError(null);
    setResult(null);

    if (!selectedYearId) {
      setError("Choose an academic year.");
      return;
    }

    setIsRunning(true);
    try {
      const { data, error: rpcError } = await supabase.rpc("run_promotion_for_all_grades_with_summary", {
        p_academic_year_id: selectedYearId,
        p_notes: buildPromotionNotes(),
      });

      if (rpcError) {
        setError(rpcError.message);
        return;
      }

      setResult(data);
    } finally {
      setIsRunning(false);
    }
  }

  async function previewPromotion() {
    setError(null);
    setResult(null);

    if (!selectedYearId) {
      setError("Choose an academic year.");
      return;
    }

    setIsRunning(true);
    try {
      const { data, error: rpcError } = await supabase.rpc("preview_promotion_for_all_grades_with_summary", {
        p_academic_year_id: selectedYearId,
      });

      if (rpcError) {
        setError(rpcError.message);
        return;
      }

      setResult(data);
    } finally {
      setIsRunning(false);
    }
  }

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight text-foreground">Promotions</h1>
        <p className="text-muted-foreground mt-2">
          Run grade promotions for a given academic year based on the average of semester 1 and semester 2.
        </p>
      </div>

      {error ? <ErrorBanner title="Request failed" message={error} /> : null}

      <Card>
        <CardHeader className="border-b">
          <CardTitle>Promotion criteria</CardTitle>
        </CardHeader>
        <CardContent className="grid gap-4 md:grid-cols-3">
          <div className="md:col-span-3 rounded-md border bg-muted/30 px-3 py-2 text-xs text-muted-foreground">
            Semester progression is not blocked by averages. Grade promotion uses the average of both semester averages. Per-subject minimum grade is optional (leave it blank to promote by overall average only). Per-subject attendance days are weighted as present=1.0 day, permission=1.0 day, late=0.5 day, absent=0 day.
          </div>

          <div className="md:col-span-3 rounded-md border bg-muted/20 px-3 py-2 text-xs text-muted-foreground">
            Active academic year: <span className="font-medium text-foreground">{activeYear?.name ?? "Not set"}</span>
          </div>

          <div className="grid gap-2">
            <Label htmlFor="criteria-grade">Grade</Label>
            <select
              id="criteria-grade"
              className="h-10 w-full rounded-md border bg-input-background px-3 text-sm outline-none focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]"
              value={selectedGradeId ?? ""}
              onChange={(e) => setSelectedGradeId(e.target.value || null)}
              disabled={isLoading}
            >
              <option value="">—</option>
              {grades.map((g) => (
                <option key={g.id} value={g.id}>
                  {g.name ?? g.code ?? g.id}
                </option>
              ))}
            </select>
          </div>

          <div className="grid gap-2">
            <Label htmlFor="min-overall">Minimum overall average</Label>
            <Input
              id="min-overall"
              inputMode="decimal"
              placeholder="Default: 70"
              value={minimumOverallAverage}
              onChange={(e) => setMinimumOverallAverage(e.target.value)}
              disabled={isLoading}
            />
            <div className="text-xs text-muted-foreground">
              Used when measuring by overall subjects average.
            </div>
          </div>

          <div className="md:col-span-3 grid gap-3">
            <div className="flex items-center justify-between">
              <div className="text-sm font-medium">Per-subject requirements</div>
              <div className="text-xs text-muted-foreground">{subjects.length} subjects</div>
            </div>
            {isSubjectsFallback ? (
              <div className="text-xs text-amber-700 rounded-md border border-amber-300 bg-amber-50 px-3 py-2">
                No subjects are assigned to this grade yet. Showing all subjects so you can still configure minimum days.
              </div>
            ) : null}
            {subjects.length === 0 ? (
              <div className="text-xs text-muted-foreground rounded-md border bg-muted/20 px-3 py-2">
                No subjects found for this grade.
              </div>
            ) : (
              <>
                <div className="hidden rounded-md border md:block">
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>Subject</TableHead>
                        <TableHead>Minimum grade (optional)</TableHead>
                        <TableHead>Minimum Present Days</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {subjects.map((subject) => (
                        <TableRow key={`table-${subject.id}`}>
                          <TableCell>
                            <div className="text-sm font-medium">{subject.name ?? subject.id}</div>
                            <div className="text-xs text-muted-foreground">
                              {subject.active === false ? "Inactive subject" : "Active subject"}
                            </div>
                          </TableCell>
                          <TableCell>
                            <Input
                              inputMode="decimal"
                              placeholder="e.g. 60"
                              value={subjectMinimumGrades[subject.id] ?? ""}
                              onChange={(e) =>
                                setSubjectMinimumGrades((prev) => ({
                                  ...prev,
                                  [subject.id]: e.target.value,
                                }))
                              }
                              disabled={isLoading}
                            />
                          </TableCell>
                          <TableCell>
                            <Input
                              inputMode="decimal"
                              placeholder="e.g. 24"
                              required
                              value={subjectAttendanceDays[subject.id] ?? ""}
                              onChange={(e) =>
                                setSubjectAttendanceDays((prev) => ({
                                  ...prev,
                                  [subject.id]: e.target.value,
                                }))
                              }
                              disabled={isLoading}
                            />
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </div>

                <div className="grid gap-3 md:hidden">
                  {subjects.map((subject) => (
                    <div key={`card-${subject.id}`} className="rounded-lg border bg-card p-3">
                      <div className="mb-3">
                        <div className="text-sm font-medium">{subject.name ?? subject.id}</div>
                        <div className="text-xs text-muted-foreground">
                          {subject.active === false ? "Inactive subject" : "Active subject"}
                        </div>
                      </div>
                      <div className="grid gap-2">
                        <div className="grid gap-1">
                          <Label className="text-xs">Minimum grade (optional)</Label>
                          <Input
                            inputMode="decimal"
                            placeholder="e.g. 60"
                            value={subjectMinimumGrades[subject.id] ?? ""}
                            onChange={(e) =>
                              setSubjectMinimumGrades((prev) => ({
                                ...prev,
                                [subject.id]: e.target.value,
                              }))
                            }
                            disabled={isLoading}
                          />
                        </div>
                        <div className="grid gap-1">
                          <Label className="text-xs">Minimum present days</Label>
                          <Input
                            inputMode="decimal"
                            placeholder="e.g. 24"
                            required
                            value={subjectAttendanceDays[subject.id] ?? ""}
                            onChange={(e) =>
                              setSubjectAttendanceDays((prev) => ({
                                ...prev,
                                [subject.id]: e.target.value,
                              }))
                            }
                            disabled={isLoading}
                          />
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </>
            )}
          </div>

          <div className="md:col-span-3 flex items-center gap-2">
            <Button
              variant="outline"
              disabled={isLoading || criteriaSaving || !selectedYearId || !selectedGradeId}
              onClick={() => void saveCriteria()}
            >
              {criteriaSaving ? "Saving…" : "Save criteria"}
            </Button>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="border-b">
          <CardTitle>Run promotion</CardTitle>
        </CardHeader>
        <CardContent className="grid gap-4 md:grid-cols-3">
          <div className="md:col-span-3 rounded-md border bg-muted/20 px-3 py-2 text-xs text-muted-foreground">
            Calculates promotion results for all grades in the active academic year (Eligible/At Risk/Not Eligible). To actually move eligible students to the next grade, start a new academic year from the Academic Year page.
          </div>

          <div className="grid gap-2 md:col-span-3">
            <Label htmlFor="notes">Notes</Label>
            <Input
              id="notes"
              placeholder="Optional run notes"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
            />
          </div>

          <div className="md:col-span-3">
            <div className="flex flex-wrap items-center gap-2">
              <Button disabled={isLoading || isRunning} onClick={() => void runPromotion()}>
                {isRunning ? "Running…" : "Run promotion"}
              </Button>
              <Button
                variant="outline"
                disabled={isLoading || isRunning || !selectedYearId}
                onClick={() => void previewPromotion()}
              >
                {isRunning ? "Running…" : "Preview"}
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="border-b">
          <CardTitle>Result</CardTitle>
        </CardHeader>
        <CardContent>
          {result ? (
            <div className="grid gap-4">
              <div className="rounded-lg border bg-muted/20 p-4">
                <div className="flex flex-wrap items-start justify-between gap-3">
                  <div>
                    <div className="text-sm font-semibold text-foreground">All-grades promotion completed</div>
                    <div className="mt-1 text-xs text-muted-foreground">Processed grades: {promotionSummary?.totalGrades ?? "—"}</div>
                  </div>
                </div>

                <div className="mt-4 grid gap-2 sm:grid-cols-2 lg:grid-cols-5">
                  <div className="rounded-md border bg-background p-3">
                    <div className="text-[11px] uppercase tracking-wide text-muted-foreground">Total</div>
                    <div className="mt-1 text-lg font-semibold text-foreground">{promotionSummary?.totalStudents ?? "—"}</div>
                  </div>
                  <div className="rounded-md border bg-emerald-50 p-3">
                    <div className="text-[11px] uppercase tracking-wide text-emerald-700">Eligible</div>
                    <div className="mt-1 text-lg font-semibold text-emerald-800">{promotionSummary?.eligible ?? "—"}</div>
                  </div>
                  <div className="rounded-md border bg-amber-50 p-3">
                    <div className="text-[11px] uppercase tracking-wide text-amber-700">At Risk</div>
                    <div className="mt-1 text-lg font-semibold text-amber-800">{promotionSummary?.atRisk ?? "—"}</div>
                  </div>
                  <div className="rounded-md border bg-rose-50 p-3">
                    <div className="text-[11px] uppercase tracking-wide text-rose-700">Not Eligible</div>
                    <div className="mt-1 text-lg font-semibold text-rose-800">{promotionSummary?.notEligible ?? "—"}</div>
                  </div>
                  <div className="rounded-md border bg-primary/10 p-3">
                    <div className="text-[11px] uppercase tracking-wide text-primary">Graduated</div>
                    <div className="mt-1 text-lg font-semibold text-primary">{promotionSummary?.graduated ?? "—"}</div>
                  </div>
                </div>

                <div className="mt-4 rounded-md border bg-background">
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>Grade</TableHead>
                        <TableHead>Students</TableHead>
                        <TableHead>Eligible</TableHead>
                        <TableHead>At Risk</TableHead>
                        <TableHead>Not Eligible</TableHead>
                        <TableHead>Graduated</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {promotionSummary?.gradeSummaries.map((gradeSummary) => (
                        <TableRow key={gradeSummary.gradeId}>
                          <TableCell>
                            <div className="font-medium text-foreground">{gradeSummary.gradeName}</div>
                            <div className="text-xs text-muted-foreground">Run: {gradeSummary.runId}</div>
                          </TableCell>
                          <TableCell>{gradeSummary.totalStudents}</TableCell>
                          <TableCell className="text-emerald-700 font-medium">{gradeSummary.eligible}</TableCell>
                          <TableCell className="text-amber-700 font-medium">{gradeSummary.atRisk}</TableCell>
                          <TableCell className="text-rose-700 font-medium">{gradeSummary.notEligible}</TableCell>
                          <TableCell className="text-primary font-medium">{gradeSummary.graduated}</TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </div>
              </div>
            </div>
          ) : (
            <div className="text-sm text-muted-foreground">
              No result yet.
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
