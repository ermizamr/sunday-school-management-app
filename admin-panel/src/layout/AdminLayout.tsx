import { NavLink, Outlet } from "react-router";
import { 
  LayoutDashboard, 
  Users, 
  UserCog, 
  CalendarDays, 
  TrendingUp, 
  Megaphone, 
  GraduationCap, 
  BookOpen, 
  LogOut,
  ShieldCheck
} from "lucide-react";

import { Button } from "../components/ui/button";
import { useAuth } from "../auth/AuthProvider";

const navItems = [
  { to: "/admin/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { to: "/admin/users", label: "Users", icon: Users },
  { to: "/admin/servants", label: "Servants", icon: UserCog },
  { to: "/admin/academic-year", label: "Academic Year", icon: CalendarDays },
  { to: "/admin/promotions", label: "Promotions", icon: TrendingUp },
  { to: "/admin/announcements", label: "Announcements", icon: Megaphone },
  { to: "/admin/grades", label: "Grades", icon: GraduationCap },
  { to: "/admin/subjects", label: "Subjects", icon: BookOpen },
] as const;

export function AdminLayout() {
  const { user, signOut } = useAuth();

  return (
    <div className="flex h-svh w-full bg-background text-foreground overflow-hidden font-sans">
      {/* Sidebar */}
      <aside className="w-64 bg-card border-r border-border/60 flex flex-col shadow-sm z-10 shrink-0">
        <div className="h-16 flex items-center px-6 border-b border-border/50">
          <div className="flex items-center gap-2 text-primary">
            <ShieldCheck className="w-6 h-6" />
            <span className="font-bold text-lg tracking-wide">Admin Portal</span>
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
              <item.icon className="w-4 h-4" />
              {item.label}
            </NavLink>
          ))}
        </nav>

        <div className="p-4 border-t border-border/50 bg-card">
          <div className="flex items-center gap-3 mb-4 px-2">
            <div className="w-9 h-9 rounded-full bg-accent text-accent-foreground flex items-center justify-center font-bold shadow-sm">
              {user?.email?.[0].toUpperCase() ?? "A"}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-semibold text-foreground truncate">
                {user?.email?.split('@')[0] ?? "Admin User"}
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
            Sign out
          </Button>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 flex flex-col min-w-0 overflow-hidden relative">
        {/* Subtle decorative background gradient */}
        <div className="absolute top-0 left-0 right-0 h-64 bg-gradient-to-b from-primary/5 to-transparent pointer-events-none -z-10" />
        
        <div className="flex-1 overflow-y-auto">
          <div className="p-6 md:p-8 max-w-7xl mx-auto">
            <Outlet />
          </div>
        </div>
      </main>
    </div>
  );
}
