import {
  createBrowserRouter,
  Navigate,
  RouterProvider,
} from "react-router";

import { RequireAuth } from "./layout/RequireAuth";
import { AdminLayout } from "./layout/AdminLayout";
import { SignInPage } from "./pages/SignInPage";
import { AcademicYearsPage } from "./pages/AcademicYearsPage";
import { UsersPage } from "./pages/UsersPage";
import { GradesPage } from "./pages/GradesPage";
import { SubjectsPage } from "./pages/SubjectsPage";
import { PromotionsPage } from "./pages/PromotionsPage";
import { AnnouncementsPage } from "./pages/AnnouncementsPage";
import { ServantsPage } from "./pages/ServantsPage";
import { DashboardPage } from "./pages/DashboardPage";
import { GraduatesPage } from "./pages/GraduatesPage";
import { DocumentsPage } from "./pages/DocumentsPage";
import { t } from "./i18n/t";

const router = createBrowserRouter([
  { path: "/sign-in", element: <SignInPage /> },
  {
    element: <RequireAuth />,
    children: [
      {
        element: <AdminLayout />,
        children: [
          { index: true, element: <Navigate to="/admin/dashboard" replace /> },

          // Admin routes
          { path: "/admin/dashboard", element: <DashboardPage /> },
          { path: "/admin/users", element: <UsersPage /> },
          { path: "/admin/graduates", element: <GraduatesPage /> },
          { path: "/admin/servants", element: <ServantsPage /> },
          { path: "/admin/academic-year", element: <AcademicYearsPage /> },
          { path: "/admin/promotions", element: <PromotionsPage /> },
          { path: "/admin/announcements", element: <AnnouncementsPage /> },
          { path: "/admin/grades", element: <GradesPage /> },
          { path: "/admin/subjects", element: <SubjectsPage /> },
          { path: "/admin/documents", element: <DocumentsPage /> },
          { path: "/admin/documents/:language", element: <DocumentsPage /> },

          // Back-compat redirects
          { path: "/academic-years", element: <Navigate to="/admin/academic-year" replace /> },
          { path: "/users", element: <Navigate to="/admin/users" replace /> },
          { path: "/graduates", element: <Navigate to="/admin/graduates" replace /> },
          { path: "/grades", element: <Navigate to="/admin/grades" replace /> },
          { path: "/subjects", element: <Navigate to="/admin/subjects" replace /> },
        ],
      },
    ],
  },
  {
    path: "*",
    element: (
      <div className="min-h-svh flex items-center justify-center text-sm text-muted-foreground">
        {t("commonNotFound")}
      </div>
    ),
  },
]);

export function AppRouter() {
  return <RouterProvider router={router} />;
}
