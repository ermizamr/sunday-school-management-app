-- Make assessment creation idempotent at the database level.
--
-- Bug found in UAT: the grade-entry screen creates a row in public.assessments
-- on every save tap (6 identical rows within 5 seconds), because the create
-- path is a plain insert with no busy-state guard. Scores then attach to each
-- duplicate, so the student view and analytics list the same exam repeatedly.
--
-- 1. Remove duplicates, keeping the earliest row per natural key
--    (assessment_scores cascade with the deleted copies; all duplicate copies
--    carried identical scores, so nothing is lost).
-- 2. Enforce the natural key so every future write must go through an upsert:
--    one assessment per (academic year, subject, grade type, date).

begin;

delete from public.assessments a
using public.assessments b
where a.academic_year_id = b.academic_year_id
  and a.subject_id = b.subject_id
  and a.grade_type = b.grade_type
  and a.assessment_date = b.assessment_date
  and (
    a.created_at > b.created_at
    or (a.created_at = b.created_at and a.id > b.id)
  );

create unique index if not exists assessments_natural_key_uidx
  on public.assessments (academic_year_id, subject_id, grade_type, assessment_date);

commit;
