-- Align safe, untouched storefront defaults with the Hermes Collection brand.
-- Exact-value guards preserve any settings a store admin has already customized.

update public.site_settings
set value = '"کالکشن هرمس"'::jsonb
where key = 'storeName'
  and value = '"کفش طوبی"'::jsonb;

update public.site_settings
set value = jsonb_set(
  jsonb_set(value, '{heroTitle}', to_jsonb('قدم‌هایی مطمئن با کالکشن هرمس'::text), true),
  '{footerText}', to_jsonb('تمامی حقوق برای کالکشن هرمس محفوظ است.'::text), true
)
where key = 'homepage'
  and value->>'heroTitle' = 'قدم‌هایی مطمئن با کفش طوبی';

update public.site_settings
set value = '"خرید آنلاین کفش کالکشن هرمس"'::jsonb
where key = 'metaDescription'
  and value = '"خرید آنلاین کفش طوبی"'::jsonb;
