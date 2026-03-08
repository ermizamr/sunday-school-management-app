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
    } catch (err: any) {
      setError(err.message);
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
        <h1 className="text-3xl font-bold tracking-tight text-foreground">Academic Year</h1>
        <p className="text-muted-foreground mt-2">
          Manage the active academic year. Access is enforced by Supabase RLS.
        </p>
      </div>

      {error ? (
        <ErrorBanner title="Request failed" message={error} />
      ) : null}

      <Card>
        <CardHeader className="border-b">
          <CardTitle>Current status</CardTitle>
        </CardHeader>
        <CardContent className="grid gap-3">
          <div className="text-sm">
            <span className="text-muted-foreground">Active year: </span>
            <span className="font-medium">
              {activeYear?.name ?? "None"}
            </span>
          </div>
          <div className="grid gap-2 sm:max-w-lg md:grid-cols-2">
            <div className="grid gap-2">
              <Label htmlFor="semester1EndDate">Semester 1 end date</Label>
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
                {isEndingSemester1 ? "Ending semester 1…" : "End semester 1"}
              </Button>
            </div>

            <div className="grid gap-2">
              <Label htmlFor="semester2StartDate">Semester 2 start date</Label>
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
                {isStartingSemester2 ? "Starting semester 2…" : "Start semester 2"}
              </Button>
            </div>
          </div>
          <div className="text-xs text-muted-foreground">
            Semester transition is administrative only. No pass/fail is required to move from semester 1 to semester 2.
          </div>
          <div className="grid gap-2 sm:max-w-sm">
            <Label htmlFor="currentPeriod">Current period</Label>
            <select
              id="currentPeriod"
              className="h-10 w-full rounded-md border bg-input-background px-3 text-sm outline-none focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]"
              value={selectedPeriod}
              onChange={(e) => setSelectedPeriod(e.target.value as "semester1" | "semester2" | "break")}
              disabled={!activeYear || isUpdatingPeriod}
            >
              <option value="semester1">Semester 1</option>
              <option value="semester2">Semester 2</option>
              <option value="break">Break</option>
            </select>
            <div className="text-xs text-muted-foreground">
              Semester change is administrative only and does not block students by average.
            </div>
            <div>
              <Button
                variant="outline"
                disabled={!activeYear || isUpdatingPeriod}
                onClick={() => void updateActivePeriod()}
              >
                {isUpdatingPeriod ? "Updating period…" : "Update period"}
              </Button>
            </div>
          </div>
          <div>
            <Button
              variant="destructive"
              disabled={!activeYear || isEnding}
              onClick={() => void endActiveYear()}
            >
              {isEnding ? "Ending…" : "End active academic year"}
            </Button>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="border-b">
          <CardTitle>Start new academic year</CardTitle>
        </CardHeader>
        <CardContent>
          <form className="grid gap-3 md:grid-cols-[1fr_auto]" onSubmit={createYear}>
            <div className="grid gap-2">
              <Label htmlFor="yearName">Year name</Label>
              <Input
                id="yearName"
                placeholder="e.g., 2026-2027"
                value={newName}
                onChange={(e) => setNewName(e.target.value)}
                required
              />
              <div className="grid gap-2 md:grid-cols-2">
                <div className="grid gap-2">
                  <Label htmlFor="startDate">Start date</Label>
                  <Input
                    id="startDate"
                    type="date"
                    value={startDate}
                    onChange={(e) => setStartDate(e.target.value)}
                    required
                  />
                </div>
                <div className="grid gap-2">
                  <Label htmlFor="endDate">End date</Label>
                  <Input
                    id="endDate"
                    type="date"
                    value={endDate}
                    onChange={(e) => setEndDate(e.target.value)}
                    required
                  />
                </div>
              </div>
              <div className="text-xs text-muted-foreground">
                Calls the DB RPC <span className="font-mono">start_new_academic_year</span>.
              </div>
            </div>
            <div className="flex items-end">
              <Button type="submit" disabled={isCreating}>
                {isCreating ? "Creating…" : "Create"}
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="border-b">
          <CardTitle>All academic years</CardTitle>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="text-sm text-muted-foreground">Loading…</div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Name</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Semester 1 end</TableHead>
                  <TableHead>Semester 2 start</TableHead>
                  <TableHead>Created</TableHead>
                  <TableHead />
                </TableRow>
              </TableHeader>
              <TableBody>
                {years.map((y) => (
                  <TableRow key={y.id}>
                    <TableCell className="font-medium">
                      {y.name ?? y.id}
                    </TableCell>
                    <TableCell>{y.status ?? "—"}</TableCell>
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
                        {archivingId === y.id ? "Archiving…" : "Archive"}
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
