import { supabase } from "./supabase";

import { t } from "../i18n/t";

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL as string | undefined;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as
  | string
  | undefined;

export type InvokeEdgeFunctionResult<T> = {
  data: T | null;
  status: number | null;
  error: string | null;
};

function safeJsonParse(text: string): unknown {
  if (!text) return null;
  try {
    return JSON.parse(text);
  } catch {
    return { raw: text };
  }
}

export async function invokeEdgeFunction<T = unknown>(
  functionName: string,
  body?: unknown,
): Promise<InvokeEdgeFunctionResult<T>> {
  if (!supabaseUrl || !supabaseAnonKey) {
    console.error("Supabase env missing for Edge Function invoke.", {
      hasUrl: Boolean(supabaseUrl),
      hasAnonKey: Boolean(supabaseAnonKey),
      functionName,
    });
    return {
      data: null,
      status: null,
      error: t("commonSystemMisconfigured"),
    };
  }

  const { data: sessionData, error: sessionError } =
    await supabase.auth.getSession();
  if (sessionError) {
    console.error("Failed to get session for Edge Function invoke.", {
      functionName,
      sessionError,
    });
    return {
      data: null,
      status: null,
      error: t("commonRequestFailed"),
    };
  }

  const accessToken = sessionData.session?.access_token;
  if (!accessToken) {
    return {
      data: null,
      status: 401,
      error: t("authPleaseSignIn"),
    };
  }

  const url = `${supabaseUrl.replace(/\/+$/, "")}/functions/v1/${functionName}`;

  try {
    const res = await fetch(url, {
      method: "POST",
      headers: {
        apikey: supabaseAnonKey,
        Authorization: `Bearer ${supabaseAnonKey}`,
        "Content-Type": "application/json",
        "X-Authorization": `Bearer ${accessToken}`,
      },
      body: body === undefined ? undefined : JSON.stringify(body),
    });

    const text = await res.text();
    const parsed = safeJsonParse(text);

    if (!res.ok) {
      const details =
        parsed && typeof parsed === "object" && "error" in parsed
          ? String((parsed as { error?: unknown }).error ?? "")
          : typeof parsed === "string"
            ? parsed
            : text;

      console.error("Edge Function request failed.", {
        functionName,
        status: res.status,
        details,
      });

      return {
        data: null,
        status: res.status,
        error: t("commonRequestFailed"),
      };
    }

    return {
      data: (parsed as T) ?? null,
      status: res.status,
      error: null,
    };
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e ?? "");
    const lower = message.toLowerCase();
    if (lower.includes("failed to fetch") || lower.includes("fetch failed") || lower.includes("networkerror")) {
      return {
        data: null,
        status: null,
        error: t("commonNetworkError"),
      };
    }

    console.error("Edge Function request threw.", { functionName, error: e });
    return {
      data: null,
      status: null,
      error: t("commonUnknownError"),
    };
  }
}
