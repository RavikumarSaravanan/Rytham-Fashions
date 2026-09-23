-- Rytham Fashions database and storage setup
create extension if not exists pgcrypto;

create table if not exists business_settings (
  id uuid primary key default gen_random_uuid(),
  business_name text not null default 'Rytham Fashions',
  phone text default '',
  whatsapp text default '',
  instagram text default 'https://www.instagram.com/rytham_fashions_porayar',
  address text default 'JP Kavya Complex, Veerapillai St, Porayar',
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

alter table gallery add column if not exists price_on_request boolean not null default false;

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

update business_settings
set address = 'JP Kavya Complex, Veerapillai St, Porayar'
where address is null or address = '' or address = 'JP Kavya Complex, Veerapillai St, Kattucherry';

-- Remove the original sample records without touching owner-uploaded records.
delete from services
where image_url in ('assets/gallery-1.jpg', 'assets/gallery-2.jpg', 'assets/gallery-3.jpg', 'assets/gallery-4.jpg', 'assets/gallery-5.jpg', 'assets/gallery-6.jpg');
delete from pricing
where service_name in ('Hand Embroidery', 'Machine Embroidery', 'Pattern Blouse', 'Bridal Blouse');
delete from gallery
where image_url like 'https://images.unsplash.com/%';

/* Demo seed data removed. New services, gallery designs, and pricing items are added from Admin.
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

insert into gallery (design_name, category, price, description, image_url)
select * from (values
  ('Rose Gold Bridal Blouse', 'Bridal Blouse', 2800::numeric, 'Rose gold zardosi work with a classic bridal finish', 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?auto=format&fit=crop&w=900&q=85'),
  ('Temple Motif Blouse', 'Aari Work', 2200::numeric, 'Traditional temple motifs with detailed hand embroidery', 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=900&q=85'),
  ('Peacock Aari Design', 'Aari Work', 2400::numeric, 'Peacock inspired aari embroidery for festive sarees', 'https://images.unsplash.com/photo-1610189012906-4c7f1f7e9e0b?auto=format&fit=crop&w=900&q=85'),
  ('Ruby Bridal Blouse', 'Bridal Blouse', 3200::numeric, 'Rich ruby detailing designed for wedding celebrations', 'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?auto=format&fit=crop&w=900&q=85'),
  ('Mirror Work Blouse', 'Designer Blouse', 1900::numeric, 'Contemporary mirror work with a neat tailored silhouette', 'https://images.unsplash.com/photo-1583391733956-6c78276477e2?auto=format&fit=crop&w=900&q=85'),
  ('Lotus Embroidery', 'Embroidery', 1800::numeric, 'Soft lotus embroidery with delicate thread highlights', 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?auto=format&fit=crop&w=900&q=85'),
  ('Festive Green Blouse', 'Designer Blouse', 2100::numeric, 'Jewel green blouse design for festive styling', 'https://images.unsplash.com/photo-1617331140180-e8262094733c?auto=format&fit=crop&w=900&q=85'),
  ('Gold Leaf Pattern', 'Embroidery', 2300::numeric, 'Gold leaf motifs arranged for an elegant finish', 'https://images.unsplash.com/photo-1585488433731-56f5a77e2e0a?auto=format&fit=crop&w=900&q=85'),
  ('Classic Magenta Blouse', 'Pattern Blouse', 1500::numeric, 'A timeless magenta pattern with a comfortable fit', 'https://images.unsplash.com/photo-1581044777550-4cfa60707c03?auto=format&fit=crop&w=900&q=85'),
  ('Pearl Border Blouse', 'Bridal Blouse', 2600::numeric, 'Pearl border detailing for a refined bridal look', 'https://images.unsplash.com/photo-1605763240000-7e93b172d754?auto=format&fit=crop&w=900&q=85'),
  ('Saree Pink Blouse', 'Pattern Blouse', 1300::numeric, 'Pretty pink blouse with a flattering modern pattern', 'https://images.unsplash.com/photo-1610030469668-8e9c8a3f64f8?auto=format&fit=crop&w=900&q=85'),
  ('Bridal Red Motif', 'Bridal Blouse', 3000::numeric, 'Bridal red with ornate motifs and statement detailing', 'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?auto=format&fit=crop&w=900&q=85'),
  ('Handworked Paisley', 'Aari Work', 2500::numeric, 'Handworked paisley design with dimensional threadwork', 'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?auto=format&fit=crop&w=900&q=85'),
  ('Champa Gold Blouse', 'Embroidery', 2000::numeric, 'Champa inspired gold embroidery for special occasions', 'https://images.unsplash.com/photo-1583391733956-6c78276477e2?auto=format&fit=crop&w=900&q=85'),
  ('Minimal Sequin Blouse', 'Designer Blouse', 1600::numeric, 'Clean silhouette with subtle sequin highlights', 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?auto=format&fit=crop&w=900&q=85'),
  ('Maroon Bridal Work', 'Bridal Blouse', 2900::numeric, 'Deep maroon bridal work with a rich traditional mood', 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=900&q=85'),
  ('Floral Thread Blouse', 'Embroidery', 1750::numeric, 'Colourful floral threadwork made for daytime events', 'https://images.unsplash.com/photo-1610189012906-4c7f1f7e9e0b?auto=format&fit=crop&w=900&q=85'),
  ('Kundan Highlight Blouse', 'Bridal Blouse', 3100::numeric, 'Kundan highlights paired with fine embroidery', 'https://images.unsplash.com/photo-1617331140180-e8262094733c?auto=format&fit=crop&w=900&q=85'),
  ('Peach Pattern Blouse', 'Pattern Blouse', 1400::numeric, 'Soft peach pattern with a polished neckline', 'https://images.unsplash.com/photo-1585488433731-56f5a77e2e0a?auto=format&fit=crop&w=900&q=85'),
  ('Rama Green Embroidery', 'Embroidery', 1850::numeric, 'Rama green embroidery with balanced border work', 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?auto=format&fit=crop&w=900&q=85'),
  ('Velvet Wine Blouse', 'Designer Blouse', 2250::numeric, 'Velvet wine finish with elegant hand details', 'https://images.unsplash.com/photo-1605763240000-7e93b172d754?auto=format&fit=crop&w=900&q=85'),
  ('Traditional Coin Work', 'Aari Work', 2350::numeric, 'Traditional coin work arranged in a graceful pattern', 'https://images.unsplash.com/photo-1610030469668-8e9c8a3f64f8?auto=format&fit=crop&w=900&q=85'),
  ('Ivory Floral Blouse', 'Pattern Blouse', 1550::numeric, 'Ivory floral design with a soft premium finish', 'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?auto=format&fit=crop&w=900&q=85'),
  ('Classic Gold Border', 'Aari Work', 2150::numeric, 'Classic gold border work for silk saree styling', 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?auto=format&fit=crop&w=900&q=85'),
  ('Coral Designer Blouse', 'Designer Blouse', 1650::numeric, 'Coral shade with a confident contemporary pattern', 'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?auto=format&fit=crop&w=900&q=85'),
  ('Bridal Lotus Motif', 'Bridal Blouse', 2750::numeric, 'Lotus motif bridal design with detailed gold work', 'https://images.unsplash.com/photo-1583391733956-6c78276477e2?auto=format&fit=crop&w=900&q=85'),
  ('Turquoise Thread Work', 'Embroidery', 1950::numeric, 'Turquoise thread work for a bright statement blouse', 'https://images.unsplash.com/photo-1617331140180-e8262094733c?auto=format&fit=crop&w=900&q=85'),
  ('Rose Petal Pattern', 'Pattern Blouse', 1450::numeric, 'Rose petal pattern with clean everyday elegance', 'https://images.unsplash.com/photo-1585488433731-56f5a77e2e0a?auto=format&fit=crop&w=900&q=85'),
  ('Antique Gold Aari', 'Aari Work', 2650::numeric, 'Antique gold aari work with a heritage inspired feel', 'https://images.unsplash.com/photo-1610189012906-4c7f1f7e9e0b?auto=format&fit=crop&w=900&q=85'),
  ('Lavender Sequin Blouse', 'Designer Blouse', 1750::numeric, 'Lavender sequin accents with a graceful neckline', 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?auto=format&fit=crop&w=900&q=85'),
  ('Crimson Zari Blouse', 'Bridal Blouse', 3300::numeric, 'Crimson zari detailing made for the bridal trousseau', 'https://images.unsplash.com/photo-1605763240000-7e93b172d754?auto=format&fit=crop&w=900&q=85'),
  ('Daisy Embroidery', 'Embroidery', 1650::numeric, 'Daisy embroidery for a light and cheerful finish', 'https://images.unsplash.com/photo-1610030469668-8e9c8a3f64f8?auto=format&fit=crop&w=900&q=85'),
  ('Mustard Silk Pattern', 'Pattern Blouse', 1350::numeric, 'Mustard silk pattern with a crisp tailored finish', 'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?auto=format&fit=crop&w=900&q=85'),
  ('Royal Blue Bridal', 'Bridal Blouse', 2950::numeric, 'Royal blue bridal style with ornate border detailing', 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?auto=format&fit=crop&w=900&q=85'),
  ('Silver Leaf Work', 'Aari Work', 2450::numeric, 'Silver leaf work for a cool-toned festive look', 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=900&q=85'),
  ('Blush Floral Blouse', 'Designer Blouse', 1800::numeric, 'Blush floral blouse with delicate finish work', 'https://images.unsplash.com/photo-1617331140180-e8262094733c?auto=format&fit=crop&w=900&q=85'),
  ('Green Peacock Blouse', 'Aari Work', 2550::numeric, 'Green peacock work with rich dimensional embroidery', 'https://images.unsplash.com/photo-1583391733956-6c78276477e2?auto=format&fit=crop&w=900&q=85'),
  ('Copper Sequin Pattern', 'Pattern Blouse', 1550::numeric, 'Copper sequin pattern for evening celebrations', 'https://images.unsplash.com/photo-1585488433731-56f5a77e2e0a?auto=format&fit=crop&w=900&q=85'),
  ('Mango Bridal Blouse', 'Bridal Blouse', 2850::numeric, 'Mango shade bridal blouse with intricate motifs', 'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?auto=format&fit=crop&w=900&q=85'),
  ('Pastel Thread Garden', 'Embroidery', 1900::numeric, 'Pastel thread garden design with a soft feminine finish', 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?auto=format&fit=crop&w=900&q=85'),
  ('Black Gold Designer', 'Designer Blouse', 2050::numeric, 'Black and gold designer combination with bold detailing', 'https://images.unsplash.com/photo-1605763240000-7e93b172d754?auto=format&fit=crop&w=900&q=85'),
  ('Temple Border Pattern', 'Pattern Blouse', 1500::numeric, 'Temple border inspired pattern for traditional sarees', 'https://images.unsplash.com/photo-1610030469668-8e9c8a3f64f8?auto=format&fit=crop&w=900&q=85'),
  ('Fuchsia Aari Blouse', 'Aari Work', 2350::numeric, 'Fuchsia aari work with a striking festive presence', 'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?auto=format&fit=crop&w=900&q=85'),
  ('Champagne Bridal Work', 'Bridal Blouse', 3400::numeric, 'Champagne bridal work with refined shimmer and texture', 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?auto=format&fit=crop&w=900&q=85'),
  ('Indigo Floral Blouse', 'Embroidery', 1700::numeric, 'Indigo floral embroidery with a modern tailored cut', 'https://images.unsplash.com/photo-1610189012906-4c7f1f7e9e0b?auto=format&fit=crop&w=900&q=85'),
  ('Peacock Feather Border', 'Aari Work', 2600::numeric, 'Peacock feather border crafted with fine handwork', 'https://images.unsplash.com/photo-1617331140180-e8262094733c?auto=format&fit=crop&w=900&q=85'),
  ('Saffron Party Blouse', 'Designer Blouse', 1850::numeric, 'Saffron party blouse with a bright contemporary look', 'https://images.unsplash.com/photo-1583391733956-6c78276477e2?auto=format&fit=crop&w=900&q=85'),
  ('Pearl Vine Pattern', 'Pattern Blouse', 1600::numeric, 'Pearl vine pattern with delicate border detailing', 'https://images.unsplash.com/photo-1585488433731-56f5a77e2e0a?auto=format&fit=crop&w=900&q=85'),
  ('Wedding Gold Motif', 'Bridal Blouse', 3250::numeric, 'Wedding gold motif blouse with a luxurious finish', 'https://images.unsplash.com/photo-1605763240000-7e93b172d754?auto=format&fit=crop&w=900&q=85'),
  ('Coral Lotus Embroidery', 'Embroidery', 1750::numeric, 'Coral lotus embroidery with clean handcrafted details', 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=900&q=85'),
  ('Rose Gold Bridal Blouse', 'Bridal Blouse', 2800::numeric, 'Rose gold zardosi work with a classic bridal finish', 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?auto=format&fit=crop&w=900&q=85'),
  ('Temple Motif Blouse', 'Aari Work', 2200::numeric, 'Traditional temple motifs with detailed hand embroidery', 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=900&q=85'),
  ('Peacock Aari Design', 'Aari Work', 2400::numeric, 'Peacock inspired aari embroidery for festive sarees', 'https://images.unsplash.com/photo-1610189012906-4c7f1f7e9e0b?auto=format&fit=crop&w=900&q=85'),
  ('Ruby Bridal Blouse', 'Bridal Blouse', 3200::numeric, 'Rich ruby detailing designed for wedding celebrations', 'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?auto=format&fit=crop&w=900&q=85'),
  ('Mirror Work Blouse', 'Designer Blouse', 1900::numeric, 'Contemporary mirror work with a neat tailored silhouette', 'https://images.unsplash.com/photo-1583391733956-6c78276477e2?auto=format&fit=crop&w=900&q=85'),
  ('Lotus Embroidery', 'Embroidery', 1800::numeric, 'Soft lotus embroidery with delicate thread highlights', 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?auto=format&fit=crop&w=900&q=85'),
  ('Festive Green Blouse', 'Designer Blouse', 2100::numeric, 'Jewel green blouse design for festive styling', 'https://images.unsplash.com/photo-1617331140180-e8262094733c?auto=format&fit=crop&w=900&q=85'),
  ('Gold Leaf Pattern', 'Embroidery', 2300::numeric, 'Gold leaf motifs arranged for an elegant finish', 'https://images.unsplash.com/photo-1585488433731-56f5a77e2e0a?auto=format&fit=crop&w=900&q=85'),
  ('Classic Magenta Blouse', 'Pattern Blouse', 1500::numeric, 'A timeless magenta pattern with a comfortable fit', 'https://images.unsplash.com/photo-1581044777550-4cfa60707c03?auto=format&fit=crop&w=900&q=85'),
  ('Pearl Border Blouse', 'Bridal Blouse', 2600::numeric, 'Pearl border detailing for a refined bridal look', 'https://images.unsplash.com/photo-1605763240000-7e93b172d754?auto=format&fit=crop&w=900&q=85'),
  ('Saree Pink Blouse', 'Pattern Blouse', 1300::numeric, 'Pretty pink blouse with a flattering modern pattern', 'https://images.unsplash.com/photo-1610030469668-8e9c8a3f64f8?auto=format&fit=crop&w=900&q=85'),
  ('Bridal Red Motif', 'Bridal Blouse', 3000::numeric, 'Bridal red with ornate motifs and statement detailing', 'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?auto=format&fit=crop&w=900&q=85'),
  ('Handworked Paisley', 'Aari Work', 2500::numeric, 'Handworked paisley design with dimensional threadwork', 'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?auto=format&fit=crop&w=900&q=85'),
  ('Champa Gold Blouse', 'Embroidery', 2000::numeric, 'Champa inspired gold embroidery for special occasions', 'https://images.unsplash.com/photo-1583391733956-6c78276477e2?auto=format&fit=crop&w=900&q=85'),
  ('Minimal Sequin Blouse', 'Designer Blouse', 1600::numeric, 'Clean silhouette with subtle sequin highlights', 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?auto=format&fit=crop&w=900&q=85'),
  ('Maroon Bridal Work', 'Bridal Blouse', 2900::numeric, 'Deep maroon bridal work with a rich traditional mood', 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=900&q=85'),
  ('Floral Thread Blouse', 'Embroidery', 1750::numeric, 'Colourful floral threadwork made for daytime events', 'https://images.unsplash.com/photo-1610189012906-4c7f1f7e9e0b?auto=format&fit=crop&w=900&q=85'),
  ('Kundan Highlight Blouse', 'Bridal Blouse', 3100::numeric, 'Kundan highlights paired with fine embroidery', 'https://images.unsplash.com/photo-1617331140180-e8262094733c?auto=format&fit=crop&w=900&q=85'),
  ('Peach Pattern Blouse', 'Pattern Blouse', 1400::numeric, 'Soft peach pattern with a polished neckline', 'https://images.unsplash.com/photo-1585488433731-56f5a77e2e0a?auto=format&fit=crop&w=900&q=85'),
  ('Rama Green Embroidery', 'Embroidery', 1850::numeric, 'Rama green embroidery with balanced border work', 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?auto=format&fit=crop&w=900&q=85'),
  ('Velvet Wine Blouse', 'Designer Blouse', 2250::numeric, 'Velvet wine finish with elegant hand details', 'https://images.unsplash.com/photo-1605763240000-7e93b172d754?auto=format&fit=crop&w=900&q=85'),
  ('Traditional Coin Work', 'Aari Work', 2350::numeric, 'Traditional coin work arranged in a graceful pattern', 'https://images.unsplash.com/photo-1610030469668-8e9c8a3f64f8?auto=format&fit=crop&w=900&q=85'),
  ('Ivory Floral Blouse', 'Pattern Blouse', 1550::numeric, 'Ivory floral design with a soft premium finish', 'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?auto=format&fit=crop&w=900&q=85'),
  ('Classic Gold Border', 'Aari Work', 2150::numeric, 'Classic gold border work for silk saree styling', 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?auto=format&fit=crop&w=900&q=85'),
  ('Coral Designer Blouse', 'Designer Blouse', 1650::numeric, 'Coral shade with a confident contemporary pattern', 'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?auto=format&fit=crop&w=900&q=85'),
  ('Bridal Lotus Motif', 'Bridal Blouse', 2750::numeric, 'Lotus motif bridal design with detailed gold work', 'https://images.unsplash.com/photo-1583391733956-6c78276477e2?auto=format&fit=crop&w=900&q=85'),
  ('Turquoise Thread Work', 'Embroidery', 1950::numeric, 'Turquoise thread work for a bright statement blouse', 'https://images.unsplash.com/photo-1617331140180-e8262094733c?auto=format&fit=crop&w=900&q=85'),
  ('Rose Petal Pattern', 'Pattern Blouse', 1450::numeric, 'Rose petal pattern with clean everyday elegance', 'https://images.unsplash.com/photo-1585488433731-56f5a77e2e0a?auto=format&fit=crop&w=900&q=85'),
  ('Antique Gold Aari', 'Aari Work', 2650::numeric, 'Antique gold aari work with a heritage inspired feel', 'https://images.unsplash.com/photo-1610189012906-4c7f1f7e9e0b?auto=format&fit=crop&w=900&q=85'),
  ('Lavender Sequin Blouse', 'Designer Blouse', 1750::numeric, 'Lavender sequin accents with a graceful neckline', 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?auto=format&fit=crop&w=900&q=85'),
  ('Crimson Zari Blouse', 'Bridal Blouse', 3300::numeric, 'Crimson zari detailing made for the bridal trousseau', 'https://images.unsplash.com/photo-1605763240000-7e93b172d754?auto=format&fit=crop&w=900&q=85'),
  ('Daisy Embroidery', 'Embroidery', 1650::numeric, 'Daisy embroidery for a light and cheerful finish', 'https://images.unsplash.com/photo-1610030469668-8e9c8a3f64f8?auto=format&fit=crop&w=900&q=85'),
  ('Mustard Silk Pattern', 'Pattern Blouse', 1350::numeric, 'Mustard silk pattern with a crisp tailored finish', 'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?auto=format&fit=crop&w=900&q=85'),
  ('Royal Blue Bridal', 'Bridal Blouse', 2950::numeric, 'Royal blue bridal style with ornate border detailing', 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?auto=format&fit=crop&w=900&q=85'),
  ('Silver Leaf Work', 'Aari Work', 2450::numeric, 'Silver leaf work for a cool-toned festive look', 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=900&q=85'),
  ('Blush Floral Blouse', 'Designer Blouse', 1800::numeric, 'Blush floral blouse with delicate finish work', 'https://images.unsplash.com/photo-1617331140180-e8262094733c?auto=format&fit=crop&w=900&q=85'),
  ('Green Peacock Blouse', 'Aari Work', 2550::numeric, 'Green peacock work with rich dimensional embroidery', 'https://images.unsplash.com/photo-1583391733956-6c78276477e2?auto=format&fit=crop&w=900&q=85'),
  ('Copper Sequin Pattern', 'Pattern Blouse', 1550::numeric, 'Copper sequin pattern for evening celebrations', 'https://images.unsplash.com/photo-1585488433731-56f5a77e2e0a?auto=format&fit=crop&w=900&q=85'),
  ('Mango Bridal Blouse', 'Bridal Blouse', 2850::numeric, 'Mango shade bridal blouse with intricate motifs', 'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?auto=format&fit=crop&w=900&q=85'),
  ('Pastel Thread Garden', 'Embroidery', 1900::numeric, 'Pastel thread garden design with a soft feminine finish', 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?auto=format&fit=crop&w=900&q=85'),
  ('Black Gold Designer', 'Designer Blouse', 2050::numeric, 'Black and gold designer combination with bold detailing', 'https://images.unsplash.com/photo-1605763240000-7e93b172d754?auto=format&fit=crop&w=900&q=85'),
  ('Temple Border Pattern', 'Pattern Blouse', 1500::numeric, 'Temple border inspired pattern for traditional sarees', 'https://images.unsplash.com/photo-1610030469668-8e9c8a3f64f8?auto=format&fit=crop&w=900&q=85'),
  ('Fuchsia Aari Blouse', 'Aari Work', 2350::numeric, 'Fuchsia aari work with a striking festive presence', 'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?auto=format&fit=crop&w=900&q=85'),
  ('Champagne Bridal Work', 'Bridal Blouse', 3400::numeric, 'Champagne bridal work with refined shimmer and texture', 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?auto=format&fit=crop&w=900&q=85'),
  ('Indigo Floral Blouse', 'Embroidery', 1700::numeric, 'Indigo floral embroidery with a modern tailored cut', 'https://images.unsplash.com/photo-1610189012906-4c7f1f7e9e0b?auto=format&fit=crop&w=900&q=85'),
  ('Peacock Feather Border', 'Aari Work', 2600::numeric, 'Peacock feather border crafted with fine handwork', 'https://images.unsplash.com/photo-1617331140180-e8262094733c?auto=format&fit=crop&w=900&q=85'),
  ('Saffron Party Blouse', 'Designer Blouse', 1850::numeric, 'Saffron party blouse with a bright contemporary look', 'https://images.unsplash.com/photo-1583391733956-6c78276477e2?auto=format&fit=crop&w=900&q=85'),
  ('Pearl Vine Pattern', 'Pattern Blouse', 1600::numeric, 'Pearl vine pattern with delicate border detailing', 'https://images.unsplash.com/photo-1585488433731-56f5a77e2e0a?auto=format&fit=crop&w=900&q=85'),
  ('Wedding Gold Motif', 'Bridal Blouse', 3250::numeric, 'Wedding gold motif blouse with a luxurious finish', 'https://images.unsplash.com/photo-1605763240000-7e93b172d754?auto=format&fit=crop&w=900&q=85'),
  ('Coral Lotus Embroidery', 'Embroidery', 1750::numeric, 'Coral lotus embroidery with clean handcrafted details', 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=900&q=85'),
  ('Rose Gold Bridal Blouse', 'Bridal Blouse', 2800::numeric, 'Rose gold zardosi work with a classic bridal finish', 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?auto=format&fit=crop&w=900&q=85'),
  ('Temple Motif Blouse', 'Aari Work', 2200::numeric, 'Traditional temple motifs with detailed hand embroidery', 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=900&q=85'),
  ('Peacock Aari Design', 'Aari Work', 2400::numeric, 'Peacock inspired aari embroidery for festive sarees', 'https://images.unsplash.com/photo-1610189012906-4c7f1f7e9e0b?auto=format&fit=crop&w=900&q=85'),
  ('Ruby Bridal Blouse', 'Bridal Blouse', 3200::numeric, 'Rich ruby detailing designed for wedding celebrations', 'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?auto=format&fit=crop&w=900&q=85'),
  ('Mirror Work Blouse', 'Designer Blouse', 1900::numeric, 'Contemporary mirror work with a neat tailored silhouette', 'https://images.unsplash.com/photo-1583391733956-6c78276477e2?auto=format&fit=crop&w=900&q=85'),
  ('Lotus Embroidery', 'Embroidery', 1800::numeric, 'Soft lotus embroidery with delicate thread highlights', 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?auto=format&fit=crop&w=900&q=85'),
  ('Festive Green Blouse', 'Designer Blouse', 2100::numeric, 'Jewel green blouse design for festive styling', 'https://images.unsplash.com/photo-1617331140180-e8262094733c?auto=format&fit=crop&w=900&q=85'),
  ('Gold Leaf Pattern', 'Embroidery', 2300::numeric, 'Gold leaf motifs arranged for an elegant finish', 'https://images.unsplash.com/photo-1585488433731-56f5a77e2e0a?auto=format&fit=crop&w=900&q=85'),
  ('Classic Magenta Blouse', 'Pattern Blouse', 1500::numeric, 'A timeless magenta pattern with a comfortable fit', 'https://images.unsplash.com/photo-1581044777550-4cfa60707c03?auto=format&fit=crop&w=900&q=85'),
  ('Pearl Border Blouse', 'Bridal Blouse', 2600::numeric, 'Pearl border detailing for a refined bridal look', 'https://images.unsplash.com/photo-1605763240000-7e93b172d754?auto=format&fit=crop&w=900&q=85'),
  ('Saree Pink Blouse', 'Pattern Blouse', 1300::numeric, 'Pretty pink blouse with a flattering modern pattern', 'https://images.unsplash.com/photo-1610030469668-8e9c8a3f64f8?auto=format&fit=crop&w=900&q=85'),
  ('Bridal Red Motif', 'Bridal Blouse', 3000::numeric, 'Bridal red with ornate motifs and statement detailing', 'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?auto=format&fit=crop&w=900&q=85'),
  ('Handworked Paisley', 'Aari Work', 2500::numeric, 'Handworked paisley design with dimensional threadwork', 'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?auto=format&fit=crop&w=900&q=85'),
  ('Champa Gold Blouse', 'Embroidery', 2000::numeric, 'Champa inspired gold embroidery for special occasions', 'https://images.unsplash.com/photo-1583391733956-6c78276477e2?auto=format&fit=crop&w=900&q=85'),
  ('Minimal Sequin Blouse', 'Designer Blouse', 1600::numeric, 'Clean silhouette with subtle sequin highlights', 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?auto=format&fit=crop&w=900&q=85'),
  ('Maroon Bridal Work', 'Bridal Blouse', 2900::numeric, 'Deep maroon bridal work with a rich traditional mood', 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=900&q=85'),
  ('Floral Thread Blouse', 'Embroidery', 1750::numeric, 'Colourful floral threadwork made for daytime events', 'https://images.unsplash.com/photo-1610189012906-4c7f1f7e9e0b?auto=format&fit=crop&w=900&q=85'),
  ('Kundan Highlight Blouse', 'Bridal Blouse', 3100::numeric, 'Kundan highlights paired with fine embroidery', 'https://images.unsplash.com/photo-1617331140180-e8262094733c?auto=format&fit=crop&w=900&q=85'),
  ('Peach Pattern Blouse', 'Pattern Blouse', 1400::numeric, 'Soft peach pattern with a polished neckline', 'https://images.unsplash.com/photo-1585488433731-56f5a77e2e0a?auto=format&fit=crop&w=900&q=85'),
  ('Rama Green Embroidery', 'Embroidery', 1850::numeric, 'Rama green embroidery with balanced border work', 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?auto=format&fit=crop&w=900&q=85'),
  ('Velvet Wine Blouse', 'Designer Blouse', 2250::numeric, 'Velvet wine finish with elegant hand details', 'https://images.unsplash.com/photo-1605763240000-7e93b172d754?auto=format&fit=crop&w=900&q=85'),
  ('Traditional Coin Work', 'Aari Work', 2350::numeric, 'Traditional coin work arranged in a graceful pattern', 'https://images.unsplash.com/photo-1610030469668-8e9c8a3f64f8?auto=format&fit=crop&w=900&q=85'),
  ('Ivory Floral Blouse', 'Pattern Blouse', 1550::numeric, 'Ivory floral design with a soft premium finish', 'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?auto=format&fit=crop&w=900&q=85'),
  ('Classic Gold Border', 'Aari Work', 2150::numeric, 'Classic gold border work for silk saree styling', 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?auto=format&fit=crop&w=900&q=85'),
  ('Coral Designer Blouse', 'Designer Blouse', 1650::numeric, 'Coral shade with a confident contemporary pattern', 'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?auto=format&fit=crop&w=900&q=85'),
  ('Bridal Lotus Motif', 'Bridal Blouse', 2750::numeric, 'Lotus motif bridal design with detailed gold work', 'https://images.unsplash.com/photo-1583391733956-6c78276477e2?auto=format&fit=crop&w=900&q=85'),
  ('Turquoise Thread Work', 'Embroidery', 1950::numeric, 'Turquoise thread work for a bright statement blouse', 'https://images.unsplash.com/photo-1617331140180-e8262094733c?auto=format&fit=crop&w=900&q=85'),
  ('Rose Petal Pattern', 'Pattern Blouse', 1450::numeric, 'Rose petal pattern with clean everyday elegance', 'https://images.unsplash.com/photo-1585488433731-56f5a77e2e0a?auto=format&fit=crop&w=900&q=85'),
  ('Antique Gold Aari', 'Aari Work', 2650::numeric, 'Antique gold aari work with a heritage inspired feel', 'https://images.unsplash.com/photo-1610189012906-4c7f1f7e9e0b?auto=format&fit=crop&w=900&q=85'),
  ('Lavender Sequin Blouse', 'Designer Blouse', 1750::numeric, 'Lavender sequin accents with a graceful neckline', 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?auto=format&fit=crop&w=900&q=85'),
  ('Crimson Zari Blouse', 'Bridal Blouse', 3300::numeric, 'Crimson zari detailing made for the bridal trousseau', 'https://images.unsplash.com/photo-1605763240000-7e93b172d754?auto=format&fit=crop&w=900&q=85'),
  ('Daisy Embroidery', 'Embroidery', 1650::numeric, 'Daisy embroidery for a light and cheerful finish', 'https://images.unsplash.com/photo-1610030469668-8e9c8a3f64f8?auto=format&fit=crop&w=900&q=85'),
  ('Mustard Silk Pattern', 'Pattern Blouse', 1350::numeric, 'Mustard silk pattern with a crisp tailored finish', 'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?auto=format&fit=crop&w=900&q=85'),
  ('Royal Blue Bridal', 'Bridal Blouse', 2950::numeric, 'Royal blue bridal style with ornate border detailing', 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?auto=format&fit=crop&w=900&q=85'),
  ('Silver Leaf Work', 'Aari Work', 2450::numeric, 'Silver leaf work for a cool-toned festive look', 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=900&q=85'),
  ('Blush Floral Blouse', 'Designer Blouse', 1800::numeric, 'Blush floral blouse with delicate finish work', 'https://images.unsplash.com/photo-1617331140180-e8262094733c?auto=format&fit=crop&w=900&q=85'),
  ('Green Peacock Blouse', 'Aari Work', 2550::numeric, 'Green peacock work with rich dimensional embroidery', 'https://images.unsplash.com/photo-1583391733956-6c78276477e2?auto=format&fit=crop&w=900&q=85'),
  ('Copper Sequin Pattern', 'Pattern Blouse', 1550::numeric, 'Copper sequin pattern for evening celebrations', 'https://images.unsplash.com/photo-1585488433731-56f5a77e2e0a?auto=format&fit=crop&w=900&q=85'),
  ('Mango Bridal Blouse', 'Bridal Blouse', 2850::numeric, 'Mango shade bridal blouse with intricate motifs', 'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?auto=format&fit=crop&w=900&q=85'),
  ('Pastel Thread Garden', 'Embroidery', 1900::numeric, 'Pastel thread garden design with a soft feminine finish', 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?auto=format&fit=crop&w=900&q=85'),
  ('Black Gold Designer', 'Designer Blouse', 2050::numeric, 'Black and gold designer combination with bold detailing', 'https://images.unsplash.com/photo-1605763240000-7e93b172d754?auto=format&fit=crop&w=900&q=85'),
  ('Temple Border Pattern', 'Pattern Blouse', 1500::numeric, 'Temple border inspired pattern for traditional sarees', 'https://images.unsplash.com/photo-1610030469668-8e9c8a3f64f8?auto=format&fit=crop&w=900&q=85'),
  ('Fuchsia Aari Blouse', 'Aari Work', 2350::numeric, 'Fuchsia aari work with a striking festive presence', 'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?auto=format&fit=crop&w=900&q=85'),
  ('Champagne Bridal Work', 'Bridal Blouse', 3400::numeric, 'Champagne bridal work with refined shimmer and texture', 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?auto=format&fit=crop&w=900&q=85'),
  ('Indigo Floral Blouse', 'Embroidery', 1700::numeric, 'Indigo floral embroidery with a modern tailored cut', 'https://images.unsplash.com/photo-1610189012906-4c7f1f7e9e0b?auto=format&fit=crop&w=900&q=85'),
  ('Peacock Feather Border', 'Aari Work', 2600::numeric, 'Peacock feather border crafted with fine handwork', 'https://images.unsplash.com/photo-1617331140180-e8262094733c?auto=format&fit=crop&w=900&q=85'),
  ('Saffron Party Blouse', 'Designer Blouse', 1850::numeric, 'Saffron party blouse with a bright contemporary look', 'https://images.unsplash.com/photo-1583391733956-6c78276477e2?auto=format&fit=crop&w=900&q=85'),
  ('Pearl Vine Pattern', 'Pattern Blouse', 1600::numeric, 'Pearl vine pattern with delicate border detailing', 'https://images.unsplash.com/photo-1585488433731-56f5a77e2e0a?auto=format&fit=crop&w=900&q=85'),
  ('Wedding Gold Motif', 'Bridal Blouse', 3250::numeric, 'Wedding gold motif blouse with a luxurious finish', 'https://images.unsplash.com/photo-1605763240000-7e93b172d754?auto=format&fit=crop&w=900&q=85'),
  ('Coral Lotus Embroidery', 'Embroidery', 1750::numeric, 'Coral lotus embroidery with clean handcrafted details', 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=900&q=85'),
  ('Rose Gold Bridal Blouse', 'Bridal Blouse', 2800::numeric, 'Rose gold zardosi work with a classic bridal finish', 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?auto=format&fit=crop&w=900&q=85'),
  ('Temple Motif Blouse', 'Aari Work', 2200::numeric, 'Traditional temple motifs with detailed hand embroidery', 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=900&q=85'),
  ('Peacock Aari Design', 'Aari Work', 2400::numeric, 'Peacock inspired aari embroidery for festive sarees', 'https://images.unsplash.com/photo-1610189012906-4c7f1f7e9e0b?auto=format&fit=crop&w=900&q=85'),
  ('Ruby Bridal Blouse', 'Bridal Blouse', 3200::numeric, 'Rich ruby detailing designed for wedding celebrations', 'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?auto=format&fit=crop&w=900&q=85'),
  ('Mirror Work Blouse', 'Designer Blouse', 1900::numeric, 'Contemporary mirror work with a neat tailored silhouette', 'https://images.unsplash.com/photo-1583391733956-6c78276477e2?auto=format&fit=crop&w=900&q=85'),
  ('Lotus Embroidery', 'Embroidery', 1800::numeric, 'Soft lotus embroidery with delicate thread highlights', 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?auto=format&fit=crop&w=900&q=85'),
  ('Festive Green Blouse', 'Designer Blouse', 2100::numeric, 'Jewel green blouse design for festive styling', 'https://images.unsplash.com/photo-1617331140180-e8262094733c?auto=format&fit=crop&w=900&q=85'),
  ('Gold Leaf Pattern', 'Embroidery', 2300::numeric, 'Gold leaf motifs arranged for an elegant finish', 'https://images.unsplash.com/photo-1585488433731-56f5a77e2e0a?auto=format&fit=crop&w=900&q=85'),
  ('Classic Magenta Blouse', 'Pattern Blouse', 1500::numeric, 'A timeless magenta pattern with a comfortable fit', 'https://images.unsplash.com/photo-1581044777550-4cfa60707c03?auto=format&fit=crop&w=900&q=85'),
  ('Pearl Border Blouse', 'Bridal Blouse', 2600::numeric, 'Pearl border detailing for a refined bridal look', 'https://images.unsplash.com/photo-1605763240000-7e93b172d754?auto=format&fit=crop&w=900&q=85'),
  ('Saree Pink Blouse', 'Pattern Blouse', 1300::numeric, 'Pretty pink blouse with a flattering modern pattern', 'https://images.unsplash.com/photo-1610030469668-8e9c8a3f64f8?auto=format&fit=crop&w=900&q=85'),
  ('Bridal Red Motif', 'Bridal Blouse', 3000::numeric, 'Bridal red with ornate motifs and statement detailing', 'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?auto=format&fit=crop&w=900&q=85'),
  ('Handworked Paisley', 'Aari Work', 2500::numeric, 'Handworked paisley design with dimensional threadwork', 'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?auto=format&fit=crop&w=900&q=85'),
  ('Champa Gold Blouse', 'Embroidery', 2000::numeric, 'Champa inspired gold embroidery for special occasions', 'https://images.unsplash.com/photo-1583391733956-6c78276477e2?auto=format&fit=crop&w=900&q=85'),
  ('Minimal Sequin Blouse', 'Designer Blouse', 1600::numeric, 'Clean silhouette with subtle sequin highlights', 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?auto=format&fit=crop&w=900&q=85'),
  ('Maroon Bridal Work', 'Bridal Blouse', 2900::numeric, 'Deep maroon bridal work with a rich traditional mood', 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=900&q=85'),
  ('Floral Thread Blouse', 'Embroidery', 1750::numeric, 'Colourful floral threadwork made for daytime events', 'https://images.unsplash.com/photo-1610189012906-4c7f1f7e9e0b?auto=format&fit=crop&w=900&q=85'),
  ('Kundan Highlight Blouse', 'Bridal Blouse', 3100::numeric, 'Kundan highlights paired with fine embroidery', 'https://images.unsplash.com/photo-1617331140180-e8262094733c?auto=format&fit=crop&w=900&q=85'),
  ('Peach Pattern Blouse', 'Pattern Blouse', 1400::numeric, 'Soft peach pattern with a polished neckline', 'https://images.unsplash.com/photo-1585488433731-56f5a77e2e0a?auto=format&fit=crop&w=900&q=85'),
  ('Rama Green Embroidery', 'Embroidery', 1850::numeric, 'Rama green embroidery with balanced border work', 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?auto=format&fit=crop&w=900&q=85'),
  ('Velvet Wine Blouse', 'Designer Blouse', 2250::numeric, 'Velvet wine finish with elegant hand details', 'https://images.unsplash.com/photo-1605763240000-7e93b172d754?auto=format&fit=crop&w=900&q=85'),
  ('Traditional Coin Work', 'Aari Work', 2350::numeric, 'Traditional coin work arranged in a graceful pattern', 'https://images.unsplash.com/photo-1610030469668-8e9c8a3f64f8?auto=format&fit=crop&w=900&q=85'),
  ('Ivory Floral Blouse', 'Pattern Blouse', 1550::numeric, 'Ivory floral design with a soft premium finish', 'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?auto=format&fit=crop&w=900&q=85'),
  ('Classic Gold Border', 'Aari Work', 2150::numeric, 'Classic gold border work for silk saree styling', 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?auto=format&fit=crop&w=900&q=85'),
  ('Coral Designer Blouse', 'Designer Blouse', 1650::numeric, 'Coral shade with a confident contemporary pattern', 'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?auto=format&fit=crop&w=900&q=85'),
  ('Bridal Lotus Motif', 'Bridal Blouse', 2750::numeric, 'Lotus motif bridal design with detailed gold work', 'https://images.unsplash.com/photo-1583391733956-6c78276477e2?auto=format&fit=crop&w=900&q=85'),
  ('Turquoise Thread Work', 'Embroidery', 1950::numeric, 'Turquoise thread work for a bright statement blouse', 'https://images.unsplash.com/photo-1617331140180-e8262094733c?auto=format&fit=crop&w=900&q=85'),
  ('Rose Petal Pattern', 'Pattern Blouse', 1450::numeric, 'Rose petal pattern with clean everyday elegance', 'https://images.unsplash.com/photo-1585488433731-56f5a77e2e0a?auto=format&fit=crop&w=900&q=85'),
  ('Antique Gold Aari', 'Aari Work', 2650::numeric, 'Antique gold aari work with a heritage inspired feel', 'https://images.unsplash.com/photo-1610189012906-4c7f1f7e9e0b?auto=format&fit=crop&w=900&q=85'),
  ('Lavender Sequin Blouse', 'Designer Blouse', 1750::numeric, 'Lavender sequin accents with a graceful neckline', 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?auto=format&fit=crop&w=900&q=85'),
  ('Crimson Zari Blouse', 'Bridal Blouse', 3300::numeric, 'Crimson zari detailing made for the bridal trousseau', 'https://images.unsplash.com/photo-1605763240000-7e93b172d754?auto=format&fit=crop&w=900&q=85'),
  ('Daisy Embroidery', 'Embroidery', 1650::numeric, 'Daisy embroidery for a light and cheerful finish', 'https://images.unsplash.com/photo-1610030469668-8e9c8a3f64f8?auto=format&fit=crop&w=900&q=85'),
  ('Mustard Silk Pattern', 'Pattern Blouse', 1350::numeric, 'Mustard silk pattern with a crisp tailored finish', 'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?auto=format&fit=crop&w=900&q=85'),
  ('Royal Blue Bridal', 'Bridal Blouse', 2950::numeric, 'Royal blue bridal style with ornate border detailing', 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?auto=format&fit=crop&w=900&q=85'),
  ('Silver Leaf Work', 'Aari Work', 2450::numeric, 'Silver leaf work for a cool-toned festive look', 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=900&q=85'),
  ('Blush Floral Blouse', 'Designer Blouse', 1800::numeric, 'Blush floral blouse with delicate finish work', 'https://images.unsplash.com/photo-1617331140180-e8262094733c?auto=format&fit=crop&w=900&q=85'),
  ('Green Peacock Blouse', 'Aari Work', 2550::numeric, 'Green peacock work with rich dimensional embroidery', 'https://images.unsplash.com/photo-1583391733956-6c78276477e2?auto=format&fit=crop&w=900&q=85'),
  ('Copper Sequin Pattern', 'Pattern Blouse', 1550::numeric, 'Copper sequin pattern for evening celebrations', 'https://images.unsplash.com/photo-1585488433731-56f5a77e2e0a?auto=format&fit=crop&w=900&q=85'),
  ('Mango Bridal Blouse', 'Bridal Blouse', 2850::numeric, 'Mango shade bridal blouse with intricate motifs', 'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?auto=format&fit=crop&w=900&q=85'),
  ('Pastel Thread Garden', 'Embroidery', 1900::numeric, 'Pastel thread garden design with a soft feminine finish', 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?auto=format&fit=crop&w=900&q=85'),
  ('Black Gold Designer', 'Designer Blouse', 2050::numeric, 'Black and gold designer combination with bold detailing', 'https://images.unsplash.com/photo-1605763240000-7e93b172d754?auto=format&fit=crop&w=900&q=85'),
  ('Temple Border Pattern', 'Pattern Blouse', 1500::numeric, 'Temple border inspired pattern for traditional sarees', 'https://images.unsplash.com/photo-1610030469668-8e9c8a3f64f8?auto=format&fit=crop&w=900&q=85'),
  ('Fuchsia Aari Blouse', 'Aari Work', 2350::numeric, 'Fuchsia aari work with a striking festive presence', 'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?auto=format&fit=crop&w=900&q=85'),
  ('Champagne Bridal Work', 'Bridal Blouse', 3400::numeric, 'Champagne bridal work with refined shimmer and texture', 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?auto=format&fit=crop&w=900&q=85'),
  ('Indigo Floral Blouse', 'Embroidery', 1700::numeric, 'Indigo floral embroidery with a modern tailored cut', 'https://images.unsplash.com/photo-1610189012906-4c7f1f7e9e0b?auto=format&fit=crop&w=900&q=85'),
  ('Peacock Feather Border', 'Aari Work', 2600::numeric, 'Peacock feather border crafted with fine handwork', 'https://images.unsplash.com/photo-1617331140180-e8262094733c?auto=format&fit=crop&w=900&q=85'),
  ('Saffron Party Blouse', 'Designer Blouse', 1850::numeric, 'Saffron party blouse with a bright contemporary look', 'https://images.unsplash.com/photo-1583391733956-6c78276477e2?auto=format&fit=crop&w=900&q=85'),
  ('Pearl Vine Pattern', 'Pattern Blouse', 1600::numeric, 'Pearl vine pattern with delicate border detailing', 'https://images.unsplash.com/photo-1585488433731-56f5a77e2e0a?auto=format&fit=crop&w=900&q=85'),
  ('Wedding Gold Motif', 'Bridal Blouse', 3250::numeric, 'Wedding gold motif blouse with a luxurious finish', 'https://images.unsplash.com/photo-1605763240000-7e93b172d754?auto=format&fit=crop&w=900&q=85'),
  ('Coral Lotus Embroidery', 'Embroidery', 1750::numeric, 'Coral lotus embroidery with clean handcrafted details', 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=900&q=85'),
  ('Rose Gold Bridal Blouse', 'Bridal Blouse', 2800::numeric, 'Rose gold zardosi work with a classic bridal finish', 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?auto=format&fit=crop&w=900&q=85'),
  ('Temple Motif Blouse', 'Aari Work', 2200::numeric, 'Traditional temple motifs with detailed hand embroidery', 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=900&q=85'),
  ('Peacock Aari Design', 'Aari Work', 2400::numeric, 'Peacock inspired aari embroidery for festive sarees', 'https://images.unsplash.com/photo-1610189012906-4c7f1f7e9e0b?auto=format&fit=crop&w=900&q=85'),
  ('Ruby Bridal Blouse', 'Bridal Blouse', 3200::numeric, 'Rich ruby detailing designed for wedding celebrations', 'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?auto=format&fit=crop&w=900&q=85'),
  ('Mirror Work Blouse', 'Designer Blouse', 1900::numeric, 'Contemporary mirror work with a neat tailored silhouette', 'https://images.unsplash.com/photo-1583391733956-6c78276477e2?auto=format&fit=crop&w=900&q=85'),
  ('Lotus Embroidery', 'Embroidery', 1800::numeric, 'Soft lotus embroidery with delicate thread highlights', 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?auto=format&fit=crop&w=900&q=85'),
  ('Festive Green Blouse', 'Designer Blouse', 2100::numeric, 'Jewel green blouse design for festive styling', 'https://images.unsplash.com/photo-1617331140180-e8262094733c?auto=format&fit=crop&w=900&q=85'),
  ('Gold Leaf Pattern', 'Embroidery', 2300::numeric, 'Gold leaf motifs arranged for an elegant finish', 'https://images.unsplash.com/photo-1585488433731-56f5a77e2e0a?auto=format&fit=crop&w=900&q=85'),
  ('Classic Magenta Blouse', 'Pattern Blouse', 1500::numeric, 'A timeless magenta pattern with a comfortable fit', 'https://images.unsplash.com/photo-1581044777550-4cfa60707c03?auto=format&fit=crop&w=900&q=85'),
  ('Pearl Border Blouse', 'Bridal Blouse', 2600::numeric, 'Pearl border detailing for a refined bridal look', 'https://images.unsplash.com/photo-1605763240000-7e93b172d754?auto=format&fit=crop&w=900&q=85'),
  ('Saree Pink Blouse', 'Pattern Blouse', 1300::numeric, 'Pretty pink blouse with a flattering modern pattern', 'https://images.unsplash.com/photo-1610030469668-8e9c8a3f64f8?auto=format&fit=crop&w=900&q=85'),
  ('Bridal Red Motif', 'Bridal Blouse', 3000::numeric, 'Bridal red with ornate motifs and statement detailing', 'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?auto=format&fit=crop&w=900&q=85'),
  ('Handworked Paisley', 'Aari Work', 2500::numeric, 'Handworked paisley design with dimensional threadwork', 'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?auto=format&fit=crop&w=900&q=85'),
  ('Champa Gold Blouse', 'Embroidery', 2000::numeric, 'Champa inspired gold embroidery for special occasions', 'https://images.unsplash.com/photo-1583391733956-6c78276477e2?auto=format&fit=crop&w=900&q=85'),
  ('Minimal Sequin Blouse', 'Designer Blouse', 1600::numeric, 'Clean silhouette with subtle sequin highlights', 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?auto=format&fit=crop&w=900&q=85'),
  ('Maroon Bridal Work', 'Bridal Blouse', 2900::numeric, 'Deep maroon bridal work with a rich traditional mood', 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=900&q=85'),
  ('Floral Thread Blouse', 'Embroidery', 1750::numeric, 'Colourful floral threadwork made for daytime events', 'https://images.unsplash.com/photo-1610189012906-4c7f1f7e9e0b?auto=format&fit=crop&w=900&q=85'),
  ('Kundan Highlight Blouse', 'Bridal Blouse', 3100::numeric, 'Kundan highlights paired with fine embroidery', 'https://images.unsplash.com/photo-1617331140180-e8262094733c?auto=format&fit=crop&w=900&q=85'),
  ('Peach Pattern Blouse', 'Pattern Blouse', 1400::numeric, 'Soft peach pattern with a polished neckline', 'https://images.unsplash.com/photo-1585488433731-56f5a77e2e0a?auto=format&fit=crop&w=900&q=85'),
  ('Rama Green Embroidery', 'Embroidery', 1850::numeric, 'Rama green embroidery with balanced border work', 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?auto=format&fit=crop&w=900&q=85'),
  ('Velvet Wine Blouse', 'Designer Blouse', 2250::numeric, 'Velvet wine finish with elegant hand details', 'https://images.unsplash.com/photo-1605763240000-7e93b172d754?auto=format&fit=crop&w=900&q=85'),
  ('Traditional Coin Work', 'Aari Work', 2350::numeric, 'Traditional coin work arranged in a graceful pattern', 'https://images.unsplash.com/photo-1610030469668-8e9c8a3f64f8?auto=format&fit=crop&w=900&q=85'),
  ('Ivory Floral Blouse', 'Pattern Blouse', 1550::numeric, 'Ivory floral design with a soft premium finish', 'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?auto=format&fit=crop&w=900&q=85'),
  ('Classic Gold Border', 'Aari Work', 2150::numeric, 'Classic gold border work for silk saree styling', 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?auto=format&fit=crop&w=900&q=85'),
  ('Coral Designer Blouse', 'Designer Blouse', 1650::numeric, 'Coral shade with a confident contemporary pattern', 'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?auto=format&fit=crop&w=900&q=85'),
  ('Bridal Lotus Motif', 'Bridal Blouse', 2750::numeric, 'Lotus motif bridal design with detailed gold work', 'https://images.unsplash.com/photo-1583391733956-6c78276477e2?auto=format&fit=crop&w=900&q=85'),
  ('Turquoise Thread Work', 'Embroidery', 1950::numeric, 'Turquoise thread work for a bright statement blouse', 'https://images.unsplash.com/photo-1617331140180-e8262094733c?auto=format&fit=crop&w=900&q=85'),
  ('Rose Petal Pattern', 'Pattern Blouse', 1450::numeric, 'Rose petal pattern with clean everyday elegance', 'https://images.unsplash.com/photo-1585488433731-56f5a77e2e0a?auto=format&fit=crop&w=900&q=85'),
  ('Antique Gold Aari', 'Aari Work', 2650::numeric, 'Antique gold aari work with a heritage inspired feel', 'https://images.unsplash.com/photo-1610189012906-4c7f1f7e9e0b?auto=format&fit=crop&w=900&q=85'),
  ('Lavender Sequin Blouse', 'Designer Blouse', 1750::numeric, 'Lavender sequin accents with a graceful neckline', 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?auto=format&fit=crop&w=900&q=85'),
  ('Crimson Zari Blouse', 'Bridal Blouse', 3300::numeric, 'Crimson zari detailing made for the bridal trousseau', 'https://images.unsplash.com/photo-1605763240000-7e93b172d754?auto=format&fit=crop&w=900&q=85'),
  ('Daisy Embroidery', 'Embroidery', 1650::numeric, 'Daisy embroidery for a light and cheerful finish', 'https://images.unsplash.com/photo-1610030469668-8e9c8a3f64f8?auto=format&fit=crop&w=900&q=85'),
  ('Mustard Silk Pattern', 'Pattern Blouse', 1350::numeric, 'Mustard silk pattern with a crisp tailored finish', 'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?auto=format&fit=crop&w=900&q=85'),
  ('Royal Blue Bridal', 'Bridal Blouse', 2950::numeric, 'Royal blue bridal style with ornate border detailing', 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?auto=format&fit=crop&w=900&q=85'),
  ('Silver Leaf Work', 'Aari Work', 2450::numeric, 'Silver leaf work for a cool-toned festive look', 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=900&q=85'),
  ('Blush Floral Blouse', 'Designer Blouse', 1800::numeric, 'Blush floral blouse with delicate finish work', 'https://images.unsplash.com/photo-1617331140180-e8262094733c?auto=format&fit=crop&w=900&q=85'),
  ('Green Peacock Blouse', 'Aari Work', 2550::numeric, 'Green peacock work with rich dimensional embroidery', 'https://images.unsplash.com/photo-1583391733956-6c78276477e2?auto=format&fit=crop&w=900&q=85'),
  ('Copper Sequin Pattern', 'Pattern Blouse', 1550::numeric, 'Copper sequin pattern for evening celebrations', 'https://images.unsplash.com/photo-1585488433731-56f5a77e2e0a?auto=format&fit=crop&w=900&q=85'),
  ('Mango Bridal Blouse', 'Bridal Blouse', 2850::numeric, 'Mango shade bridal blouse with intricate motifs', 'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?auto=format&fit=crop&w=900&q=85'),
  ('Pastel Thread Garden', 'Embroidery', 1900::numeric, 'Pastel thread garden design with a soft feminine finish', 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?auto=format&fit=crop&w=900&q=85'),
  ('Black Gold Designer', 'Designer Blouse', 2050::numeric, 'Black and gold designer combination with bold detailing', 'https://images.unsplash.com/photo-1605763240000-7e93b172d754?auto=format&fit=crop&w=900&q=85'),
  ('Temple Border Pattern', 'Pattern Blouse', 1500::numeric, 'Temple border inspired pattern for traditional sarees', 'https://images.unsplash.com/photo-1610030469668-8e9c8a3f64f8?auto=format&fit=crop&w=900&q=85'),
  ('Fuchsia Aari Blouse', 'Aari Work', 2350::numeric, 'Fuchsia aari work with a striking festive presence', 'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?auto=format&fit=crop&w=900&q=85'),
  ('Champagne Bridal Work', 'Bridal Blouse', 3400::numeric, 'Champagne bridal work with refined shimmer and texture', 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?auto=format&fit=crop&w=900&q=85'),
  ('Indigo Floral Blouse', 'Embroidery', 1700::numeric, 'Indigo floral embroidery with a modern tailored cut', 'https://images.unsplash.com/photo-1610189012906-4c7f1f7e9e0b?auto=format&fit=crop&w=900&q=85'),
  ('Peacock Feather Border', 'Aari Work', 2600::numeric, 'Peacock feather border crafted with fine handwork', 'https://images.unsplash.com/photo-1617331140180-e8262094733c?auto=format&fit=crop&w=900&q=85'),
  ('Saffron Party Blouse', 'Designer Blouse', 1850::numeric, 'Saffron party blouse with a bright contemporary look', 'https://images.unsplash.com/photo-1583391733956-6c78276477e2?auto=format&fit=crop&w=900&q=85'),
  ('Pearl Vine Pattern', 'Pattern Blouse', 1600::numeric, 'Pearl vine pattern with delicate border detailing', 'https://images.unsplash.com/photo-1585488433731-56f5a77e2e0a?auto=format&fit=crop&w=900&q=85'),
  ('Wedding Gold Motif', 'Bridal Blouse', 3250::numeric, 'Wedding gold motif blouse with a luxurious finish', 'https://images.unsplash.com/photo-1605763240000-7e93b172d754?auto=format&fit=crop&w=900&q=85'),
  ('Coral Lotus Embroidery', 'Embroidery', 1750::numeric, 'Coral lotus embroidery with clean handcrafted details', 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=900&q=85')
) as starter(design_name, category, price, description, image_url)
where not exists (select 1 from gallery where gallery.design_name = starter.design_name);

insert into pricing (service_name, description, price)
select * from (values
  ('Hand Embroidery', 'Custom hand embroidery designs', 0::numeric),
  ('Machine Embroidery', 'Detailed machine embroidery', 0::numeric),
  ('Pattern Blouse', 'Custom pattern blouse stitching', 0::numeric),
  ('Bridal Blouse', 'Made-to-measure bridal blouse design', 0::numeric)
) as starter(service_name, description, price)
where not exists (select 1 from pricing);
*/

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
