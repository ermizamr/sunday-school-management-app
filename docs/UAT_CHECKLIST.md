# UAT Checklist — ተከታታይ ትምህርት ዘእግዚአብሔር ምስሌነ

**Goal:** walk every critical flow with real accounts before teachers and
students depend on the system. Tick each box, note issues in the Notes column,
and sign off at the bottom.

**Environment**

| Item | Value |
|---|---|
| App APK | `sunday-school-0.9.0-b6-release.apk` (install over previous builds) |
| Supabase project | `Egziaabher-mislene-erp` — `https://eucvcyqrgdlkrhoekqtq.supabase.co` |
| Admin panel | `https://admin-panel-lake-nu.vercel.app` ⚠️ **only after the Vercel env vars are updated** (see §0) |
| Seed script | `supabase/seed_uat.sql` — already applied; re-running resets the passwords below |

---

## 0. Prerequisites (do before testing)

- [ ] **Vercel env fix:** in the Vercel project set `VITE_SUPABASE_URL` =
      `https://eucvcyqrgdlkrhoekqtq.supabase.co` and `VITE_SUPABASE_ANON_KEY` to
      the new project's anon key, then redeploy. *Until this is done the live
      admin panel talks to the deleted project and shows errors.*
- [ ] Install the APK on **one Android device** (and one iPhone if available).
- [ ] Confirm the Supabase project is on a **paid plan or has backups** —
      free-tier projects pause after ~7 days of inactivity.

---

## 1. Launch & identity (any device, no login)

| # | Check | Expected | ✓ |
|---|------|----------|---|
| 1.1 | Cold-start the app | Animated splash: logo + two lines **ተከታታይ ትምህርት** / **ዘእግዚአብሔር ምስሌነ**, no black screen | ☐ |
| 1.2 | Home-screen icon | New adaptive icon, fully visible, two-line label under it (some launchers truncate to one line — acceptable) | ☐ |
| 1.3 | App language | Starts in Amharic; switch to English in settings and back | ☐ |
| 1.4 | Kill app during startup, relaunch | Splash still shows, then routes to role selection; no crash | ☐ |

---

## 2. Test accounts (seeded — passwords re-applied by every seed re-run)

| Role | Email | Password | Grade | Notes |
|------|-------|----------|-------|-------|
| Admin | `admin@sunday-school.local` | `Xvrp6QHq06r1l9Vwom` | — | password-reset emails **won't** deliver (`.local` domain) — reset manually if lost |
| Servant | `0001-18@school.local` | `Servant123!` | 1st | Ethiopian name: ኤርምያስ ምስክር |
| Servant | `0002-18@school.local` | `Servant123!` | 2nd | ሳሙኤል ተስፋዬ |
| Student | `0001-19@school.local` | `0001/19` | 1st | high performer (90%) — promotion **eligible** |
| Student | `0002-19@school.local` | `0002/19` | 1st | low average (63%) — promotion **not_eligible** |
| Student | `0003-19@school.local` | `0003/19` | 2nd | good marks, 50% attendance — promotion **at_risk** |

Pre-seeded data: academic year **2026-2027** (active, semester2), 4 subjects ×
4 grades, 32 assessments with 48 scores, 32 attendance sessions with 48 records
(4 Sundays), 2 announcements, 1 open question, 1 pending complaint, promotion
criteria (70 / 60 / 75) for every grade.

- [ ] Log in as **student** `0002-19@school.local` / `0002/19` → lands on student home
- [ ] Log in as **servant** `0001-18@school.local` / `Servant123!` → lands on servant home
- [ ] Log in as **admin** (above) → admin panel opens
- [ ] Wrong password → clear error, no crash
- [ ] Logout → returns to role selection; login again works

---

## 3. Admin flows (admin panel or app, as admin)

| # | Check | Expected | ✓ |
|---|------|----------|---|
| 3.1 | Create a servant (grade 3rd) | Account created; auto email + password shown; servant can log in | ☐ |
| 3.2 | Create a student (auto academic ID) | ID like `0004/26`; password = academic ID; student can log in | ☐ |
| 3.3 | Reset a student's password | New password works, old one stops working | ☐ |
| 3.4 | Deactivate an account → login attempt | Blocked with "account inactive" style message | ☐ |
| 3.5 | Re-activate the account | Login works again | ☐ |
| 3.6 | Post a global announcement | Visible to servants **and** students of all grades | ☐ |
| 3.7 | Answer a student question (the seeded one) | Student sees the answer; item marked answered | ☐ |
| 3.8 | Respond to the seeded complaint | Status moves pending → in review → resolved; student sees response | ☐ |
| 3.9 | View reports/analytics | Numbers match seeded data (see averages below) | ☐ |
| 3.10 | Promotion **preview** (§7) | Shows 3 expected outcomes | ☐ |

---

## 4. Servant flows (app, as servant)

| # | Check | Expected | ✓ |
|---|------|----------|---|
| 4.1 | Register a new student | Gets academic ID + password; appears in grade list | ☐ |
| 4.2 | Take attendance for today (grade 1st) | All students listed; mark present/late/absent/permission; saves | ☐ |
| 4.3 | Re-open the same session | Previous marks are retained (no duplicates) | ☐ |
| 4.4 | Enter grades (quiz/exam) | Saved; student sees the score immediately | ☐ |
| 4.5 | Edit a saved score | New value wins everywhere (student view, analytics) | ☐ |
| 4.6 | Post a grade-only announcement (grade 1st) | Only grade-1st students/servants see it; grade 2nd does not | ☐ |
| 4.7 | View grade analytics | 0001/19 ≈ 90 %, 0002/19 ≈ 63 %, 0003/19 ≈ 84 % | ☐ |
| 4.8 | Servant of grade 2nd opens grade 1st data | **Blocked / empty** — servants only see their own grade | ☐ |
| 4.9 | Try admin-only action (create/delete user) as servant | Denied (button absent or server rejects) | ☐ |

---

## 5. Student flows (app, as student)

| # | Check | Expected | ✓ |
|---|------|----------|---|
| 5.1 | Home shows my grades | Quiz/Exam scores match what the servant entered | ☐ |
| 5.2 | Attendance history | Seeded sessions visible; percentages: 0001/19 = 100 %, 0002/19 = 75 %, 0003/19 = 50 % | ☐ |
| 5.3 | Ask a question (pick subject) | Reaches the servant; shows as unanswered until replied | ☐ |
| 5.4 | Submit a complaint (category *course*) | Created with status *pending*; visible to admin | ☐ |
| 5.5 | Read announcements | Seeded global + grade-specific announcements render with correct category badges | ☐ |
| 5.6 | Student of grade 2nd sees grade-1st-only content | **Not visible** (announcement, questions, grades) | ☐ |
| 5.7 | Two students' data cross-check | 0001/19 can never see 0002/19's scores (RLS) | ☐ |

---

## 6. Notifications (needs a real device with the app installed)

| # | Check | Expected | ✓ |
|---|------|----------|---|
| 6.1 | First launch → permission prompt | "Allow notifications" dialog appears | ☐ |
| 6.2 | Allow permission | Device registers a push token (`device_push_tokens` gains a row) | ☐ |
| 6.3 | Admin posts an announcement | Push arrives on the device even when app is closed | ☐ |
| 6.4 | Tap the notification | Opens the app at the announcement/composition | ☐ |
| 6.5 | Decline permission on 2nd device | App still works; no crash; no token for that device | ☐ |

> The FCM service-account secret is set on the project and the credential chain
> was verified (real Google OAuth token exchange). Step 6.3 is the remaining
> end-to-end proof and needs a physical device.

---

## 7. Promotion (admin, at the end of UAT)

- [ ] Open promotion **preview** for grade 1st → exactly:
  - `0001/19` → **eligible** (90 % avg, 100 % attendance)
  - `0002/19` → **not_eligible** (63 % < 70 minimum)
- [ ] Preview for grade 2nd → `0003/19` → **at_risk** (attendance 50 % < 75)
- [ ] Run promotion for grade 1st → results stored, re-run is blocked or
      updates (single-run guard), students' status/grade updates as designed
- [ ] Grade 3rd / 4th (no students, no assessments) → empty states, no errors

---

## 8. Admin panel on Vercel (after §0 env fix)

| # | Check | Expected | ✓ |
|---|------|----------|---|
| 8.1 | Open the URL | Login page, no console errors about failed fetch | ☐ |
| 8.2 | Admin login | Dashboard loads with real data (grades, students) | ☐ |
| 8.3 | Create user from panel | Same result as §3.1 | ☐ |
| 8.4 | HTTPS / padlock | Valid certificate (automatic on Vercel) | ☐ |
| 8.5 | Phone browser (Android + iPhone) | Usable layout, not broken | ☐ |

---

## 9. Security spot-checks (negative tests)

| # | Check | Expected | ✓ |
|---|------|----------|---|
| 9.1 | Call `admin-create-user` edge function with **no auth header** | Rejected (401) | ☐ |
| 9.2 | Call it with a **student's** JWT | Rejected (403 — not admin) | ☐ |
| 9.3 | Call it with a **servant's** JWT | Rejected (403) | ☐ |
| 9.4 | Student edits `profiles.role` to `admin` via API | Rejected by RLS | ☐ |
| 9.5 | Student reads another student's `assessment_scores` | Empty result (RLS) | ☐ |

> 9.1–9.3 can be done with `curl` (copy a token from the app's stored session,
> or ask for a Postman-style snippet). If any of these pass, stop UAT — that is
> a blocker.

---

## 10. Reliability

| # | Check | Expected | ✓ |
|---|------|----------|---|
| 10.1 | Airplane mode → open app | Friendly offline/error state, no endless spinner | ☐ |
| 10.2 | Kill app mid-save (attendance/grades) | Data either saved or cleanly retryable; no partial corruption | ☐ |
| 10.3 | Background the app 10+ min, return | Session still valid or clean re-login | ☐ |
| 10.4 | Force a crash (dev build only, if available) | Crash appears in Firebase Crashlytics console within ~5 min | ☐ |

---

## Sign-off

| Role | Name | Date | Result (pass / fail / pass with issues) | Signature |
|------|------|------|------------------------------------------|-----------|
| Admin (you) |  |  |  |  |
| Servant tester |  |  |  |  |
| Student tester |  |  |  |  |

**Known issues at UAT start** (do not report as new bugs):

1. Admin panel URL is still the default `*.vercel.app` slug (custom domain pending).
2. Password-reset emails to `@school.local` / `@sunday-school.local` never arrive — resets are manual.
3. Crashlytics native symbol upload deferred (Dart errors are reported; native frames unsymbolicated).
4. Some launchers show only one line of the two-line app name under the icon.

**Blocking issues found:** _(list here — anything in §9 failing is automatically blocking)_
