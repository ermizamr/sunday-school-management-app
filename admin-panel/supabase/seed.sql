-- Seed data for local/dev environments.
-- Creates sample subjects (if missing) and mock attendance sessions/records.
-- Safe to run multiple times.

begin;
-- Seed subjects for each grade if missing
do $$
declare
  v_grade record;
  v_subjects text[] := array['Bible', 'Hymnology', 'Church History'];
  v_subject_name text;
  v_subject_exists int;
begin
  for v_grade in select id from public.grades loop
    foreach v_subject_name in array v_subjects loop
      select count(*) into v_subject_exists from public.subjects
        where grade_id = v_grade.id and name = v_subject_name;
      if v_subject_exists = 0 then
        insert into public.subjects (grade_id, name, active)
        values (v_grade.id, v_subject_name, true);
      end if;
    end loop;
  end loop;
end $$;

do $$
declare
  v_academic_year_id uuid;
  v_creator_id uuid;
  v_grade record;
  v_subject record;
  v_date date;
  v_day int;
  v_session_id uuid;
  v_days int[] := array[7, 14, 21, 28];
begin
  -- Ensure an active academic year exists.
  select id
    into v_academic_year_id
  from public.academic_years
  where status = 'active'
  order by created_at desc
  limit 1;

  if v_academic_year_id is null then
    insert into public.academic_years (name, start_date, end_date, status, current_period)
    values (
      'DEV ' || to_char(current_date, 'YYYY') || '-' || to_char(current_date + interval '1 year', 'YYYY'),
      current_date - interval '30 days',
      current_date + interval '300 days',
      'active',
      'semester1'
    )
    returning id into v_academic_year_id;
  end if;

  -- Removed mock subject seeding. Subjects must exist in DB.

  -- Create mock attendance sessions + records.
  for v_grade in (select id from public.grades) loop
    -- Creator: prefer a servant for this grade; fallback to any admin.
    select id
      into v_creator_id
    from public.profiles
    where role = 'servant'
      and grade_id = v_grade.id
    order by created_at asc
    limit 1;

    if v_creator_id is null then
      select id
        into v_creator_id
      from public.profiles
      where role = 'admin'
      order by created_at asc
      limit 1;
    end if;

    -- If no servant/admin exists, we can't create attendance sessions (FK created_by).
    if v_creator_id is null then
      continue;
    end if;

    for v_subject in (
      select id
      from public.subjects
      where grade_id = v_grade.id
        and active = true
    ) loop
      foreach v_day in array v_days loop
        v_date := (current_date - make_interval(days => v_day))::date;
        -- Insert session (idempotent).
        insert into public.attendance_sessions (
          academic_year_id,
          grade_id,
          subject_id,
          session_date,
          created_by
        )
        values (
          v_academic_year_id,
          v_grade.id,
          v_subject.id,
          v_date,
          v_creator_id
        )
        on conflict (academic_year_id, subject_id, session_date)
        do update set updated_at = now()
        returning id into v_session_id;

        if v_session_id is null then
          select id
            into v_session_id
          from public.attendance_sessions
          where academic_year_id = v_academic_year_id
            and subject_id = v_subject.id
            and session_date = v_date;
        end if;

        if v_session_id is null then
          continue;
        end if;

        -- Insert records for students in this grade (idempotent).
        insert into public.attendance_records (
          session_id,
          student_id,
          status,
          updated_by,
          updated_at
        )
        select
          v_session_id,
          p.id,
          (
            case (abs(hashtext(p.id::text || v_session_id::text)) % 10)
              when 0 then 'absent'
              when 1 then 'late'
              when 2 then 'permission'
              else 'present'
            end
          )::public.attendance_status,
          v_creator_id,
          now()
        from public.profiles p
        where p.role = 'student'
          and p.grade_id = v_grade.id
        on conflict (session_id, student_id) do nothing;
      end loop;
    end loop;
  end loop;
end $$;

commit;
