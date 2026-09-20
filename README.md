# Rytham Fashions — HTML + CSS + JavaScript + Supabase

Commercial website starter for Rytham Fashions using plain HTML/CSS/JavaScript and Supabase.

## Included
- Responsive public website
- Services, gallery, pricing and reviews loaded from Supabase
- Gallery category and numeric price filtering
- WhatsApp, Instagram, phone and Google Maps settings
- Supabase Auth admin login
- Admin CRUD for gallery, services, pricing and reviews
- Two Storage buckets: `gallery-images` and `service-images`
- Business settings editor
- Enquiries table

## Setup
1. Create or open the Supabase project.
2. In Supabase SQL Editor, run [`supabase.sql`](supabase.sql). It creates all tables, RLS policies, the default settings row, and both public image buckets.
3. In Supabase Authentication, create the owner admin user with email and password. No credentials are stored in this project.
4. Confirm [`js/supabase.js`](js/supabase.js) contains the project URL and publishable/anon key only.
5. Serve this folder with VS Code Live Server or `python -m http.server 5500 --directory Rytham-Fashions`.
6. Open `index.html` for the public site and `admin/index.html` for the dashboard.

## Designs and reviews

The authenticated Admin dashboard manages the `gallery` designs and `reviews` records. Gallery designs support image upload to the public `gallery-images` bucket, category, numeric Indian Rupee pricing, editing, deletion, and WhatsApp enquiry links. Reviews support customer name, 1-5 rating, text, optional customer image, editing, and deletion.

The public Designs section loads records from Supabase, shows eight cards initially, combines category/price/sort filters, and loads eight more matching cards with View More Designs. Apply the current `supabase.sql` setup before using customer-image uploads or the `reviews.updated_at` field.

## Supabase features
- Public reads: business settings, services, gallery, pricing and reviews.
- Public inserts: enquiries only.
- Authenticated admin CRUD: business settings, services, gallery, pricing, reviews and enquiries.
- Storage buckets: `gallery-images` and `service-images`; uploaded images are stored as public URLs in PostgreSQL.
- Gallery price/category filters and sorting run against Supabase-loaded data.

## Important production security
The included authenticated write policies allow any signed-in user to manage content. Before public commercial launch, replace them with policies that verify the owner admin identity or an `app_metadata` role. Never put a Supabase service-role/secret key in browser JavaScript.

## Important content
Phone/WhatsApp and business pricing/reviews should be entered with real information from the owner. Do not publish demo testimonials or placeholder contact numbers.
