-- Fix RLS untuk tabel public.perpanjangan
-- Tujuan:
-- 1) User login bisa insert perpanjangan hanya untuk peminjaman miliknya.
-- 2) User bisa melihat perpanjangan miliknya.
-- 3) Admin bisa melihat semua perpanjangan (jika kolom role di users tersedia).
-- 4) Admin bisa update status perpanjangan (disetujui/ditolak).

begin;

alter table public.perpanjangan enable row level security;

-- Bersihkan policy lama (jika ada)
drop policy if exists perpanjangan_insert_owner on public.perpanjangan;
drop policy if exists perpanjangan_insert_owner_with_user_id on public.perpanjangan;
drop policy if exists perpanjangan_select_owner on public.perpanjangan;
drop policy if exists perpanjangan_select_owner_admin on public.perpanjangan;
drop policy if exists perpanjangan_update_admin on public.perpanjangan;
drop policy if exists perpanjangan_update_owner on public.perpanjangan;

-- Buat policy sesuai struktur tabel yang ada
DO $$
declare
  has_perpanjangan_user_id boolean;
  has_users_role boolean;
begin
  select exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'perpanjangan'
      and column_name = 'user_id'
  ) into has_perpanjangan_user_id;

  select exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'users'
      and column_name = 'role'
  ) into has_users_role;

  -- INSERT policy: user hanya boleh insert untuk peminjaman miliknya
  if has_perpanjangan_user_id then
    execute $sql$
      create policy perpanjangan_insert_owner_with_user_id
      on public.perpanjangan
      for insert
      to authenticated
      with check (
        auth.uid() = user_id
        and exists (
          select 1
          from public.peminjaman p
          where p.id = peminjaman_id
            and p.user_id = auth.uid()
        )
      );
    $sql$;
  else
    execute $sql$
      create policy perpanjangan_insert_owner
      on public.perpanjangan
      for insert
      to authenticated
      with check (
        exists (
          select 1
          from public.peminjaman p
          where p.id = peminjaman_id
            and p.user_id = auth.uid()
        )
      );
    $sql$;
  end if;

  -- SELECT policy: owner bisa lihat miliknya
  if has_users_role then
    execute $sql$
      create policy perpanjangan_select_owner_admin
      on public.perpanjangan
      for select
      to authenticated
      using (
        exists (
          select 1
          from public.peminjaman p
          where p.id = peminjaman_id
            and p.user_id = auth.uid()
        )
        or exists (
          select 1
          from public.users u
          where u.id = auth.uid()
            and lower(coalesce(u.role, '')) = 'admin'
        )
      );
    $sql$;

    -- UPDATE policy: admin boleh update status perpanjangan
    execute $sql$
      create policy perpanjangan_update_admin
      on public.perpanjangan
      for update
      to authenticated
      using (
        exists (
          select 1
          from public.users u
          where u.id = auth.uid()
            and lower(coalesce(u.role, '')) = 'admin'
        )
      )
      with check (
        exists (
          select 1
          from public.users u
          where u.id = auth.uid()
            and lower(coalesce(u.role, '')) = 'admin'
        )
      );
    $sql$;
  else
    execute $sql$
      create policy perpanjangan_select_owner
      on public.perpanjangan
      for select
      to authenticated
      using (
        exists (
          select 1
          from public.peminjaman p
          where p.id = peminjaman_id
            and p.user_id = auth.uid()
        )
      );
    $sql$;
  end if;
end $$;

commit;

-- Optional verifikasi cepat:
-- select schemaname, tablename, policyname, cmd, roles, permissive
-- from pg_policies
-- where schemaname = 'public' and tablename = 'perpanjangan'
-- order by policyname;
