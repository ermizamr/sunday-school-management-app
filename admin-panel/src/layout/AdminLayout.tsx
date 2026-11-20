import { useState } from "react";
import { NavLink, Outlet, useLocation } from "react-router";
import { 
  LayoutDashboard, 
  Users, 
  UserCheck,
  UserCog, 
  CalendarDays, 
  TrendingUp, 
  Megaphone, 
  GraduationCap, 
  BookOpen, 
  FileText,
  LogOut,
  ShieldCheck,
  Menu,
  X
} from "lucide-react";

import { Button } from "../components/ui/button";
import { useAuth } from "../auth/useAuth";
import { t } from "../i18n/t";

const navItems = [
  { to: "/admin/dashboard", label: t("navDashboard"), icon: LayoutDashboard },
  { to: "/admin/users", label: t("navStudents"), icon: Users },
  { to: "/admin/servants", label: t("navServants"), icon: UserCog },
  { to: "/admin/grades", label: t("navGrades"), icon: GraduationCap },
  { to: "/admin/subjects", label: t("navSubjects"), icon: BookOpen },
  { to: "/admin/academic-year", label: t("navAcademicYear"), icon: CalendarDays },
  { to: "/admin/promotions", label: t("navPromotions"), icon: TrendingUp },
  { to: "/admin/announcements", label: t("navAnnouncements"), icon: Megaphone },
  { to: "/admin/graduates", label: t("navGraduates"), icon: UserCheck },
  { to: "/admin/documents", label: t("navDocuments"), icon: FileText },
] as const;

export function AdminLayout() {
  const { user, signOut } = useAuth();
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const location = useLocation();
  const [prevPathname, setPrevPathname] = useState(location.pathname);

  // Close mobile drawer on route change
  if (prevPathname !== location.pathname) {
    setPrevPathname(location.pathname);
    setIsMobileMenuOpen(false);
  }

  return (
    <div className="flex flex-col md:flex-row h-svh w-full bg-background text-foreground overflow-hidden font-sans">
      {/* Mobile Top App Bar */}
      <header className="md:hidden flex h-14 items-center justify-between px-4 border-b border-border/60 bg-card/95 backdrop-blur-md sticky top-0 z-30 shrink-0">
        <div className="flex items-center gap-3">
          <button
            type="button"
            className="p-2 -ml-2 rounded-lg text-muted-foreground hover:text-foreground hover:bg-secondary/80 transition-colors focus:outline-hidden focus:ring-2 focus:ring-ring"
            onClick={() => setIsMobileMenuOpen(true)}
            aria-label={t("commonMenu")}
          >
            <Menu className="w-5 h-5" />
          </button>
          <div className="flex items-center gap-2 text-primary font-bold text-base tracking-wide">
            <ShieldCheck className="w-5 h-5" />
            <span>{t("commonAdminPortal")}</span>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-full bg-accent text-accent-foreground flex items-center justify-center text-xs font-bold shadow-xs">
            {user?.email?.[0].toUpperCase() ?? "A"}
          </div>
        </div>
      </header>

      {/* Mobile Drawer Backdrop */}
      {isMobileMenuOpen && (
        <div
          className="fixed inset-0 bg-black/50 backdrop-blur-xs z-40 md:hidden transition-opacity"
          onClick={() => setIsMobileMenuOpen(false)}
          aria-hidden="true"
        />
      )}

      {/* Mobile Sidebar Drawer */}
      <aside
        className={`fixed inset-y-0 left-0 w-72 max-w-[85vw] bg-card border-r border-border/60 flex flex-col z-50 transition-transform duration-300 ease-in-out md:hidden shadow-2xl ${
          isMobileMenuOpen ? "translate-x-0" : "-translate-x-full"
        }`}
      >
        <div className="h-14 flex items-center justify-between px-5 border-b border-border/50">
          <div className="flex items-center gap-2 text-primary">
            <ShieldCheck className="w-5 h-5" />
            <span className="font-bold text-base tracking-wide">{t("commonAdminPortal")}</span>
          </div>
          <button
            type="button"
            className="p-1.5 rounded-lg text-muted-foreground hover:text-foreground hover:bg-secondary/80 transition-colors"
            onClick={() => setIsMobileMenuOpen(false)}
            aria-label={t("commonClose")}
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <nav className="flex-1 overflow-y-auto py-4 px-3 space-y-1">
          {navItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              onClick={() => setIsMobileMenuOpen(false)}
              className={({ isActive }) =>
                [
                  "flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-all duration-200",
                  isActive
                    ? "bg-primary text-primary-foreground shadow-md shadow-primary/20"
                    : "text-muted-foreground hover:bg-secondary/80 hover:text-foreground",
                ].join(" ")
              }
            >
              <item.icon className="w-4 h-4 shrink-0" />
              <span className="truncate">{item.label}</span>
            </NavLink>
          ))}
        </nav>

        <div className="p-4 border-t border-border/50 bg-card">
          <div className="flex items-center gap-3 mb-4 px-2">
            <div className="w-9 h-9 rounded-full bg-accent text-accent-foreground flex items-center justify-center font-bold shadow-sm shrink-0">
              {user?.email?.[0].toUpperCase() ?? "A"}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-semibold text-foreground truncate">
                {user?.email?.split("@")[0] ?? t("commonAdminUser")}
              </p>
              <p className="text-xs text-muted-foreground truncate">
                {user?.email ?? user?.id}
              </p>
            </div>
          </div>
          <Button 
            variant="outline" 
            className="w-full flex items-center justify-center gap-2 rounded-xl text-muted-foreground hover:text-destructive hover:bg-destructive/10 hover:border-destructive/30" 
            onClick={() => void signOut()}
          >
            <LogOut className="w-4 h-4" />
            {t("commonSignOut")}
          </Button>
        </div>
      </aside>

      {/* Desktop Sidebar */}
      <aside className="hidden md:flex w-64 bg-card border-r border-border/60 flex-col shadow-sm z-10 shrink-0 h-full">
        <div className="h-16 flex items-center px-6 border-b border-border/50">
          <div className="flex items-center gap-2 text-primary">
            <ShieldCheck className="w-6 h-6" />
            <span className="font-bold text-lg tracking-wide">{t("commonAdminPortal")}</span>
          </div>
        </div>

        <nav className="flex-1 overflow-y-auto py-4 px-3 space-y-1">
          {navItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              className={({ isActive }) =>
                [
                  "flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-all duration-200",
                  isActive
                    ? "bg-primary text-primary-foreground shadow-md shadow-primary/20"
                    : "text-muted-foreground hover:bg-secondary/80 hover:text-foreground",
                ].join(" ")
              }
            >
              <item.icon className="w-4 h-4 shrink-0" />
              <span className="truncate">{item.label}</span>
            </NavLink>
          ))}
        </nav>

        <div className="p-4 border-t border-border/50 bg-card">
          <div className="flex items-center gap-3 mb-4 px-2">
            <div className="w-9 h-9 rounded-full bg-accent text-accent-foreground flex items-center justify-center font-bold shadow-sm shrink-0">
              {user?.email?.[0].toUpperCase() ?? "A"}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-semibold text-foreground truncate">
                {user?.email?.split("@")[0] ?? t("commonAdminUser")}
              </p>
              <p className="text-xs text-muted-foreground truncate">
                {user?.email ?? user?.id}
              </p>
            </div>
          </div>
          <Button 
            variant="outline" 
            className="w-full flex items-center justify-center gap-2 rounded-xl text-muted-foreground hover:text-destructive hover:bg-destructive/10 hover:border-destructive/30" 
            onClick={() => void signOut()}
          >
            <LogOut className="w-4 h-4" />
            {t("commonSignOut")}
          </Button>
        </div>
      </aside>

      {/* Main Content Area */}
      <main className="flex-1 flex flex-col min-w-0 overflow-hidden relative">
        {/* Subtle decorative background gradient */}
        <div className="absolute top-0 left-0 right-0 h-64 bg-gradient-to-b from-primary/5 to-transparent pointer-events-none -z-10" />
        
        <div className="flex-1 overflow-y-auto">
          <div className="p-4 sm:p-6 md:p-8 max-w-7xl mx-auto">
            <Outlet />
          </div>
        </div>
      </main>
    </div>
  );
}
