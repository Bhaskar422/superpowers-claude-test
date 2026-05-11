-- Smoke test: every expected table exists.
DO $$
DECLARE
  expected text[] := ARRAY[
    'users',
    'scenarios',
    'sessions',
    'transcript_turns',
    'feedback_reports',
    'feedback_items',
    'user_skill_aggregates',
    'daily_activity',
    'user_streak',
    'custom_scenarios'
  ];
  t text;
BEGIN
  FOREACH t IN ARRAY expected LOOP
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.tables
      WHERE table_schema = 'public' AND table_name = t
    ) THEN
      RAISE EXCEPTION 'Missing table: %', t;
    END IF;
  END LOOP;
END $$;

-- Smoke test: RLS is enabled on every user-scoped table.
DO $$
DECLARE
  rls_required text[] := ARRAY[
    'users','sessions','transcript_turns','feedback_reports',
    'feedback_items','user_skill_aggregates','daily_activity',
    'user_streak','custom_scenarios'
  ];
  t text;
  rls_on boolean;
BEGIN
  FOREACH t IN ARRAY rls_required LOOP
    SELECT relrowsecurity INTO rls_on
    FROM pg_class WHERE relname = t AND relnamespace = 'public'::regnamespace;
    IF NOT rls_on THEN
      RAISE EXCEPTION 'RLS not enabled on: %', t;
    END IF;
  END LOOP;
END $$;

SELECT 'rls_smoke OK';
