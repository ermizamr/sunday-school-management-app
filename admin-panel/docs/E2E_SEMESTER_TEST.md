# Semester Flow E2E Test

This test validates the new semester workflow end-to-end against your linked Supabase project.

## What it validates

1. Admin can authenticate.
2. Active academic year is discoverable.
3. (Apply mode) `end_first_semester` works.
4. (Apply mode) `start_second_semester` works.
5. Academic year fields are persisted (`current_period`, `semester1_end_date`, `semester2_start_date`).
6. Student can authenticate.
7. Student RPCs return valid payloads:
   - `get_my_semester_report(semester1)`
   - `get_my_semester_report(semester2)`
   - `get_my_academic_assessment`

## Setup

1. Copy `.env.e2e.example` to `.env.e2e`
2. Fill all values.
3. In PowerShell:

```powershell
Get-Content .env.e2e | ForEach-Object {
  if ($_ -match '^(?<k>[^#=][^=]*)=(?<v>.*)$') {
    [Environment]::SetEnvironmentVariable($matches.k, $matches.v)
  }
}
```

## Run

### Dry run (no writes)

```powershell
npm run test:e2e:semester
```

### Apply mode (performs semester transition writes)

```powershell
npm run test:e2e:semester -- --apply
```

## Notes

- Use dedicated test admin/student accounts.
- Apply mode updates active academic year period and semester boundary dates.
- If your active year is already in semester2, apply mode still validates transition RPC behavior by writing current computed dates.
