-- Commit statistics, one pending suggestion per name, and a skill catalog.

alter table public.skill_suggestions
  add column commit_metrics jsonb not null default '{}'::jsonb,
  add column origin text not null default 'catalog';

alter table public.skill_suggestions
  add constraint skill_suggestions_origin check (origin in ('catalog', 'new_skill'));

create unique index skill_suggestions_one_pending_name
  on public.skill_suggestions (profile_id, lower(name))
  where status = 'pending';

create table public.skill_catalog (
  id text primary key,
  name text not null unique,
  aliases text[] not null default '{}',
  extensions text[] not null default '{}',
  created_at timestamptz not null default now()
);

alter table public.skill_catalog enable row level security;
revoke all on table public.skill_catalog from public, anon, authenticated;
grant select on table public.skill_catalog to authenticated;

create policy skill_catalog_read
  on public.skill_catalog for select to authenticated
  using (true);

create or replace function public.review_suggestion(p_suggestion_id uuid, p_accept boolean)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $fn$
declare
  uid uuid := auth.uid();
  suggestion public.skill_suggestions%rowtype;
  skill uuid;
  evidence_id uuid;
  signal text;
  stored_type text;
  repo text;
  metrics jsonb;
  found_confidence public.skill_confidence;
  found_reason text;
begin
  select * into suggestion
  from public.skill_suggestions
  where id = p_suggestion_id
  for update;
  if not found or suggestion.profile_id is distinct from uid then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;
  if suggestion.status <> 'pending' then
    raise exception 'ALREADY_REVIEWED' using errcode = 'P0001';
  end if;
  if not p_accept then
    update public.skill_suggestions
    set status = 'rejected', reviewed_at = now()
    where id = suggestion.id;
    return jsonb_build_object('skill_id', null, 'confidence', null, 'reason', null);
  end if;
  select id into skill
  from public.skills
  where profile_id = uid
    and name_normalized = lower(regexp_replace(btrim(suggestion.name), '\s+', ' ', 'g'));
  if skill is null then
    insert into public.skills (profile_id, name)
    values (uid, suggestion.name)
    returning id into skill;
  end if;
  foreach evidence_id in array suggestion.evidence_ids loop
    if exists (
      select 1 from public.evidence
      where id = evidence_id and profile_id = uid
    ) then
      insert into public.skill_evidence (skill_id, evidence_id)
      values (skill, evidence_id)
      on conflict do nothing;
      select github_full_name into repo
      from public.evidence where id = evidence_id;
      if suggestion.origin is distinct from 'new_skill' then
        foreach signal in array suggestion.signals loop
          stored_type := case split_part(signal, ':', 1)
            when 'language' then 'language_stat'
            when 'topic' then 'topic'
            when 'keyword' then 'readme_keyword'
            when 'dependency' then 'manifest_dependency'
            when 'file' then 'manifest_dependency'
            else 'readme_keyword'
          end;
          insert into public.evidence_signal (
            profile_id, skill_id, evidence_id, repo_ref, signal_type
          ) values (uid, skill, evidence_id, repo, stored_type)
          on conflict do nothing;
        end loop;
        metrics := suggestion.commit_metrics -> coalesce(repo, '');
        if metrics is not null and exists (
          select 1
          from jsonb_array_elements_text(coalesce(metrics -> 'skill_names', '[]'::jsonb)) as skill_name
          where lower(skill_name) = lower(suggestion.name)
        ) then
          insert into public.evidence_signal (
            profile_id, skill_id, evidence_id, repo_ref, signal_type,
            valid_commit_count, lines_authored, first_commit_at, last_commit_at
          ) values (
            uid,
            skill,
            evidence_id,
            repo,
            'commit_activity',
            (metrics ->> 'valid_commit_count')::integer,
            (metrics ->> 'lines_authored')::integer,
            (metrics ->> 'first_commit_at')::timestamptz,
            (metrics ->> 'last_commit_at')::timestamptz
          )
          on conflict do nothing;
        end if;
      end if;
    end if;
  end loop;
  perform public.recompute_skill_confidence(skill);
  select detail.confidence, detail.reason
    into found_confidence, found_reason
  from public._skill_confidence(uid, skill) as detail;
  update public.skill_suggestions
  set status = 'accepted', reviewed_at = now()
  where id = suggestion.id;
  return jsonb_build_object(
    'skill_id', skill,
    'confidence', found_confidence,
    'reason', found_reason
  );
end;
$fn$;

insert into public.skill_catalog (id, name, aliases, extensions) values
  ('flutter', 'Flutter', array['flutter']::text[], '{}'::text[]),
  ('dart', 'Dart', array['dart']::text[], array['.dart']::text[]),
  ('provider', 'Provider', array['provider']::text[], '{}'::text[]),
  ('react', 'React', array['react']::text[], '{}'::text[]),
  ('typescript', 'TypeScript', array['typescript']::text[], array['.ts','.tsx']::text[]),
  ('javascript', 'JavaScript', array['javascript']::text[], array['.js','.jsx']::text[]),
  ('python', 'Python', array['python']::text[], array['.py']::text[]),
  ('docker', 'Docker', array['docker']::text[], '{}'::text[]),
  ('postgresql', 'PostgreSQL', array['postgresql']::text[], '{}'::text[]),
  ('swift', 'Swift', array['swift']::text[], array['.swift']::text[]),
  ('kotlin', 'Kotlin', array['kotlin']::text[], array['.kt']::text[]),
  ('go', 'Go', array['go']::text[], array['.go']::text[]),
  ('rust', 'Rust', array['rust']::text[], array['.rs']::text[]),
  ('java', 'Java', array['java']::text[], array['.java']::text[]),
  ('c', 'C', array['c']::text[], array['.c','.h']::text[]),
  ('cplusplus', 'C++', array['c++']::text[], array['.cpp','.cc','.hpp']::text[]),
  ('csharp', 'C#', array['c#']::text[], array['.cs']::text[]),
  ('ruby', 'Ruby', array['ruby']::text[], array['.rb']::text[]),
  ('php', 'PHP', array['php']::text[], array['.php']::text[]),
  ('scala', 'Scala', array['scala']::text[], array['.scala']::text[]),
  ('elixir', 'Elixir', array['elixir']::text[], array['.ex']::text[]),
  ('haskell', 'Haskell', array['haskell']::text[], array['.hs']::text[]),
  ('lua', 'Lua', array['lua']::text[], array['.lua']::text[]),
  ('r', 'R', array['r']::text[], array['.r']::text[]),
  ('shell', 'Shell', array['shell']::text[], array['.sh']::text[]),
  ('sql', 'SQL', array['sql']::text[], '{}'::text[]),
  ('html', 'HTML', array['html']::text[], array['.html']::text[]),
  ('css', 'CSS', array['css']::text[], array['.css']::text[]),
  ('sass', 'Sass', array['sass']::text[], array['.scss']::text[]),
  ('tailwind', 'Tailwind', array['tailwind']::text[], '{}'::text[]),
  ('vue', 'Vue', array['vue']::text[], '{}'::text[]),
  ('angular', 'Angular', array['angular']::text[], '{}'::text[]),
  ('svelte', 'Svelte', array['svelte']::text[], '{}'::text[]),
  ('nextjs', 'Next.js', array['next.js']::text[], '{}'::text[]),
  ('nuxt', 'Nuxt', array['nuxt']::text[], '{}'::text[]),
  ('react-native', 'React Native', array['react native']::text[], '{}'::text[]),
  ('jetpack-compose', 'Jetpack Compose', array['jetpack compose']::text[], '{}'::text[]),
  ('swiftui', 'SwiftUI', array['swiftui']::text[], '{}'::text[]),
  ('android', 'Android', array['android']::text[], '{}'::text[]),
  ('ios', 'iOS', array['ios']::text[], '{}'::text[]),
  ('nodejs', 'Node.js', array['node.js']::text[], '{}'::text[]),
  ('express', 'Express', array['express']::text[], '{}'::text[]),
  ('nestjs', 'NestJS', array['nestjs']::text[], '{}'::text[]),
  ('django', 'Django', array['django']::text[], '{}'::text[]),
  ('flask', 'Flask', array['flask']::text[], '{}'::text[]),
  ('fastapi', 'FastAPI', array['fastapi']::text[], '{}'::text[]),
  ('spring', 'Spring', array['spring']::text[], '{}'::text[]),
  ('rails', 'Rails', array['rails']::text[], '{}'::text[]),
  ('laravel', 'Laravel', array['laravel']::text[], '{}'::text[]),
  ('gin', 'Gin', array['gin']::text[], '{}'::text[]),
  ('fiber', 'Fiber', array['fiber']::text[], '{}'::text[]),
  ('aspnet', 'ASP.NET', array['asp.net']::text[], '{}'::text[]),
  ('electron', 'Electron', array['electron']::text[], '{}'::text[]),
  ('unity', 'Unity', array['unity']::text[], '{}'::text[]),
  ('unreal', 'Unreal', array['unreal']::text[], '{}'::text[]),
  ('godot', 'Godot', array['godot']::text[], '{}'::text[]),
  ('firebase', 'Firebase', array['firebase']::text[], '{}'::text[]),
  ('supabase', 'Supabase', array['supabase']::text[], '{}'::text[]),
  ('prisma', 'Prisma', array['prisma']::text[], '{}'::text[]),
  ('graphql', 'GraphQL', array['graphql']::text[], '{}'::text[]),
  ('rest-api', 'REST API', array['rest api']::text[], '{}'::text[]),
  ('grpc', 'gRPC', array['grpc']::text[], '{}'::text[]),
  ('websocket', 'WebSocket', array['websocket']::text[], '{}'::text[]),
  ('openapi', 'OpenAPI', array['openapi']::text[], '{}'::text[]),
  ('protobuf', 'Protobuf', array['protobuf']::text[], '{}'::text[]),
  ('json', 'JSON', array['json']::text[], '{}'::text[]),
  ('yaml', 'YAML', array['yaml']::text[], '{}'::text[]),
  ('oauth', 'OAuth', array['oauth']::text[], '{}'::text[]),
  ('jwt', 'JWT', array['jwt']::text[], '{}'::text[]),
  ('redis', 'Redis', array['redis']::text[], '{}'::text[]),
  ('mysql', 'MySQL', array['mysql']::text[], '{}'::text[]),
  ('sqlite', 'SQLite', array['sqlite']::text[], '{}'::text[]),
  ('mongodb', 'MongoDB', array['mongodb']::text[], '{}'::text[]),
  ('elasticsearch', 'Elasticsearch', array['elasticsearch']::text[], '{}'::text[]),
  ('kafka', 'Kafka', array['kafka']::text[], '{}'::text[]),
  ('rabbitmq', 'RabbitMQ', array['rabbitmq']::text[], '{}'::text[]),
  ('nginx', 'Nginx', array['nginx']::text[], '{}'::text[]),
  ('linux', 'Linux', array['linux']::text[], '{}'::text[]),
  ('git', 'Git', array['git']::text[], '{}'::text[]),
  ('kubernetes', 'Kubernetes', array['kubernetes']::text[], '{}'::text[]),
  ('terraform', 'Terraform', array['terraform']::text[], '{}'::text[]),
  ('ansible', 'Ansible', array['ansible']::text[], '{}'::text[]),
  ('github-actions', 'GitHub Actions', array['github actions']::text[], '{}'::text[]),
  ('ci-cd', 'CI/CD', array['ci/cd']::text[], '{}'::text[]),
  ('aws', 'AWS', array['aws']::text[], '{}'::text[]),
  ('gcp', 'GCP', array['gcp']::text[], '{}'::text[]),
  ('azure', 'Azure', array['azure']::text[], '{}'::text[]),
  ('helm', 'Helm', array['helm']::text[], '{}'::text[]),
  ('prometheus', 'Prometheus', array['prometheus']::text[], '{}'::text[]),
  ('grafana', 'Grafana', array['grafana']::text[], '{}'::text[]),
  ('jest', 'Jest', array['jest']::text[], '{}'::text[]),
  ('pytest', 'Pytest', array['pytest']::text[], '{}'::text[]),
  ('junit', 'JUnit', array['junit']::text[], '{}'::text[]),
  ('selenium', 'Selenium', array['selenium']::text[], '{}'::text[]),
  ('cypress', 'Cypress', array['cypress']::text[], '{}'::text[]),
  ('playwright', 'Playwright', array['playwright']::text[], '{}'::text[]),
  ('bloc', 'Bloc', array['bloc']::text[], '{}'::text[]),
  ('riverpod', 'Riverpod', array['riverpod']::text[], '{}'::text[]),
  ('redux', 'Redux', array['redux']::text[], '{}'::text[]),
  ('mobx', 'MobX', array['mobx']::text[], '{}'::text[]),
  ('getx', 'GetX', array['getx']::text[], '{}'::text[]),
  ('hibernate', 'Hibernate', array['hibernate']::text[], '{}'::text[]),
  ('mybatis', 'MyBatis', array['mybatis']::text[], '{}'::text[]),
  ('pandas', 'Pandas', array['pandas']::text[], '{}'::text[]),
  ('numpy', 'NumPy', array['numpy']::text[], '{}'::text[]),
  ('tensorflow', 'TensorFlow', array['tensorflow']::text[], '{}'::text[]),
  ('pytorch', 'PyTorch', array['pytorch']::text[], '{}'::text[]),
  ('scikit-learn', 'scikit-learn', array['scikit-learn']::text[], '{}'::text[]),
  ('spark', 'Spark', array['spark']::text[], '{}'::text[]),
  ('hadoop', 'Hadoop', array['hadoop']::text[], '{}'::text[]),
  ('airflow', 'Airflow', array['airflow']::text[], '{}'::text[]),
  ('dbt', 'dbt', array['dbt']::text[], '{}'::text[]),
  ('snowflake', 'Snowflake', array['snowflake']::text[], '{}'::text[]),
  ('bigquery', 'BigQuery', array['bigquery']::text[], '{}'::text[]),
  ('figma', 'Figma', array['figma']::text[], '{}'::text[]),
  ('webpack', 'Webpack', array['webpack']::text[], '{}'::text[]),
  ('vite', 'Vite', array['vite']::text[], '{}'::text[]),
  ('esbuild', 'esbuild', array['esbuild']::text[], '{}'::text[]),
  ('babel', 'Babel', array['babel']::text[], '{}'::text[]),
  ('eslint', 'ESLint', array['eslint']::text[], '{}'::text[]),
  ('prettier', 'Prettier', array['prettier']::text[], '{}'::text[]),
  ('gradle', 'Gradle', array['gradle']::text[], '{}'::text[]),
  ('maven', 'Maven', array['maven']::text[], '{}'::text[]),
  ('cmake', 'CMake', array['cmake']::text[], '{}'::text[]),
  ('cocoapods', 'CocoaPods', array['cocoapods']::text[], '{}'::text[]),
  ('swift-package-manager', 'Swift Package Manager', array['swift package manager']::text[], '{}'::text[]),
  ('npm', 'npm', array['npm']::text[], '{}'::text[]),
  ('pnpm', 'pnpm', array['pnpm']::text[], '{}'::text[]),
  ('yarn', 'Yarn', array['yarn']::text[], '{}'::text[]),
  ('poetry', 'Poetry', array['poetry']::text[], '{}'::text[]),
  ('pip', 'Pip', array['pip']::text[], '{}'::text[]),
  ('cargo', 'Cargo', array['cargo']::text[], '{}'::text[]),
  ('composer', 'Composer', array['composer']::text[], '{}'::text[]),
  ('nuget', 'NuGet', array['nuget']::text[], '{}'::text[]),
  ('make', 'Make', array['make']::text[], '{}'::text[]),
  ('caddy', 'Caddy', array['caddy']::text[], '{}'::text[]),
  ('traefik', 'Traefik', array['traefik']::text[], '{}'::text[]),
  ('envoy', 'Envoy', array['envoy']::text[], '{}'::text[]),
  ('istio', 'Istio', array['istio']::text[], '{}'::text[]),
  ('postgresql-pl-pgsql', 'PostgreSQL PL/pgSQL', array['postgresql pl/pgsql']::text[], '{}'::text[]),
  ('postgis', 'PostGIS', array['postgis']::text[], '{}'::text[]),
  ('supabase-auth', 'Supabase Auth', array['supabase auth']::text[], '{}'::text[]),
  ('row-level-security', 'Row Level Security', array['row level security']::text[], '{}'::text[]),
  ('edge-functions', 'Edge Functions', array['edge functions']::text[], '{}'::text[]),
  ('flutter-web', 'Flutter Web', array['flutter web']::text[], '{}'::text[]),
  ('dart-frog', 'Dart Frog', array['dart frog']::text[], '{}'::text[]),
  ('serverpod', 'Serverpod', array['serverpod']::text[], '{}'::text[]),
  ('firebase-auth', 'Firebase Auth', array['firebase auth']::text[], '{}'::text[]),
  ('cloud-firestore', 'Cloud Firestore', array['cloud firestore']::text[], '{}'::text[]),
  ('cloud-functions', 'Cloud Functions', array['cloud functions']::text[], '{}'::text[]),
  ('s3', 'S3', array['s3']::text[], '{}'::text[]),
  ('lambda', 'Lambda', array['lambda']::text[], '{}'::text[]),
  ('cloud-run', 'Cloud Run', array['cloud run']::text[], '{}'::text[]),
  ('app-engine', 'App Engine', array['app engine']::text[], '{}'::text[]),
  ('ec2', 'EC2', array['ec2']::text[], '{}'::text[]),
  ('azure-functions', 'Azure Functions', array['azure functions']::text[], '{}'::text[]),
  ('docker-compose', 'Docker Compose', array['docker compose']::text[], '{}'::text[]),
  ('github', 'GitHub', array['github']::text[], '{}'::text[]),
  ('gitlab-ci', 'GitLab CI', array['gitlab ci']::text[], '{}'::text[]),
  ('bitbucket-pipelines', 'Bitbucket Pipelines', array['bitbucket pipelines']::text[], '{}'::text[]),
  ('circleci', 'CircleCI', array['circleci']::text[], '{}'::text[]),
  ('jenkins', 'Jenkins', array['jenkins']::text[], '{}'::text[]),
  ('argo-cd', 'Argo CD', array['argo cd']::text[], '{}'::text[]),
  ('flux', 'Flux', array['flux']::text[], '{}'::text[]),
  ('pulumi', 'Pulumi', array['pulumi']::text[], '{}'::text[]),
  ('packer', 'Packer', array['packer']::text[], '{}'::text[]),
  ('vagrant', 'Vagrant', array['vagrant']::text[], '{}'::text[]),
  ('nomad', 'Nomad', array['nomad']::text[], '{}'::text[]),
  ('consul', 'Consul', array['consul']::text[], '{}'::text[]);
