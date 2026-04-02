import * as React from "react";
import { Navigate, useLocation } from "react-router";

import { useAuth } from "../auth/useAuth";
import { supabase } from "../lib/supabase";
import { ErrorBanner } from "../components/ErrorBanner";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "../components/ui/card";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";
import { t } from "../i18n/t";

export function SignInPage() {
  const { session } = useAuth();
  const location = useLocation();

  const [email, setEmail] = React.useState("");
  const [password, setPassword] = React.useState("");
  const [error, setError] = React.useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = React.useState(false);

  const locationState = location.state as
    | { from?: string; message?: string }
    | null
    | undefined;

  const redirectTo =
    locationState?.from ?? "/admin/academic-year";

  const preAuthMessage = locationState?.message ?? null;

  if (session) {
    return <Navigate to={redirectTo} replace />;
  }

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setIsSubmitting(true);
    try {
      const { error: signInError } = await supabase.auth.signInWithPassword({
        email,
        password,
      });
      if (signInError) {
        setError(signInError.message);
      }
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div className="min-h-svh bg-background text-foreground flex items-center justify-center px-4">
      <Card className="w-full max-w-md">
        <CardHeader>
          <CardTitle>{t("authAdminSignInTitle")}</CardTitle>
          <CardDescription>
            {t("authSignInDescription")}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form className="flex flex-col gap-4" onSubmit={onSubmit}>
            <div className="grid gap-2">
              <Label htmlFor="email">{t("authEmailLabel")}</Label>
              <Input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                autoComplete="email"
                required
              />
            </div>

            <div className="grid gap-2">
              <Label htmlFor="password">{t("authPasswordLabel")}</Label>
              <Input
                id="password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                autoComplete="current-password"
                required
              />
            </div>

            {preAuthMessage ? (
              <ErrorBanner title={t("authAccessDeniedTitle")} message={preAuthMessage} />
            ) : null}

            {error ? <ErrorBanner title={t("authSignInFailedTitle")} message={error} /> : null}

            <Button type="submit" disabled={isSubmitting}>
              {isSubmitting ? t("authSigningIn") : t("authSignInButton")}
            </Button>

            <div className="text-xs text-muted-foreground">
              {t("authRlsNote")}
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
