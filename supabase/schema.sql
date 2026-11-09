-- Esquema para el seguimiento de citas de la Dra. Andrea Pérez.
-- Se ejecuta una vez en Supabase: SQL Editor > New query > pegar > Run.
-- Solo se guardan datos de contacto y de la cita. NO guardar diagnósticos ni historial clínico.

create extension if not exists pgcrypto;

-- Solicitudes de cita (las crea el formulario público y las gestiona la doctora)
create table if not exists public.solicitudes (
  id uuid primary key default gen_random_uuid(),
  creada timestamptz not null default now(),
  nombre text not null check (char_length(nombre) between 2 and 100),
  telefono text not null check (char_length(telefono) between 8 and 20),
  servicio text not null check (char_length(servicio) between 2 and 80),
  fecha_preferida date,
  consentimiento boolean not null check (consentimiento = true),
  estado text not null default 'nueva'
    check (estado in ('nueva', 'contactada', 'agendada', 'atendida', 'cancelada')),
  fecha_cita timestamptz,
  nota text check (nota is null or char_length(nota) <= 500)
);

create index if not exists solicitudes_estado_idx on public.solicitudes (estado, creada desc);

-- Quién puede gestionar. Solo las cuentas que estén en esta tabla.
create table if not exists public.admins (
  user_id uuid primary key references auth.users (id) on delete cascade
);

alter table public.solicitudes enable row level security;
alter table public.admins enable row level security;

-- Privilegios mínimos (por si el proyecto expone tablas nuevas a la API por defecto):
-- el público solo puede insertar; las cuentas con sesión pasan además por las políticas de abajo.
revoke all on public.solicitudes from anon, authenticated;
revoke all on public.admins from anon, authenticated;
grant insert on public.solicitudes to anon;
grant select, update, delete on public.solicitudes to authenticated;
grant select on public.admins to authenticated;

-- Público (sin sesión): solo puede CREAR solicitudes nuevas. No puede leer ni editar.
drop policy if exists publico_crea on public.solicitudes;
create policy publico_crea on public.solicitudes
  for insert to anon
  with check (estado = 'nueva' and fecha_cita is null and nota is null);

-- Cuentas admin: leer, editar y borrar.
drop policy if exists admin_lee on public.solicitudes;
create policy admin_lee on public.solicitudes
  for select to authenticated
  using (exists (select 1 from public.admins a where a.user_id = auth.uid()));

drop policy if exists admin_edita on public.solicitudes;
create policy admin_edita on public.solicitudes
  for update to authenticated
  using (exists (select 1 from public.admins a where a.user_id = auth.uid()))
  with check (exists (select 1 from public.admins a where a.user_id = auth.uid()));

drop policy if exists admin_borra on public.solicitudes;
create policy admin_borra on public.solicitudes
  for delete to authenticated
  using (exists (select 1 from public.admins a where a.user_id = auth.uid()));

-- Cada usuario puede ver solo su propia fila en admins (para saber si tiene permiso).
drop policy if exists admin_se_ve on public.admins;
create policy admin_se_ve on public.admins
  for select to authenticated
  using (user_id = auth.uid());

-- Después de crear/invitar a la doctora en Authentication > Users, dale permiso:
-- insert into public.admins (user_id)
--   select id from auth.users where lower(email) = lower('Dra.Andrea.Pere@gmail.com');
