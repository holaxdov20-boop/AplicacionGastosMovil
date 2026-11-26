-- Esquema para Supabase (SQL Editor -> New query -> Run)
-- Cada fila pertenece a un usuario y Row Level Security impide leer o
-- modificar filas de otros usuarios.

create table if not exists public.categorias (
  id uuid primary key,
  user_id uuid not null default auth.uid()
    references auth.users(id) on delete cascade,
  nombre text not null check (char_length(nombre) between 1 and 40),
  color bigint not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.presupuestos (
  id uuid primary key,
  user_id uuid not null default auth.uid()
    references auth.users(id) on delete cascade,
  categoria_id uuid not null
    references public.categorias(id) on delete cascade,
  monto numeric(12,2) not null check (monto > 0),
  periodo text not null check (periodo in ('semanal', 'mensual')),
  updated_at timestamptz not null default now()
);

create table if not exists public.gastos (
  id uuid primary key,
  user_id uuid not null default auth.uid()
    references auth.users(id) on delete cascade,
  categoria_id uuid not null
    references public.categorias(id) on delete restrict,
  monto numeric(12,2) not null check (monto > 0),
  -- Se guarda CIFRADA desde el dispositivo (AES-256-GCM): el servidor
  -- nunca ve el texto original.
  descripcion_cifrada text not null default '',
  fecha timestamptz not null,
  updated_at timestamptz not null default now()
);

create index if not exists idx_gastos_user_fecha on public.gastos (user_id, fecha);

alter table public.categorias   enable row level security;
alter table public.presupuestos enable row level security;
alter table public.gastos       enable row level security;

create policy "categorias: solo el dueño" on public.categorias
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "presupuestos: solo el dueño" on public.presupuestos
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "gastos: solo el dueño" on public.gastos
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
