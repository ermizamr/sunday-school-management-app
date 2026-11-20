import { useEffect, useState } from "react";
import { supabase } from "../lib/supabase";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { Users, UserCog, Megaphone, Calendar } from "lucide-react";
import { t } from "../i18n/t";

interface DashboardStats {
  totalUsers: number;
  totalServants: number;
  activeAnnouncements: number;
  currentAcademicYear: string;
}

export function DashboardPage() {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function loadStats() {
      try {
        setLoading(true);
        setError(null);

        // Fetch Total Users (role = student) - count only since we don't need actual data here
        const { count: studentCount, error: studentError } = await supabase
          .from("profiles")
          .select("*", { count: "exact", head: true })
          .eq("role", "student");

        if (studentError) throw studentError;

        // Fetch Total Servants (role = servant)
        const { count: servantCount, error: servantError } = await supabase
          .from("profiles")
          .select("*", { count: "exact", head: true })
          .eq("role", "servant");

        if (servantError) throw servantError;

        // Fetch Announcements Count
        const { count: announcementCount, error: announcementError } = await supabase
          .from("announcements")
          .select("*", { count: "exact", head: true });

        if (announcementError) throw announcementError;

        // Fetch Active Academic Year
        const { data: activeYear, error: yearError } = await supabase
          .from("academic_years")
          .select("name")
          .eq("status", "active")
          .single();

        if (yearError && yearError.code !== "PGRST116") {
          // PGRST116 is No rows found for single(), which is fine if no year is active
          throw yearError;
        }

        setStats({
          totalUsers: studentCount || 0,
          totalServants: servantCount || 0,
          activeAnnouncements: announcementCount || 0,
          currentAcademicYear: activeYear?.name || t("dashboardNoActiveYear"),
        });
      } catch (err: unknown) {
        console.error("Failed to load dashboard stats", err);
        setError(err instanceof Error ? err.message : t("dashboardErrorFallback"));
      } finally {
        setLoading(false);
      }
    }

    loadStats();
  }, []);

  return (
    <div className="space-y-6 sm:space-y-8 max-w-6xl mx-auto pb-10">
      <div>
        <h1 className="text-2xl sm:text-4xl font-extrabold tracking-tight text-foreground">{t("dashboardTitle")}</h1>
        <p className="text-muted-foreground mt-1.5 sm:mt-2 text-sm sm:text-base md:text-lg whitespace-pre-line">
          {t("dashboardSubtitle")}
        </p>
      </div>

      {error && (
        <div className="rounded-xl border border-destructive/20 bg-destructive/10 text-destructive p-4 text-sm font-medium flex items-center gap-3">
          <div className="h-2 w-2 rounded-full bg-destructive animate-pulse shrink-0" />
          <span className="break-words">{error}</span>
        </div>
      )}

      {loading ? (
        <div className="grid gap-4 sm:gap-6 grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 animate-pulse">
          {[1, 2, 3, 4].map((i) => (
            <div key={i} className="h-32 sm:h-36 bg-muted rounded-2xl border border-border/50"></div>
          ))}
        </div>
      ) : (
        <div className="grid gap-4 sm:gap-6 grid-cols-1 sm:grid-cols-2 lg:grid-cols-4">
          <Card className="relative overflow-hidden group hover:shadow-lg hover:-translate-y-1 transition-all duration-300">
            <div className="absolute top-0 right-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity">
              <Users className="w-20 h-20 sm:w-24 sm:h-24 text-primary" />
            </div>
            <CardHeader className="flex flex-row items-center justify-between pb-2 relative z-10">
              <CardTitle className="text-xs sm:text-sm font-semibold text-muted-foreground uppercase tracking-wider">{t("dashboardTotalStudents")}</CardTitle>
              <div className="bg-primary/10 p-2 rounded-lg text-primary">
                <Users className="h-4 w-4 sm:h-5 sm:w-5" />
              </div>
            </CardHeader>
            <CardContent className="relative z-10">
              <div className="text-3xl sm:text-4xl font-bold text-foreground">{stats?.totalUsers ?? 0}</div>
            </CardContent>
            <div className="absolute bottom-0 left-0 h-1 w-full bg-primary" />
          </Card>

          <Card className="relative overflow-hidden group hover:shadow-lg hover:-translate-y-1 transition-all duration-300">
            <div className="absolute top-0 right-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity">
              <UserCog className="w-20 h-20 sm:w-24 sm:h-24 text-accent" />
            </div>
            <CardHeader className="flex flex-row items-center justify-between pb-2 relative z-10">
              <CardTitle className="text-xs sm:text-sm font-semibold text-muted-foreground uppercase tracking-wider">{t("dashboardTotalServants")}</CardTitle>
              <div className="bg-accent/20 p-2 rounded-lg text-accent-foreground">
                <UserCog className="h-4 w-4 sm:h-5 sm:w-5 text-accent-foreground" />
              </div>
            </CardHeader>
            <CardContent className="relative z-10">
              <div className="text-3xl sm:text-4xl font-bold text-foreground">{stats?.totalServants ?? 0}</div>
            </CardContent>
            <div className="absolute bottom-0 left-0 h-1 w-full bg-accent" />
          </Card>

          <Card className="relative overflow-hidden group hover:shadow-lg hover:-translate-y-1 transition-all duration-300">
            <div className="absolute top-0 right-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity">
              <Megaphone className="w-20 h-20 sm:w-24 sm:h-24 text-emerald-500" />
            </div>
            <CardHeader className="flex flex-row items-center justify-between pb-2 relative z-10">
              <CardTitle className="text-xs sm:text-sm font-semibold text-muted-foreground uppercase tracking-wider">{t("dashboardAnnouncements")}</CardTitle>
              <div className="bg-emerald-500/10 p-2 rounded-lg text-emerald-600">
                <Megaphone className="h-4 w-4 sm:h-5 sm:w-5" />
              </div>
            </CardHeader>
            <CardContent className="relative z-10">
              <div className="text-3xl sm:text-4xl font-bold text-foreground">{stats?.activeAnnouncements ?? 0}</div>
            </CardContent>
            <div className="absolute bottom-0 left-0 h-1 w-full bg-emerald-500" />
          </Card>

          <Card className="relative overflow-hidden group hover:shadow-lg hover:-translate-y-1 transition-all duration-300">
            <div className="absolute top-0 right-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity">
              <Calendar className="w-20 h-20 sm:w-24 sm:h-24 text-purple-500" />
            </div>
            <CardHeader className="flex flex-row items-center justify-between pb-2 relative z-10">
              <CardTitle className="text-xs sm:text-sm font-semibold text-muted-foreground uppercase tracking-wider">{t("dashboardActiveYear")}</CardTitle>
              <div className="bg-purple-500/10 p-2 rounded-lg text-purple-600">
                <Calendar className="h-4 w-4 sm:h-5 sm:w-5" />
              </div>
            </CardHeader>
            <CardContent className="relative z-10">
              <div className="text-2xl sm:text-3xl font-bold text-foreground truncate">{stats?.currentAcademicYear}</div>
            </CardContent>
            <div className="absolute bottom-0 left-0 h-1 w-full bg-purple-500" />
          </Card>
        </div>
      )}

      {/* Welcome & quick info section */}
      <div className="grid gap-6 grid-cols-1">
        <Card className="bg-gradient-to-r from-primary/5 via-transparent to-transparent border-primary/10">
          <CardHeader>
            <CardTitle className="text-xl sm:text-2xl flex items-center gap-2">
              <span className="bg-primary w-2 h-6 rounded-full inline-block" />
              {t("dashboardWelcomeTitle")}
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-muted-foreground text-sm sm:text-base md:text-lg max-w-3xl leading-relaxed">
              {t("dashboardWelcomeBody")}
            </p>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
