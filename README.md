# Atlas Wear — shop files for GitHub Pages + Supabase

This folder contains the storefront (`index.html`), public browser configuration (`config.js`), and the Supabase database/storage setup (`supabase-setup.sql`). Customers can browse and request an order through WhatsApp. The owner signs in to the protected **Espace propriétaire** panel to edit products, photos, prices, shop name, and WhatsApp contact.

The included sample products, name, and prices are placeholders. Replace them before the shop is announced. A WhatsApp number must be configured in the owner dashboard before customers can send an order.

## Security notes

- The Supabase **anon/publishable key** is designed to be used in browser code; the SQL enables row-level security and restricts all writes to owner IDs in `shop_admins`.
- Never put a Supabase `service_role` / secret key in `config.js` or a public GitHub repository.
- Public signup should be disabled. Create the owner's Supabase Auth account yourself, then add that account's UUID to `shop_admins` using the SQL Editor.
- Product images are publicly viewable (they are storefront images); upload/change/delete is owner-only.
- Customer order details are placed into the WhatsApp message. This prototype does not store customer orders in the database.

## Setup outline (we will do this one step at a time)

1. Create a Supabase project: <https://supabase.com/dashboard>.
2. In **SQL Editor**, run all of `supabase-setup.sql`.
3. In **Authentication → Users**, create the owner's login. Disable public signups in the Auth settings.
4. Copy the owner's user UUID and run this in the SQL Editor, replacing the placeholder with that UUID:

   ```sql
   insert into public.shop_admins (user_id)
   values ('PASTE-OWNER-USER-UUID-HERE')
   on conflict (user_id) do nothing;
   ```

5. In Project Settings → API, copy the Project URL and the publishable/anon key into `config.js`. Do not use the secret/service-role key.
6. Test the site and the owner dashboard. Add the actual shop name, WhatsApp number, real products, prices, sizes, and photos.
7. Upload the project files to a public GitHub repository and enable **Settings → Pages → Deploy from a branch → `main` / `/(root)`**.
8. Test the public link from another phone/browser: customer can only browse and request an order; the owner can sign in and make changes that appear for everyone.

## Local preview

Open `index.html` in a browser for the visual preview. With placeholder config values, it shows sample products in read-only demo mode; authentication and saving are unavailable until Supabase is configured. Product images require internet access.
