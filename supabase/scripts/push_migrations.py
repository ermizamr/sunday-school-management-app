#!/usr/bin/env python3
"""Apply supabase/migrations/*.sql to the linked hosted project via the
Management API SQL endpoint, and record them in supabase_migrations.schema_migrations
so a future `supabase db push` sees them as applied.

Usage: SUPABASE_ACCESS_TOKEN=... python3 push_migrations.py [--dry-run] [--only PREFIX]
"""
import json
import os
import pathlib
import re
import sys
import time
import urllib.error
import urllib.request

TOKEN = os.environ["SUPABASE_ACCESS_TOKEN"]
REF = os.environ.get("SUPABASE_PROJECT_REF", "eucvcyqrgdlkrhoekqtq")
URL = f"https://api.supabase.com/v1/projects/{REF}/database/query"
MIG_DIR = pathlib.Path(__file__).resolve().parent.parent / "migrations"
NAME_RE = re.compile(r"^([0-9]+)_(.*)\.sql$")

BOOTSTRAP = """
CREATE SCHEMA IF NOT EXISTS supabase_migrations;
CREATE TABLE IF NOT EXISTS supabase_migrations.schema_migrations (version text NOT NULL PRIMARY KEY);
ALTER TABLE supabase_migrations.schema_migrations ADD COLUMN IF NOT EXISTS statements text[];
ALTER TABLE supabase_migrations.schema_migrations ADD COLUMN IF NOT EXISTS name text;
"""


def query(sql: str, label: str, attempts: int = 4) -> list:
    body = json.dumps({"query": sql}).encode()
    last_err: Exception | None = None
    for attempt in range(1, attempts + 1):
        req = urllib.request.Request(
            URL,
            data=body,
            headers={
                "Authorization": f"Bearer {TOKEN}",
                "Content-Type": "application/json",
            },
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=180) as resp:
                payload = json.loads(resp.read().decode())
            break
        except urllib.error.HTTPError as e:
            detail = e.read().decode()[:2000]
            raise SystemExit(f"HTTP {e.code} during [{label}]: {detail}")
        except (urllib.error.URLError, TimeoutError, OSError) as e:
            last_err = e
            if attempt < attempts:
                time.sleep(3 * attempt)
                continue
            raise SystemExit(f"network failure during [{label}] after {attempts} tries: {e}")
    else:
        raise SystemExit(f"unreachable: {last_err}")
    if isinstance(payload, dict) and payload.get("message"):
        raise SystemExit(f"Error during [{label}]: {json.dumps(payload)[:2000]}")
    return payload


def sql_literal(s: str) -> str:
    return "'" + s.replace("'", "''") + "'"


def main() -> None:
    dry = "--dry-run" in sys.argv
    only = None
    if "--only" in sys.argv:
        only = sys.argv[sys.argv.index("--only") + 1]

    files = sorted(p for p in MIG_DIR.glob("*.sql") if NAME_RE.match(p.name))
    if only:
        files = [p for p in files if p.name.startswith(only)]
    print(f"{len(files)} migration file(s) selected")

    if not dry:
        query(BOOTSTRAP, "bootstrap history table")
        applied = {
            row["version"] for row in query(
                "SELECT version FROM supabase_migrations.schema_migrations", "list history"
            )
        }
    else:
        applied = set()

    for path in files:
        m = NAME_RE.match(path.name)
        version, name = m.group(1), m.group(2)
        sql = path.read_text(encoding="utf-8")
        if version in applied:
            print(f"= {path.name} (already recorded, skipped)")
            continue
        if dry:
            print(f"? {path.name} ({len(sql)} bytes)")
            continue
        print(f"> {path.name} ... ", end="", flush=True)
        query(sql, path.name)
        stmt = (
            "INSERT INTO supabase_migrations.schema_migrations(version, name, statements) "
            "VALUES (%s, %s, ARRAY[%s]::text[]) "
            "ON CONFLICT (version) DO UPDATE SET name = EXCLUDED.name, "
            "statements = EXCLUDED.statements"
            % (sql_literal(version), sql_literal(name), sql_literal(sql))
        )
        query(stmt, f"history:{path.name}")
        print("ok")

    if not dry:
        count = query(
            "SELECT count(*) AS n FROM supabase_migrations.schema_migrations", "count"
        )[0]["n"]
        print(f"done — {count} migration(s) recorded in history")


if __name__ == "__main__":
    main()
