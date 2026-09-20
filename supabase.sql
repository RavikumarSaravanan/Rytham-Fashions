-- Rytham Fashions database and storage setup
create extension if not exists pgcrypto;

create table if not exists business_settings (
  id uuid primary key default gen_random_uuid(),
  business_name text not null default 'Rytham Fashions',
  phone text default '',
  whatsapp text default '',
  instagram text default 'https://www.instagram.com/rytham_fashions_porayar',
  address text default 'JP Kavya Complex, Veerapillai St, Kattucherry',
  google_maps text default 'https://maps.app.goo.gl/B3PiJ8JTEbUqAt57',
  opening_hours text default '',
  updated_at timestamptz not null default now()
);

create table if not exists services (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text default '',
  starting_price numeric default 0,
  image_url text default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists gallery (
  id uuid primary key default gen_random_uuid(),
  design_name text not null,
  category text not null,
  price numeric default 0,
  description text default '',
  image_url text default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists pricing (
  id uuid primary key default gen_random_uuid(),
  service_name text not null,
  price numeric default 0,
  description text default '',
  created_at timestamptz not null default now()
);

create table if not exists reviews (
  id uuid primary key default gen_random_uuid(),
  customer_name text not null,
  rating integer not null check (rating between 1 and 5),
  review_text text not null,
  customer_image text default '',
  created_at timestamptz not null default now()
);

alter table reviews add column if not exists updated_at timestamptz not null default now();
delete from reviews where customer_name = 'Reviews coming soon' and review_text = 'Customer reviews will be added by the owner from the Admin dashboard.';

create table if not exists enquiries (
  id uuid primary key default gen_random_uuid(),
  customer_name text not null,
  phone text not null,
  message text not null,
  source text default 'website',
  handled boolean not null default false,
  created_at timestamptz not null default now()
);

alter table business_settings enable row level security;
alter table services enable row level security;
alter table gallery enable row level security;
alter table pricing enable row level security;
alter table reviews enable row level security;
alter table enquiries enable row level security;

drop policy if exists "public read business settings" on business_settings;
create policy "public read business settings" on business_settings for select using (true);
drop policy if exists "public read services" on services;
create policy "public read services" on services for select using (true);
drop policy if exists "public read gallery" on gallery;
create policy "public read gallery" on gallery for select using (true);
drop policy if exists "public read pricing" on pricing;
create policy "public read pricing" on pricing for select using (true);
drop policy if exists "public read reviews" on reviews;
create policy "public read reviews" on reviews for select using (true);
drop policy if exists "public create enquiries" on enquiries;
create policy "public create enquiries" on enquiries for insert with check (true);

-- Authenticated admin users can manage private business content.
drop policy if exists "authenticated manage business settings" on business_settings;
create policy "authenticated manage business settings" on business_settings for all to authenticated using (true) with check (true);
drop policy if exists "authenticated manage services" on services;
create policy "authenticated manage services" on services for all to authenticated using (true) with check (true);
drop policy if exists "authenticated manage gallery" on gallery;
create policy "authenticated manage gallery" on gallery for all to authenticated using (true) with check (true);
drop policy if exists "authenticated manage pricing" on pricing;
create policy "authenticated manage pricing" on pricing for all to authenticated using (true) with check (true);
drop policy if exists "authenticated manage reviews" on reviews;
create policy "authenticated manage reviews" on reviews for all to authenticated using (true) with check (true);
drop policy if exists "authenticated manage enquiries" on enquiries;
create policy "authenticated manage enquiries" on enquiries for all to authenticated using (true) with check (true);

insert into business_settings (business_name)
select 'Rytham Fashions'
where not exists (select 1 from business_settings);

insert into services (name, description, image_url)
select * from (values
  ('Aari & Embroidery', 'Intricate designs, beautifully crafted', 'assets/gallery-1.jpg'),
  ('Blouse Stitching', 'All types of pattern blouses', 'assets/gallery-2.jpg'),
  ('Bridal Blouse', 'Make your special day more beautiful', 'assets/gallery-3.jpg'),
  ('Ladies Tailoring', 'Sarees, dresses and custom stitching', 'assets/gallery-4.jpg'),
  ('Alterations', 'Perfect fit, every time', 'assets/gallery-5.jpg'),
  ('Kids Dress', 'Comfortable custom outfits for little ones', 'assets/gallery-6.jpg')
) as starter(name, description, image_url)
where not exists (select 1 from services);

delete from gallery where (design_name, description) in (
  ('Aari Work', 'Detailed hand embroidery blouse design'),
  ('Bridal Blouse', 'Festive blouse with traditional detailing'),
  ('Designer Blouse', 'Custom designer blouse collection'),
  ('Embroidery', 'Colourful embroidery crafted with care'),
  ('Pattern Blouse', 'Pattern blouse with a neat finish'),
  ('More Designs', 'Explore more custom tailoring designs')
);

insert into pricing (service_name, description, price)
select * from (values
  ('Hand Embroidery', 'Custom hand embroidery designs', 0::numeric),
  ('Machine Embroidery', 'Detailed machine embroidery', 0::numeric),
  ('Pattern Blouse', 'Custom pattern blouse stitching', 0::numeric),
  ('Bridal Blouse', 'Made-to-measure bridal blouse design', 0::numeric)
) as starter(service_name, description, price)
where not exists (select 1 from pricing);

insert into storage.buckets (id, name, public)
values ('gallery-images', 'gallery-images', true), ('service-images', 'service-images', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists "public view gallery images" on storage.objects;
create policy "public view gallery images" on storage.objects for select using (bucket_id in ('gallery-images', 'service-images'));
drop policy if exists "authenticated upload fashion images" on storage.objects;
create policy "authenticated upload fashion images" on storage.objects for insert to authenticated with check (bucket_id in ('gallery-images', 'service-images'));
drop policy if exists "authenticated update fashion images" on storage.objects;
create policy "authenticated update fashion images" on storage.objects for update to authenticated using (bucket_id in ('gallery-images', 'service-images')) with check (bucket_id in ('gallery-images', 'service-images'));
drop policy if exists "authenticated delete fashion images" on storage.objects;
create policy "authenticated delete fashion images" on storage.objects for delete to authenticated using (bucket_id in ('gallery-images', 'service-images'));
