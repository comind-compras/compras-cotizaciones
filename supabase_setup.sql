-- ============================================================
--  Compras · Cotizaciones  —  configuración de Supabase
--  Pégalo en Supabase > SQL Editor > New query > Run (una sola vez)
-- ============================================================

-- 1) Tabla principal: guarda toda la app en una fila (id = 'main')
create table if not exists public.app_state (
  id          text primary key,
  data        jsonb       not null,
  rev         bigint      not null default 1,   -- sirve para detectar cambios hechos desde otro equipo
  updated_at  timestamptz not null default now(),
  updated_by  uuid        default auth.uid()
);

-- 2) Historial automático (copia de seguridad): máx. 1 cada 6 horas, se conservan las últimas 60
create table if not exists public.app_state_history (
  hid       bigint generated always as identity primary key,
  id        text        not null,
  data      jsonb       not null,
  rev       bigint      not null,
  saved_at  timestamptz not null default now(),
  saved_by  uuid
);

-- 3) Seguridad: solo usuarios con sesión iniciada (anónimos no ven nada)
alter table public.app_state         enable row level security;
alter table public.app_state_history enable row level security;

drop policy if exists "app_state_select" on public.app_state;
drop policy if exists "app_state_insert" on public.app_state;
drop policy if exists "app_state_update" on public.app_state;
drop policy if exists "history_select"   on public.app_state_history;

create policy "app_state_select" on public.app_state
  for select to authenticated using (true);
create policy "app_state_insert" on public.app_state
  for insert to authenticated with check (true);
create policy "app_state_update" on public.app_state
  for update to authenticated using (true) with check (true);
create policy "history_select" on public.app_state_history
  for select to authenticated using (true);
-- (no hay policy de DELETE: nadie puede borrar desde la app)

-- 4) Trigger: sella fecha/usuario y guarda el historial
create or replace function public.app_state_touch()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.updated_at := now();
  new.updated_by := auth.uid();

  if not exists (
    select 1 from public.app_state_history h
    where h.id = old.id and h.saved_at > now() - interval '6 hours'
  ) then
    insert into public.app_state_history (id, data, rev, saved_by)
    values (old.id, old.data, old.rev, old.updated_by);

    delete from public.app_state_history h
    where h.id = old.id
      and h.hid not in (
        select hid from public.app_state_history
        where id = old.id order by saved_at desc limit 60
      );
  end if;
  return new;
end $$;

drop trigger if exists app_state_touch on public.app_state;
create trigger app_state_touch
  before update on public.app_state
  for each row execute function public.app_state_touch();

-- 5) Vistas en formato tabla, para consultar desde otras plataformas
--    (Looker Studio, Power BI, Sheets con conector, apps propias, etc.)
create or replace view public.v_compras with (security_invoker = true) as
select
  r->>'id'                        as id,
  nullif(r->>'seq','')::int       as seq,
  r->>'VS'                        as vs,
  r->>'OP'                        as op,
  r->>'CANT'                      as cantidad,
  r->>'DESC'                      as descripcion,
  r->>'OBS'                       as observaciones,
  r->>'PROV'                      as proveedor,
  r->>'COT'                       as cotizado,
  r->>'OC'                        as oc,
  r->>'APR'                       as aprobado,
  r->>'ENTREGA'                   as tipo_entrega,
  r->>'SEDE'                      as recepcionado_en,
  r->>'FECHA'                     as recibido_el,
  r->>'NOTAS'                     as notas,
  r->>'estado'                    as estado   -- white / yellow / green / red
from public.app_state s
cross join lateral jsonb_array_elements(s.data->'records') r
where s.id = 'main';

create or replace view public.v_proveedores with (security_invoker = true) as
select p->>'name' as nombre, p->>'email' as correo, p->>'phone' as telefono, p->>'entrega' as entrega
from public.app_state s
cross join lateral jsonb_array_elements(s.data->'suppliers') p
where s.id = 'main';

create or replace view public.v_materiales with (security_invoker = true) as
select m->>'name' as material, m->>'unit' as unidad
from public.app_state s
cross join lateral jsonb_array_elements(s.data->'materials') m
where s.id = 'main';

-- Listo. Ahora: Authentication > Users > Add user (crea tu usuario con "Auto Confirm User")
-- y, si quieres, apaga el registro público en Authentication > Sign In / Providers.
