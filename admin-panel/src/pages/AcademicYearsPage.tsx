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

type AcademicYearRow = {
  id: string;
  name?: string | null;
  status?: string | null;
  current_period?: string | null;
  semester1_end_date?: string | null;
  semester2_start_date?: string | null;
  created_at?: string | null;
};

export function AcademicYearsPage() {
  const [years, setYears] = React.useState<AcademicYearRow[]>([]);
  const [isLoading, setIsLoading] = React.useState(true);
  const [error, setError] = React.useState<string | null>(null);

  const [newName, setNewName] = React.useState("");
  const [startDate, setStartDate] = React.useState("");
  const [endDate, setEndDate] = React.useState("");
  const [isCreating, setIsCreating] = React.useState(false);
  const [isEnding, setIsEnding] = React.useState(false);
  const [archivingId, setArchivingId] = React.useState<string | null>(null);
  const [isUpdatingPeriod, setIsUpdatingPeriod] = React.useState(false);
  const [isEndingSemester1, setIsEndingSemester1] = React.useState(false);
  const [isStartingSemester2, setIsStartingSemester2] = React.useState(false);
  const [semester1EndDateDraft, setSemester1EndDateDraft] = React.useState("");
  const [semester2StartDateDraft, setSemester2StartDateDraft] = React.useState("");

  const activeYear = years.find((y) => y.status === "active") ?? null;
  const [selectedPeriod, setSelectedPeriod] = React.useState<"semester1" | "semester2" | "break">("semester1");

  React.useEffect(() => {
    const period = activeYear?.current_period;
    if (period === "semester1" || period === "semester2" || period === "break") {
      setSelectedPeriod(period);
    } else {
      setSelectedPeriod("semester1");
    }

    setSemester1EndDateDraft(activeYear?.semester1_end_date ?? "");
    setSemester2StartDateDraft(activeYear?.semester2_start_date ?? "");
  }, [activeYear?.id, activeYear?.current_period, activeYear?.semester1_end_date, activeYear?.semester2_start_date]);

  const load = React.useCallback(async () => {
    setError(null);
    setIsLoading(true);
    const { data, error: loadError } = await supabase
      .from("academic_years")
      .select("*")
      .order("created_at", { ascending: false });

    if (loadError) {
      setError(loadError.message);
      setYears([]);
      setIsLoading(false);
      return;
    }

    setYears((data ?? []) as AcademicYearRow[]);
    setIsLoading(false);
  }, []);

  React.useEffect(() => {
    void load();
  }, [load]);

  function statusLabel(status: string | null | undefined): string {
    switch ((status ?? "").toLowerCase()) {
      case "active":
        return t("academicYearStatusActive");
      case "ended":
        return t("academicYearStatusEnded");
      case "archived":
        return t("academicYearStatusArchived");
      default:
        return status ?? "—";
    }
  }

  async function createYear(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setIsCreating(true);
    try {
      const name = newName.trim();
      const start = startDate.trim();
      const end = endDate.trim();

      if (!name || !start || !end) return;

      const { error: rpcError } = await supabase.rpc("start_new_academic_year", {
        p_name: name,
        p_start_date: start,
        p_end_date: end,
      });

      if (rpcError) {
        setError(rpcError.message);
        return;
      }

      setNewName("");
      setStartDate("");
      setEndDate("");
      await load();
    } finally {
      setIsCreating(false);
    }
  }

  async function endActiveYear() {
    if (!activeYear) return;
    if (!window.confirm(t("academicYearConfirmEndActive", { name: activeYear.name ?? activeYear.id }))) {
      return;
    }
    setError(null);
    setIsEnding(true);
    try {
      const { error: rpcError } = await supabase.rpc("end_academic_year", {
        p_academic_year_id: activeYear.id,
      });

      if (rpcError) {
        setError(rpcError.message);
        return;
      }

      await load();
    } finally {
      setIsEnding(false);
    }
  }

  async function archiveYear(yearId: string) {
    const targetYear = years.find((year) => year.id === yearId);
    if (!window.confirm(t("academicYearConfirmArchive", { name: targetYear?.name ?? yearId }))) {
      return;
    }
    setError(null);
    setArchivingId(yearId);
    try {
      const { error: rpcError } = await supabase.rpc("archive_academic_year", {
        p_academic_year_id: yearId,
      });

      if (rpcError) {
        setError(rpcError.message);
        return;
      }

      await load();
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : t("academicYearArchiveFailed"));
    } finally {
      setArchivingId(null);
    }
  }

  async function updateActivePeriod() {
    if (!activeYear) return;
    setError(null);
    setIsUpdatingPeriod(true);
    try {
      const { error: rpcError } = await supabase.rpc("set_academic_year_period", {
        p_academic_year_id: activeYear.id,
        p_period: selectedPeriod,
      });

      if (rpcError) {
        setError(rpcError.message);
        return;
      }

      await load();
    } finally {
      setIsUpdatingPeriod(false);
    }
  }

  async function endFirstSemester() {
    if (!activeYear || !semester1EndDateDraft) return;
    setError(null);
    setIsEndingSemester1(true);
    try {
      const { error: rpcError } = await supabase.rpc("end_first_semester", {
        p_academic_year_id: activeYear.id,
        p_semester1_end_date: semester1EndDateDraft,
      });

      if (rpcError) {
        setError(rpcError.message);
        return;
      }

      await load();
    } finally {
      setIsEndingSemester1(false);
    }
  }

  async function startSecondSemester() {
    if (!activeYear || !semester2StartDateDraft) return;
    setError(null);
    setIsStartingSemester2(true);
    try {
      const { error: rpcError } = await supabase.rpc("start_second_semester", {
        p_academic_year_id: activeYear.id,
        p_semester2_start_date: semester2StartDateDraft,
      });

      if (rpcError) {
        setError(rpcError.message);
        return;
      }

      await load();
    } finally {
      setIsStartingSemester2(false);
    }
  }

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight text-foreground">{t("academicYearTitle")}</h1>
        <p className="text-muted-foreground mt-2">
          {t("academicYearSubtitle")}
        </p>
      </div>

      {error ? (
        <ErrorBanner title={t("commonRequestFailed")} message={error} />
      ) : null}

      <Card>
        <CardHeader className="border-b">
          <CardTitle>{t("academicYearCurrentStatus")}</CardTitle>
        </CardHeader>
        <CardContent className="grid gap-3">
          <div className="text-sm">
            <span className="text-muted-foreground">{t("academicYearActiveYearLabel")} </span>
            <span className="font-medium">
              {activeYear?.name ?? t("commonNone")}
            </span>
          </div>
          <div className="grid gap-2 sm:max-w-lg md:grid-cols-2">
            <div className="grid gap-2">
              <Label htmlFor="semester1EndDate">{t("academicYearSemester1EndDate")}</Label>
              <Input
                id="semester1EndDate"
                type="date"
                value={semester1EndDateDraft}
                onChange={(e) => setSemester1EndDateDraft(e.target.value)}
                disabled={!activeYear || isEndingSemester1}
              />
              <Button
                variant="outline"
                disabled={!activeYear || !semester1EndDateDraft || isEndingSemester1}
                onClick={() => void endFirstSemester()}
              >
                {isEndingSemester1 ? t("academicYearEndingSemester1") : t("academicYearEndSemester1")}
              </Button>
            </div>

            <div className="grid gap-2">
              <Label htmlFor="semester2StartDate">{t("academicYearSemester2StartDate")}</Label>
              <Input
                id="semester2StartDate"
                type="date"
                value={semester2StartDateDraft}
                onChange={(e) => setSemester2StartDateDraft(e.target.value)}
                disabled={!activeYear || isStartingSemester2}
              />
              <Button
                variant="outline"
                disabled={!activeYear || !semester2StartDateDraft || isStartingSemester2}
                onClick={() => void startSecondSemester()}
              >
                {isStartingSemester2 ? t("academicYearStartingSemester2") : t("academicYearStartSemester2")}
              </Button>
            </div>
          </div>
          <div className="text-xs text-muted-foreground">
            {t("academicYearTransitionNote")}
          </div>
          <div className="grid gap-2 sm:max-w-sm">
            <Label htmlFor="currentPeriod">{t("academicYearCurrentPeriod")}</Label>
            <select
              id="currentPeriod"
              className="h-10 w-full rounded-md border bg-input-background px-3 text-sm outline-none focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]"
              value={selectedPeriod}
              onChange={(e) => setSelectedPeriod(e.target.value as "semester1" | "semester2" | "break")}
              disabled={!activeYear || isUpdatingPeriod}
            >
              <option value="semester1">{t("academicYearPeriodSemester1")}</option>
              <option value="semester2">{t("academicYearPeriodSemester2")}</option>
              <option value="break">{t("academicYearPeriodBreak")}</option>
            </select>
            <div className="text-xs text-muted-foreground">
              {t("academicYearPeriodNote")}
            </div>
            <div>
              <Button
                variant="outline"
                disabled={!activeYear || isUpdatingPeriod}
                onClick={() => void updateActivePeriod()}
              >
                {isUpdatingPeriod ? t("academicYearUpdatingPeriod") : t("academicYearUpdatePeriod")}
              </Button>
            </div>
          </div>
          <div>
            <Button
              variant="destructive"
              disabled={!activeYear || isEnding}
              onClick={() => void endActiveYear()}
            >
              {isEnding ? t("academicYearEndingActiveYear") : t("academicYearEndActiveYear")}
            </Button>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="border-b">
          <CardTitle>{t("academicYearStartNew")}</CardTitle>
        </CardHeader>
        <CardContent>
          <form className="grid gap-3 md:grid-cols-[1fr_auto]" onSubmit={createYear}>
            <div className="grid gap-2">
              <Label htmlFor="yearName">{t("academicYearYearName")}</Label>
              <Input
                id="yearName"
                placeholder={t("academicYearYearNamePlaceholder")}
                value={newName}
                onChange={(e) => setNewName(e.target.value)}
                required
              />
              <div className="grid gap-2 md:grid-cols-2">
                <div className="grid gap-2">
                  <Label htmlFor="startDate">{t("academicYearStartDate")}</Label>
                  <Input
                    id="startDate"
                    type="date"
                    value={startDate}
                    onChange={(e) => setStartDate(e.target.value)}
                    required
                  />
                </div>
                <div className="grid gap-2">
                  <Label htmlFor="endDate">{t("academicYearEndDate")}</Label>
                  <Input
                    id="endDate"
                    type="date"
                    value={endDate}
                    onChange={(e) => setEndDate(e.target.value)}
                    required
                  />
                </div>
              </div>
            </div>
            <div className="flex items-end">
              <Button type="submit" disabled={isCreating}>
                {isCreating ? t("commonCreating") : t("commonCreate")}
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="border-b">
          <CardTitle>{t("academicYearAllYears")}</CardTitle>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="text-sm text-muted-foreground">{t("commonLoading")}</div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>{t("academicYearTableName")}</TableHead>
                  <TableHead>{t("academicYearTableStatus")}</TableHead>
                  <TableHead>{t("academicYearTableSem1End")}</TableHead>
                  <TableHead>{t("academicYearTableSem2Start")}</TableHead>
                  <TableHead>{t("academicYearTableCreated")}</TableHead>
                  <TableHead />
                </TableRow>
              </TableHeader>
              <TableBody>
                {years.map((y) => (
                  <TableRow key={y.id}>
                    <TableCell className="font-medium">
                      {y.name ?? y.id}
                    </TableCell>
                    <TableCell>{statusLabel(y.status)}</TableCell>
                    <TableCell className="text-muted-foreground">{y.semester1_end_date ?? "—"}</TableCell>
                    <TableCell className="text-muted-foreground">{y.semester2_start_date ?? "—"}</TableCell>
                    <TableCell className="text-muted-foreground">
                      {y.created_at ? new Date(y.created_at).toLocaleString() : "—"}
                    </TableCell>
                    <TableCell className="text-right">
                      <Button
                        size="sm"
                        variant="outline"
                        disabled={y.status !== "ended" || archivingId === y.id}
                        onClick={() => void archiveYear(y.id)}
                      >
                        {archivingId === y.id ? t("commonArchiving") : t("commonArchive")}
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
