# Admin Dashboard Guide

This document describes the **Admin Portal** web dashboard located in `admin-panel/`.

It covers:
- How to sign in and navigate
- What each page does (purpose, fields, actions, validation, permissions)
- Common workflows (academic year lifecycle, promotions, announcements)
- Best practices and warnings for sensitive actions
- A simplified data model (admin-relevant)
- Error handling and troubleshooting

---

## Table of contents

- [1. Overview](#1-overview)
- [2. Access & sign-in](#2-access--sign-in)
- [3. Navigation structure](#3-navigation-structure)
- [4. What to use for what](#4-what-to-use-for-what)
- [5. Dashboard (what it shows)](#5-dashboard-what-it-shows)
- [6. Page-by-page reference](#6-page-by-page-reference)
  - [6.1 Students](#61-students)
  - [6.2 Graduates](#62-graduates)
  - [6.3 Servants](#63-servants)
  - [6.4 Grades](#64-grades)
  - [6.5 Subjects](#65-subjects)
  - [6.6 Academic Year](#66-academic-year)
  - [6.7 Promotions](#67-promotions)
  - [6.8 Announcements](#68-announcements)
- [7. Workflows](#7-workflows)
  - [7.1 Set up a new system](#71-set-up-a-new-system)
  - [7.2 Onboard a new student](#72-onboard-a-new-student)
  - [7.3 Reset a student password](#73-reset-a-student-password)
  - [7.4 Activate / deactivate accounts](#74-activate--deactivate-accounts)
  - [7.5 Semester transitions](#75-semester-transitions)
  - [7.6 End-of-year promotion + start new year](#76-end-of-year-promotion--start-new-year)
  - [7.7 Archive an ended academic year (destructive)](#77-archive-an-ended-academic-year-destructive)
  - [7.8 Publish an announcement + push notification](#78-publish-an-announcement--push-notification)
- [8. Best practices](#8-best-practices)
- [9. Sensitive actions & warnings](#9-sensitive-actions--warnings)
- [10. Data model (admin-relevant)](#10-data-model-admin-relevant)
- [11. Error handling & troubleshooting](#11-error-handling--troubleshooting)
- [12. Developer notes (optional)](#12-developer-notes-optional)

---

## 1. Overview

The Admin Portal is used by administrators to manage the core operational data for the Sunday School system:
- Students and servant accounts
- Grades and subjects
- Academic year lifecycle (including semesters)
- Promotions (criteria + running promotions)
- Announcements (and push notifications)
- Graduates list (read-only)

**Permissions (high level):**
- All `/admin/*` pages are guarded so only users with `profiles.role = 'admin'` can access.
- Sensitive operations are also enforced server-side (RPC functions and Edge Functions).

---

## 2. Access & sign-in

### Where to sign in
- Navigate to the Admin Portal URL and you will be redirected to the sign-in page when not authenticated.
- The sign-in page route is `/sign-in`.

### Credentials
- Sign in uses **email + password**.
- If your account is not an admin account, you will be signed out and redirected back to `/sign-in`.

### After sign-in
- If you were redirected from another page, you’ll be sent back to that original page.
- Otherwise, the portal redirects to the **Academic Year** page by default.

### Sign out
- Use the **Sign Out** button in the sidebar.

---

## 3. Navigation structure

The sidebar navigation contains these pages (in order):
1. Dashboard
2. Students
3. Servants
4. Grades
5. Subjects
6. Academic Year
7. Promotions
8. Announcements
9. Graduates

---

## 4. What to use for what

Use this as a quick “where do I go?” map:

- **Create a new student** → Students
- **Change a student’s grade** → Students
- **Reset a password** → Students
- **Deactivate/activate a student or servant** → Students / Servants
- **Define grades (e.g., 1st–4th)** → Grades
- **Define subjects per grade** → Subjects
- **Set subject prerequisites** → Subjects
- **Start a new academic year** → Academic Year
- **End Semester 1 / start Semester 2** → Academic Year
- **End an academic year** → Academic Year
- **Configure promotion criteria** → Promotions
- **Run promotions (all grades)** → Promotions
- **Create announcements (and push notifications)** → Announcements
- **View graduated students** → Graduates

---

## 5. Dashboard (what it shows)

**Purpose:** Quick operational snapshot.

**Shows:**
- Total number of students (profiles with role `student`)
- Total number of servants (profiles with role `servant`)
- Total number of announcements
- The currently active academic year name (or a “no active year” message)

**Actions:** None (read-only).

---

## 6. Page-by-page reference

### 6.1 Students

**Purpose**
- Create new student accounts
- Maintain student grade assignments
- Reset student passwords
- Activate/deactivate student accounts

**Data shown**
- Table of student profiles (`profiles.role = 'student'`)
- Status filter: `All / Active / Inactive`
- Search: matches **name**, **academic ID**, or internal **user id**

**Create student: fields**
- **Academic ID (optional)**
  - If provided, must match format `xxxx/xx` (example: `0001/17`).
  - If left empty, the system auto-assigns the next available ID for the current Ethiopian year (example: `0001/yy`, `0002/yy`, …).
- **Name (required)**
- **Password (optional)**
  - If omitted, the password defaults to the student’s academic ID.
  - If the academic ID is auto-assigned, the password defaults to the assigned academic ID.
- **Email (optional)**
  - If omitted, the backend creates a placeholder email internally.
- **Grade (required)**

**Create student: actions**
- **Create**
  - On success, if the academic ID was auto-assigned, the portal shows an alert with the assigned ID.

**Edit student: fields/actions**
- **Grade dropdown** (per student)
  - Change the grade value then click **Save**.
  - Note: although the UI allows a blank grade, leaving a student without a grade can break grade-scoped workflows.

**Reset password**
- Click **Reset Password**
- Enter a new password in the prompt
- The password is changed immediately

**Activate / deactivate**
- Click **Deactivate** to set account status to `inactive_pending_admin`.
- Click **Activate** to set account status to `active`.
- Confirmation is required.
- Graduated students (status `graduated`) are treated as read-only for status changes.

**Validation & constraints**
- Create requires: `name` and `grade`.
- Academic ID (if provided) must be `xxxx/xx`.
- Backend also validates that the chosen grade exists.

**Permissions**
- Admin-only UI.
- Backend enforcement:
  - `admin-create-user`: requires **servant or admin** (portal uses it as admin), validates grade, ensures academic ID uniqueness.
  - `admin-reset-password`: admin-only.
  - `admin-set-account-status`: admin-only.

---

### 6.2 Graduates

**Purpose**
- Read-only list of students who have been marked as graduated.

**Data shown**
- Students with `profiles.role = 'student'` and `account_status = 'graduated'`.
- Search by name, academic ID, or internal user id.

**Actions**
- None (read-only).

**Permissions**
- Admin-only UI.

---

### 6.3 Servants

**Purpose**
- View servant accounts
- Activate/deactivate servant accounts

**Data shown**
- Table of servant profiles (`profiles.role = 'servant'`)
- Displays: name, academic ID, grade (if set), and status

**Actions**
- **Deactivate / Activate**
  - Sets `account_status` to `inactive_pending_admin` or `active`
  - Confirmation is required

**Validation & constraints**
- No form fields; action is a status toggle.

**Permissions**
- Admin-only UI.
- Backend enforcement: uses `admin-set-account-status` (admin-only).

---

### 6.4 Grades

**Purpose**
- Define and maintain the list of grades used throughout the system.

**Create grade: fields**
- **Name** (required by the UI)
- **Code** (strongly recommended)
- **Sort order** (strongly recommended)

**Important database constraints**
- In the current schema, `code` and `sort_order` are required and must be unique.
- The UI does not strictly enforce these as required inputs, but the database will reject inserts/updates that violate constraints.

**Actions**
- **Create** a new grade
- **Save** changes for an existing grade (inline editing)

**Validation & constraints**
- Ensure:
  - `code` is filled (example: `1st`, `2nd`, `3rd`, `4th`)
  - `sort_order` is filled and unique (used to order grades and determine “next grade” in promotions)

**Permissions**
- Admin-only UI.

---

### 6.5 Subjects

**Purpose**
- Create and manage subjects
- Assign each subject to a grade
- Maintain passing grade + weight
- Configure **one prerequisite** subject per subject (via the portal UI)

**Data shown**
- All subjects (`subjects` table)
- Optional filter by grade
- For each subject: grade, prerequisite, prerequisite minimum score, passing grade, weight

**Create subject: fields**
- **Name** (required)
- **Grade** (should be selected; the database expects `grade_id`)
- **Passing grade** (required)
- **Weight** (optional)
- **“Is prerequisite” checkbox**
  - This is informational in the current UI (it does not automatically create prerequisite links).

**Edit subject (inline)**
- Update name, grade, passing grade, weight
- Update prerequisite selection and minimum score

**Prerequisites behavior (important)**
- The portal allows selecting a prerequisite only from subjects in the **same grade**.
- When you click **Save**, the portal:
  - Deletes existing prerequisite rows for that subject
  - Inserts the selected prerequisite (if any)
- This means the UI effectively supports **at most one prerequisite per subject** (even though the database can store multiple).

**Delete subject**
- Confirmation is required.
- Deletion can be blocked if the subject is referenced by other records (foreign key constraints), such as assessments, attendance sessions, promotion criteria, or prerequisite relationships.

**Validation & constraints**
- Passing grade must be a valid number.
- Grade should not be left blank.

**Permissions**
- Admin-only UI.

---

### 6.6 Academic Year

**Purpose**
- Manage the academic year lifecycle and semester transitions.

**What you can do**
- View current active academic year
- End Semester 1 (sets `semester1_end_date`)
- Start Semester 2 (sets `semester2_start_date`)
- Set the current period (`semester1`, `semester2`, `break`)
- End the active academic year
- Start a new academic year
- Archive ended academic years (destructive)

**Current status section**
- **Active year name** (or “None”)
- **Semester 1 end date** + **End Semester 1** button
- **Semester 2 start date** + **Start Semester 2** button
- **Current period** dropdown + **Update Period** button
- **End Active Year** button

**Semester transition validation (backend-enforced)**
- You must end Semester 1 before starting Semester 2.
- Semester 2 start date cannot be before Semester 1 end date.

**Start new academic year (RPC: `start_new_academic_year`)**
- Fields:
  - Name (required)
  - Start date (required)
  - End date (required)

**Critical rule: end-year + promotions required before starting a new year**
- You must **end the active year first** (Academic Years → End Active Year).
- Then you must **run promotions for every grade** for the most recently ended academic year (Promotions page).
- If any grade is missing a promotion run for that ended year, starting a new academic year will fail.

**What “Start new academic year” does (important)**
- Requires: no academic year with status `active`.
- Creates the new year as `active` with current period = `semester1`.
- Uses the most recently `ended` year (if any) and applies the latest promotion run per grade to student records:
  - `eligible` + next grade exists → student is moved to next grade and set `active`
  - `eligible` + no next grade → student is marked `graduated`
  - otherwise → student becomes `inactive_pending_admin` (admin must review/activate)

**End active year (RPC: `end_academic_year`)**
- Sets academic year status to `ended` and current period to `break`.
- Does not delete operational data.

**Archive an ended year (RPC: `archive_academic_year`)**
- Only enabled in the UI for years with status `ended`.
- Copies year-scoped data into archive tables and then deletes it from live tables.
- Marks the year as `archived`.

**Permissions**
- Admin-only UI.
- Backend enforcement: all academic-year RPC actions are admin-only.

---

### 6.7 Promotions

**Purpose**
- Configure promotion criteria per grade
- Run promotions for all grades and get a summary

**Key concept**
- Promotions are required before starting a new academic year when a previous year exists.

#### Promotion criteria

**Scope**
- The portal targets the **active** academic year automatically.
- Criteria are edited per grade via the grade dropdown.

**Fields**
- **Minimum overall average** (numeric; default 70)
- For each subject in the grade:
  - **Minimum grade** (required)
  - **Minimum present days** (required)

**Subjects fallback warning**
- If no subjects are assigned to the selected grade, the UI may fall back to showing subjects from other grades and display a warning.
- Best practice: ensure each grade has its own subjects configured.

**Save Criteria action**
- Saves/upserts:
  - `promotion_criteria_sets` (per academic year + grade)
  - `promotion_criteria_subjects` (per subject rules)

**Validation**
- You cannot save criteria if:
  - A grade is not selected
  - There are no subjects
  - Any subject is missing minimum grade or minimum present days

#### Run promotions

**Run action**
- Button: **Run Promotion**
- Calls the admin-only RPC: `run_promotion_for_all_grades_with_summary(p_academic_year_id, p_notes)`

**Notes field**
- Free-text notes are saved along with the run.
- The portal also includes a small JSON config in notes for traceability.

**Result summary**
- Displays totals across all grades:
  - total students, eligible, at risk, not eligible, graduated
- Displays per-grade results including the `run_id`.

**Permissions**
- Admin-only UI.
- Backend enforcement: promotion RPCs are admin-only.

---

### 6.8 Announcements

**Purpose**
- Create announcements
- Optionally send push notifications when an announcement is created
- Delete announcements

**Create announcement: fields**
- **Title** (required)
- **Message** (required)
- **Grade (optional)**
  - Global announcement (all grades)
  - Or grade-scoped announcement (one grade)
- **Category** (dropdown: general / grades / schedule / event / urgent)
- **Priority** (free text; default `medium`)
- **Expires on** (optional)
  - If the date is not parseable, it is treated as empty.
- **Academic year** (select)
  - Defaults to the active year
  - Can be set to another year or left blank
- **Active** (checkbox)

**Create action**
1. Inserts the announcement into the database.
2. Attempts to send a push notification via the `push-notify` Edge Function.

**Push notifications are best-effort**
- If push sending fails (or if there are no recipients/tokens), the portal shows a notice.
- The announcement is still saved even when push fails.

**Delete action**
- Deletes the announcement row after confirmation.

**Permissions**
- Admin-only UI.

---

## 7. Workflows

### 7.1 Set up a new system

Recommended order:
1. **Grades**: confirm grade names, codes, and sort order are correct.
2. **Subjects**: create subjects for each grade.
3. **Subjects**: set prerequisites if needed.
4. **Academic Year**: start a new academic year.
5. **Promotions**: configure criteria for every grade (do this early so you’re ready at year-end).

---

### 7.2 Onboard a new student

1. Go to **Students**.
2. Fill **Name** and select a **Grade**.
3. Optional:
   - Academic ID: set it if you have an official ID; otherwise leave it blank to auto-assign.
   - Password: leave blank to default to academic ID.
   - Email: optional.
4. Click **Create**.
5. If an academic ID was auto-assigned, record it from the alert.

---

### 7.3 Reset a student password

1. Go to **Students**.
2. Find the student.
3. Click **Reset Password**.
4. Enter the new password in the prompt.
5. Communicate the new password securely.

---

### 7.4 Activate / deactivate accounts

**Students**
- Students → click **Deactivate** or **Activate**.

**Servants**
- Servants → click **Deactivate** or **Activate**.

Notes:
- Deactivated accounts are marked `inactive_pending_admin`.
- Graduated accounts are treated as read-only in the Students list.

---

### 7.5 Semester transitions

**End Semester 1**
1. Academic Year → set **Semester 1 end date**.
2. Click **End Semester 1**.

**Start Semester 2**
1. Academic Year → set **Semester 2 start date**.
2. Click **Start Semester 2**.

Constraints:
- Semester 2 cannot start until Semester 1 is ended.
- Semester 2 start date cannot be before Semester 1 end date.

---

### 7.6 End-of-year promotion + start new year

1. **Promotions** → ensure criteria are saved for every grade.
2. **Promotions** → click **Run Promotion**.
3. Review the summary.
4. **Academic Year** → start the new academic year.
   - If promotions are missing for any grade in the previous active year, the start will fail and list the missing grades.

What happens automatically when you start a new year:
- Previous year is ended.
- Students are moved/updated based on the most recent promotion result.

---

### 7.7 Archive an ended academic year (destructive)

1. Academic Year → find a year with status **Ended**.
2. Click **Archive**.
3. Confirm.

Warning:
- This is destructive: operational data for that year is copied to archive tables and removed from live tables.

---

### 7.8 Publish an announcement + push notification

1. Announcements → fill in title and message.
2. Optional:
   - Choose a grade to target a specific grade
   - Choose category, priority, expiry, academic year
3. Click **Create**.
4. If a notice appears about push delivery, it means the announcement is saved but push did not send (or sent to 0 recipients).

---

## 8. Best practices

- **Treat grade `code` and `sort_order` as required** and keep them unique.
- **Always assign a grade to each subject**; promotion criteria depends on subjects being grade-correct.
- **Set promotion criteria early** (not only at year end) to reduce mistakes.
- **Before starting a new year, run promotions for all grades** and confirm the summary.
- **Be careful with deactivation**: inactive users are blocked by access policies.
- **Use grade-scoped announcements** when the message is not relevant to all grades.
- **Avoid deleting subjects** unless you’re sure they are not referenced; remove dependencies first.
- **Archive only when you are sure** you no longer need live access to that year’s operational data.

---

## 9. Sensitive actions & warnings

- **Archive Academic Year**: destructive; deletes live data for that year after archiving.
- **Start New Academic Year**: ends the previous year and updates many student records (grade + account status).
- **Run Promotions**: creates promotion runs/results and can mark students as graduated.
- **Reset Password**: immediately changes a user’s ability to sign in.
- **Deactivate Account**: blocks user access via RLS/access checks.
- **Delete Subject**: can be blocked; removing a subject can disrupt grading/attendance history.

---

## 10. Data model (admin-relevant)

This is a simplified view of the core tables used by the Admin Portal.

### Core identity
- `profiles`
  - One row per user (ties to `auth.users`).
  - Key fields: `id`, `role (admin/student/servant)`, `academic_id`, `name`, `grade_id`, `account_status (active/inactive_pending_admin/graduated)`.

### Structure
- `grades`
  - Key fields: `id`, `name`, `code`, `sort_order`.
- `subjects`
  - Key fields: `id`, `grade_id`, `name`, `passing_grade`, `weight`, `active`.
- `subject_prerequisites`
  - Links subjects to prerequisite subjects.
  - Key fields: `subject_id`, `prerequisite_subject_id`, `minimum_score`.

### Academic lifecycle
- `academic_years`
  - Key fields: `id`, `name`, `start_date`, `end_date`, `status (active/ended/archived)`, `current_period (semester1/semester2/break)`, `semester1_end_date`, `semester2_start_date`, `ended_at`, `archived_at`.

### Announcements
- `announcements`
  - Key fields: `id`, `academic_year_id (optional)`, `grade_id (optional)`, `title`, `message`, `category`, `priority`, `active`, `expires_on`, `created_by`.

### Promotions
- `promotion_criteria_sets`
  - One criteria set per `(academic_year_id, grade_id)`.
  - Key fields: thresholds including `minimum_overall_average`, `minimum_subject_grade`, `minimum_attendance`, plus band/category ranges.
- `promotion_criteria_subjects`
  - Per-subject rules for a criteria set.
  - Key fields: `subject_id`, `minimum_grade`, `minimum_attendance_days`, `required`, `weight`.
- `promotion_runs`
  - One row per promotion execution per grade.
  - Key fields: `academic_year_id`, `grade_id`, `run_by`, `run_at`, `notes`.
- `promotion_results`
  - Per-student promotion result for a run.
  - Key fields: `run_id`, `student_id`, `status (eligible/at_risk/not_eligible)`, `recommended_next_grade_id`, `overall_average`, `attendance_percent`, `details`.

### Archive tables
- `archive_*` tables are used by `archive_academic_year`.
- They store historical year-scoped data after archiving so live tables can be cleaned.

---

## 11. Error handling & troubleshooting

### How errors show up
- Most pages render an **ErrorBanner** when a request fails.
- The UI “humanizes” a few common errors:
  - Network fetch failures → “Network error”
  - Invalid login credentials → friendly auth error
  - Email not confirmed → friendly auth error

### Common issues

**“Access denied / not admin”**
- Cause: your `profiles.role` is not `admin`.
- Result: you are signed out and redirected to `/sign-in`.

**Network errors / failed to fetch**
- Cause: connectivity issues, wrong Supabase URL, blocked requests.
- Action: check internet, Supabase project URL, and whether the Edge Functions endpoint is reachable.

**Grades/Subjects create/save fails**
- Cause: database constraints (required fields / uniqueness) even if UI inputs look optional.
- Action:
  - Grades: fill `code` and `sort_order`, ensure uniqueness.
  - Subjects: select a grade and ensure passing grade is numeric.

**Subject delete blocked**
- Cause: foreign key references.
- Action: remove dependent records first (assessments, attendance, criteria, prerequisites, etc.).

**Announcement push notice**
- Cause: push notifications are best-effort; there may be no recipients, no device tokens, or FCM isn’t configured.
- Action: treat the announcement as saved; investigate push configuration separately.

---

## 12. Developer notes (optional)

### Edge Function auth headers

This project uses a gateway-safe pattern when calling Supabase Edge Functions:
- `apikey: <SUPABASE_ANON_KEY>`
- `Authorization: Bearer <SUPABASE_ANON_KEY>`
- `X-Authorization: Bearer <USER_JWT_ACCESS_TOKEN>`

Edge Functions are implemented to read `X-Authorization` first.

### Admin portal required env vars
- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`

### Push notifications (server-side)
- The `push-notify` Edge Function requires Firebase/FCM secrets (either legacy server key or service account JSON) and Supabase service role key on the server.
