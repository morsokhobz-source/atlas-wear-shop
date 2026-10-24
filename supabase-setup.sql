-- Atlas Wear shop schema for Supabase.
-- Run this entire file once in Supabase Dashboard > SQL Editor > New query.
-- The public anon key is safe only because every table and storage operation below is protected by RLS.

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null check (category in ('Chaussures', 'T-shirts')),
  price integer not null check (price >= 0),
  sizes text[] not null default '{}',
  description text not null default '',
  image_url text not null default '',
  tag text not null default '',
  is_active boolean not null default true,
  sort_order integer not null default 100,
  created_at timestamptz not null default now()
);

create table if not exists public.shop_settings (
  id integer primary key check (id = 1),
  shop_name text not null default 'Atlas Wear',
  whatsapp text not null default '',
  announcement text not null default 'Livraison disponible dans les 58 wilayas · Commande simple par WhatsApp',
  updated_at timestamptz not null default now()
);

create table if not exists public.shop_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

-- Owner check used by RLS and the image bucket. SECURITY DEFINER avoids RLS recursion
-- when a policy checks membership in shop_admins.
create or replace function public.is_shop_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.shop_admins sa
    where sa.user_id = (select auth.uid())
  );
$$;
revoke all on function public.is_shop_admin() from public;
grant execute on function public.is_shop_admin() to anon, authenticated;

alter table public.products enable row level security;
alter table public.shop_settings enable row level security;
alter table public.shop_admins enable row level security;

grant usage on schema public to anon, authenticated;
grant select on public.products to anon, authenticated;
grant insert, update, delete on public.products to authenticated;
grant select on public.shop_settings to anon, authenticated;
grant update on public.shop_settings to authenticated;
grant select on public.shop_admins to authenticated;

drop policy if exists "public reads active products" on public.products;
create policy "public reads active products" on public.products
  for select to anon, authenticated
  using (is_active = true or public.is_shop_admin());
drop policy if exists "owner inserts products" on public.products;
create policy "owner inserts products" on public.products
  for insert to authenticated
  with check (public.is_shop_admin());
drop policy if exists "owner updates products" on public.products;
create policy "owner updates products" on public.products
  for update to authenticated
  using (public.is_shop_admin()) with check (public.is_shop_admin());
drop policy if exists "owner deletes products" on public.products;
create policy "owner deletes products" on public.products
  for delete to authenticated
  using (public.is_shop_admin());

drop policy if exists "public reads shop contact" on public.shop_settings;
create policy "public reads shop contact" on public.shop_settings
  for select to anon, authenticated using (true);
drop policy if exists "owner updates shop contact" on public.shop_settings;
create policy "owner updates shop contact" on public.shop_settings
  for update to authenticated
  using (public.is_shop_admin()) with check (public.is_shop_admin());

drop policy if exists "owner reads own membership" on public.shop_admins;
create policy "owner reads own membership" on public.shop_admins
  for select to authenticated
  using (user_id = (select auth.uid()));

-- Publicly readable product photos; only an authenticated shop owner can upload/change/delete them.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('product-images', 'product-images', true, 4194304, array['image/jpeg','image/png','image/webp','image/gif'])
on conflict (id) do update set public = true, file_size_limit = 4194304, allowed_mime_types = array['image/jpeg','image/png','image/webp','image/gif'];

drop policy if exists "public reads product photos" on storage.objects;
create policy "public reads product photos" on storage.objects
  for select to anon, authenticated
  using (bucket_id = 'product-images');
drop policy if exists "owner uploads product photos" on storage.objects;
create policy "owner uploads product photos" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'product-images' and public.is_shop_admin());
drop policy if exists "owner updates product photos" on storage.objects;
create policy "owner updates product photos" on storage.objects
  for update to authenticated
  using (bucket_id = 'product-images' and public.is_shop_admin())
  with check (bucket_id = 'product-images' and public.is_shop_admin());
drop policy if exists "owner deletes product photos" on storage.objects;
create policy "owner deletes product photos" on storage.objects
  for delete to authenticated
  using (bucket_id = 'product-images' and public.is_shop_admin());

insert into public.shop_settings (id, shop_name, whatsapp)
values (1, 'Atlas Wear', '')
on conflict (id) do nothing;

-- Sample products for preview only. The owner can change/delete these in the private dashboard.
insert into public.products (name, category, price, sizes, description, image_url, tag, is_active, sort_order)
select seed.name, seed.category, seed.price, seed.sizes, seed.description, seed.image_url, seed.tag, true, seed.sort_order
from (values
  ('Sneaker Studio', 'Chaussures', 8900, array['39','40','41','42','43','44']::text[], 'Un essentiel confortable au quotidien.', 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=900&q=82', 'Sélection', 10),
  ('T-shirt essentiel', 'T-shirts', 3500, array['S','M','L','XL','XXL']::text[], 'Une coupe simple, facile à associer.', 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?auto=format&fit=crop&w=900&q=82', '', 20),
  ('Runner classique', 'Chaussures', 9900, array['39','40','41','42','43','44']::text[], 'Léger et prêt pour la journée.', 'https://images.unsplash.com/photo-1552346154-21d32810aba3?auto=format&fit=crop&w=900&q=82', '', 30),
  ('T-shirt oversize', 'T-shirts', 4200, array['S','M','L','XL','XXL']::text[], 'Une silhouette décontractée et moderne.', 'https://images.unsplash.com/photo-1503341504253-dff4815485f1?auto=format&fit=crop&w=900&q=82', 'Nouveau', 40)
) as seed(name, category, price, sizes, description, image_url, tag, sort_order)
where not exists (select 1 from public.products);
