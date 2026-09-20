# Rytham Fashions

Responsive boutique website and Supabase-powered admin dashboard for Rytham Fashions, a Poraiyar-based studio offering Aari work, embroidery, designer blouses, tailoring, and custom stitching.

## Features

- Responsive public website for desktop, tablet, and mobile screens.
- Hero section with WhatsApp enquiry action.
- Services, gallery, and customer reviews loaded from Supabase.
- Gallery category, price-range, and price-sorting filters.
- View-more pagination for gallery designs.
- WhatsApp enquiry links for individual designs.
- Contact details, Instagram, address, Google Maps, and opening-hours settings.
- Supabase email/password authentication for the admin dashboard.
- Admin management for gallery designs and customer reviews.
- Gallery image uploads through Supabase Storage.
- Service image uploads supported by the admin data model.
- Customer enquiry records stored in Supabase.

## Technology

- HTML5
- CSS3
- Vanilla JavaScript
- Supabase Database, Auth, and Storage
- Font Awesome icons
- Google Fonts

## Project Structure

```text
Rytham-Fashions/
├── admin/
│   ├── admin.css
│   ├── admin.js
│   └── index.html
├── assets/
├── css/
│   └── style.css
├── js/
│   ├── app.js
│   └── supabase.js
├── index.html
├── supabase.sql
└── README.md
```

## Supabase Setup

1. Create a Supabase project.
2. Open the Supabase SQL Editor.
3. Run [`supabase.sql`](supabase.sql). It creates the application tables, RLS policies, starter data, and storage buckets.
4. In Supabase Authentication, create an admin user with an email address and password.
5. Confirm that [`js/supabase.js`](js/supabase.js) contains only the Supabase project URL and publishable key.
6. Replace the starter contact details and content from the Admin dashboard.

The SQL setup creates these tables:

- `business_settings`
- `services`
- `gallery`
- `pricing`
- `reviews`
- `enquiries`

It also creates the public Storage buckets `gallery-images` and `service-images`.

## Run Locally

The project is a static website and does not require a build step. From the parent directory, run one of these commands:

```bash
python -m http.server 5500 --directory Rytham-Fashions
```

Or open the folder with VS Code and use Live Server.

Then visit:

- Public website: `http://localhost:5500/`
- Admin dashboard: `http://localhost:5500/admin/`

Opening the HTML files directly may prevent some browser features and Supabase requests from working correctly, so use a local web server during development.

## Admin Dashboard

Sign in with the Supabase Auth user created during setup. The dashboard currently provides:

- Gallery design creation, editing, deletion, and image upload.
- Gallery design category, price, and description fields.
- Customer review creation, editing, and deletion.
- Customer name, rating from 1 to 5, and review text fields.
- Link back to the public website.

Reviews do not require an image in the admin form. The database keeps the optional `customer_image` column for compatibility with existing records, but new reviews are managed without image uploads.

## Security Notes

- `js/supabase.js` must contain only a publishable/anon key. Never expose a Supabase service-role or secret key in browser code.
- The included authenticated policies allow any authenticated Supabase user to manage content. Before a commercial launch, restrict write policies to the owner account or an approved admin role.
- Replace starter contact details, sample services, and pricing before publishing.
- Review and remove any demo or placeholder content before launch.

## Deployment

Deploy the `Rytham-Fashions` folder to any static hosting provider, such as GitHub Pages, Netlify, or Vercel static hosting. Configure the deployed site URL in Supabase Authentication if email authentication redirects require it.

## Repository

The project is hosted at [RavikumarSaravanan/Rytham-Fashions](https://github.com/RavikumarSaravanan/Rytham-Fashions).
