# Supabase: Auth، پایگاه داده و مهاجرت‌ها

## وضعیت فعلی

کد فروشگاه دیگر provider محلی یا snapshot مرورگر برای داده‌های فروشگاهی ندارد. `services/data-provider.js` فقط پس از اتصال Auth و پاسخ موفق `commerce_health` با نسخهٔ schema `202610030001` دادهٔ Supabase را hydrate می‌کند؛ در نبود تنظیمات، خطای اتصال یا schema قدیمی، برنامه fail-closed است و به Demo/LocalStorage برنمی‌گردد.

۱۳ migration مربوط به schema و تجارت (از جمله نسخهٔ نهایی BitPay-only و حذف RPCهای بازنشستهٔ BluPal) روی پروژهٔ Supabase `hermes-collection-` با ref `rqdwqrmjwzlpgrxizggw` اعمال و در تاریخچهٔ migration ثبت شدند. بررسی پس از اجرا: ۲۰ جدول عمومی، همگی با RLS فعال؛ `commerce_health()` سالم؛ bucket عمومی `product-images` با محدودیت JPEG/PNG/WebP و سقف ۵ MiB؛ وضعیت Auth، DB، REST و Storage همگی `ACTIVE_HEALTHY`. هیچ محصول، دسته، variant، کوپن، بنر، سفارش یا پرداخت آزمایشی ایجاد نشد؛ کاتالوگ عمداً خالی است. ۹ تنظیم پایهٔ فروشگاه ایجاد و نام/متن‌های پیش‌فرض به Hermes Collection اصلاح شدند.

فایل‌های migration با versionهای ثبت‌شدهٔ remote هم‌تراز شده‌اند تا `supabase db push` همان migrationها را دوباره اجرا نکند. هیچ مقدار credential یا کلید پذیرنده در کد/این مستندات قرار نمی‌گیرد. اجرای واقعی گردش ثبت‌نام ایمیلی، سفارش و پرداخت هنوز انجام نشده: SMTP سفارشی Supabase تنظیم نیست، کلیدهای runtime محلی در preview در دسترس نیستند، و برای آزمون پرداخت باید حساب/محصول واقعی و کلید BitPay فراهم باشد.

## تنظیم Auth ایمیل/رمز

در Vercel → Project → Settings → Environment Variables برای محیط‌های موردنیاز تنظیم کنید:

- `SUPABASE_URL` — Project URL.
- `SUPABASE_PUBLISHABLE_KEY` — public/publishable key؛ اگر پروژه فقط کلید legacy را دارد از `SUPABASE_ANON_KEY` استفاده کنید.

این‌ها تنها مقدارهای Supabase هستند که به کلاینت مرورگر می‌رسند. `SUPABASE_SERVICE_ROLE_KEY`، رمز دیتابیس، GitHub token و کلید API بیت‌پی (`BITPAY_API_KEY`) را هرگز در Browser یا Git قرار ندهید. پس از تغییر Environment Variables، deployment را دوباره بسازید.

در Supabase → Authentication، Email provider فعال است، ثبت‌نام باز است و email confirmation لازم است. Site URL روی `https://toubashose.ir` قرار دارد و allow-list فعلی شامل مسیرهای تأیید/بازیابی همین دامنه و `http://localhost:3000` برای توسعه است. اگر دامنهٔ production عوض شد، هر دو مورد را به‌روز کنید.

حداقل طول و سیاست password را در Supabase مطابق الزامات حساب تنظیم کنید (فرم سایت حداقل ۱۲ نویسه می‌خواهد). SMTP اختصاصی هنوز پیکربندی نشده است؛ تا زمانی که SMTP دامنهٔ تأییدشده تنظیم و با چند mailbox واقعی آزمایش نشود، تحویل ایمیل تأیید/بازیابی در Production تأییدشده نیست.

متغیرهای Production در Vercel از این workspace قابل مشاهده نیستند. در preview محلی، `/api/supabase-config` با وضعیت `configured=false` و `enabled=false` پاسخ داد، چون فایل `.env` محلی موجود نیست؛ این نتیجه دربارهٔ متغیرهای ذخیره‌شده در Vercel چیزی ثابت نمی‌کند. پس از واردکردن Environment Variables، deployment را دوباره بسازید و وضعیت config را بدون چاپ کلیدها بررسی کنید.

Trigger اولیه، `profiles` را با role پیش‌فرض `customer` می‌سازد. ثبت‌نام مرورگر نقشی بالاتر نمی‌پذیرد؛ role و active بودن از profile و policy/RPCهای DB خوانده می‌شود. برای ساخت اولین مدیر، پس از ثبت‌نام و تأیید حساب مالک، ایمیل دقیق Auth user را بررسی کنید و فقط از SQL Editor مورداعتماد اجرا کنید:

```sql
update public.profiles p
set role = 'super_admin'
from auth.users u
where p.id = u.id
  and lower(u.email) = lower('OWNER_EMAIL_HERE');
```

جایگزین را در همان SQL Editor با ایمیل دقیق عوض کنید؛ آن را در کد یا endpoint عمومی قرار ندهید. تعداد ردیف‌های متأثر و `profiles.role` را بعد از اجرا بررسی کنید. هیچ مسیر promote-role در UI عمومی وجود ندارد.

## Migrationها

فایل‌های SQL در `supabase/migrations/` به ترتیب version واقعی Supabase قرار دارند؛ suffix هر نام، شناسهٔ منطقی اصلی migration را نگه می‌دارد. این prefixها با تاریخچهٔ ثبت‌شدهٔ پروژه هم‌تراز شده‌اند. Migrationهای قبلاً اجراشده را ویرایش نکنید؛ تغییر تازه را با timestamp جدید اضافه کنید.

`20261025222644_202610030001_live_commerce.sql` پس از migrationهای پایه:

- فقط داده‌های شناخته‌شدهٔ seed قدیمی کاتالوگ/کوپن/بنر را پاک می‌کند؛ حساب واقعی، سفارش نامرتبط یا ردیف ناشناخته را حذف نمی‌کند. migration seed قدیمی اکنون عمداً no-op است و محصول آزمایشی درج نمی‌کند.
- `commerce_health()` و نسخهٔ پایهٔ schema را اعلام می‌کند.
- write مستقیم مرورگر برای cart/order/payment را می‌بندد و RPCهای کنترل‌شده برای cart، کوپن، ساخت سفارش/رزرو موجودی و وضعیت سفارش فراهم می‌کند.
- Storage bucket عمومی `product-images` و policyهای آن در migration پایه ساخته شده‌اند؛ upload و delete نیازمند مدیر فعال و policyهای RLS/storage هستند.

`20261025222854_202610260001_hermes_collection_defaults.sql` فقط مقادیر default قدیمی و دست‌نخوردهٔ برند را به Hermes Collection تغییر می‌دهد و تنظیماتی را که قبلاً سفارشی شده باشند بازنویسی نمی‌کند.

`20261025223509_202610260002_drop_retired_blupal_rpcs.sql` RPCهای دیتابیسی درگاه بازنشستهٔ BluPal را حذف می‌کند؛ نام providerهای قدیمی فقط برای سازگاری با تاریخچهٔ پرداخت در constraint باقی می‌ماند، در حالی‌که trigger فقط BitPay را برای درج/به‌روزرسانی می‌پذیرد.

Workflow فایل `.github/workflows/supabase-db-push.yml` روی push به `main` که migrationها را تغییر دهد اجرا می‌شود. برای اجرای دستی به Actions Secrets زیر نیاز است:

- `SUPABASE_ACCESS_TOKEN`
- `SUPABASE_PROJECT_REF`
- `SUPABASE_DB_PASSWORD`

Workflow قبل از apply، `supabase db push --dry-run` اجرا می‌کند و فقط برای دستی بودن به ورودی `confirm=true` نیاز دارد. Versionهای local اکنون با رکوردهای remote هم‌خوان هستند؛ پس از push، خروجی dry-run را بررسی کنید و نباید migrationهای از قبل اجراشده را pending اعلام کند. push این شاخه به‌تنهایی Workflowای که فقط روی `main` تعریف شده را فعال نمی‌کند.

## بررسی پس از migration

بررسی read-only روی پروژهٔ واقعی انجام شد:

- `commerce_health()` مقدار `schemaVersion = 202610030001` و `orders/payments/products = true` برگرداند.
- هر ۲۰ جدول عمومی `relrowsecurity = true` دارند.
- شمار ردیف‌های catalog (`categories`, `products`, `variants`, `product_images`, `coupons`, `banners`) همگی صفر است؛ `orders` و `payments` نیز صفرند. ۹ ردیف تنظیم پایه وجود دارد و متن‌های برند «کالکشن هرمس» است.
- bucket `product-images` عمومی است، سقف هر فایل ۵ MiB دارد و JPEG/PNG/WebP را می‌پذیرد؛ چهار policy دانلود عمومی/نوشتن مدیر فعال‌اند.
- RPCهای سفارش، سبد، BitPay، سهمیهٔ تصویر و مدیریت تماس در DB موجودند و با `SECURITY DEFINER` و `search_path` خالی تعریف شده‌اند.
- Auth، DB، REST و Storage همگی `ACTIVE_HEALTHY` گزارش شدند.
- `npm test` و `npm run build` موفق شدند.

تست E2E ثبت‌نام، آپلود، ساخت/لغو سفارش یا پرداخت انجام نشد؛ برای حفظ production، کاربر/محصول/سفارش آزمایشی ایجاد نکردیم. تست‌های repository در این پروژه Supabase را با stub شبیه‌سازی می‌کنند و جایگزین آزمون E2E نیستند.

## بیت‌پی (BitPay · bitpay.ir — پرداخت مستقیم بانکی)

`supabase/migrations/20261025222821_202610170001_bitpay_gateway.sql` قید `provider` را گسترش می‌دهد و
چهار RPC امن می‌سازد؛ `supabase/migrations/20261025222849_202610200001_bitpay_only.sql` بیت‌پی را تنها
درگاه قابل‌نوشت می‌کند و سفارشات تازه را مستقیم با `provider = 'bitpay'` می‌سازد:

- `attach_bitpay_payment(p_order_id, p_id_get, p_amount_rial, p_factor_id)` — فقط `service_role`؛ شناسهٔ درگاه و مبلغ ریالی را روی ردیف `pending` می‌گذارد و provider را یک‌بار به `bitpay` می‌چرخاند. ساخت دوباره مجاز است (تلاش‌های قبلی در `callback_payload.attempts` می‌ماند).
- `record_bitpay_trans_id(p_order_id, p_id_get, p_trans_id)` — فقط `service_role`؛ `trans_id` بانک را یک‌بار ثبت می‌کند تا سوءاستفاده نشود (سرنخ، نه مدرک پرداخت).
- `settle_bitpay_payment(...)` — تنها راه `verified` شدن؛ فقط نتیجهٔ `gateway-result-second` (وضعیت ۱ یا ۱۱) با تطبیق مبلغ و `id_get`، موجودی سبد را کم و سفارش را `paid` می‌کند.
- `expire_stale_bitpay_checkouts(p_grace_minutes default 60)` — چک‌اوت‌های رهاشده را بعد از مهلت با بازگرداندن رزرو موجودی و ظرفیت کوپن می‌بندد.

`payments.authority` شناسهٔ `id_get` درگاه است (عددی و کوتاه)؛ الگوی اعتبارسنجی در SQL و
در `lib/supabase-server.js` روی همین اساس شل شده است.

همراه آن: `create_order_with_payment` (کف مبلغ ۵۰۰ تومان = حداقل مبلغ درگاه، رزرو اتمیک
موجودی، `provider = 'bitpay'`)، `cancel_pending_order` و `admin_update_order_status` که
`PAID` را فقط برای پرداخت `verified` می‌پذیرد.

هنگام اجرای migration چک‌اوت‌های `pending` درگاه بازنشسته بسته می‌شوند (رزرو موجودی و
سهم کد تخفیف آزاد، سفارش `cancelled`، `provider_code = 'GATEWAY_RETIRED'`). ردیف‌های
تأییدشدهٔ قدیمی حذف یا بازنویسی **نمی‌شوند**: قید `CHECK` نام همان درگاه‌ها را برای
تاریخچه می‌پذیرد و تریگر `payments_enforce_bitpay_provider` ثبت پرداخت تازه با هر
مقدار دیگری را رد می‌کند.

متغیرهای لازم سمت سرور (هیچ‌کدام در SQL نیستند):

- `BITPAY_API_KEY` — کلید ۵۲ کاراکتری «بخش توسعه ← فعال‌سازی API» پنل بیت‌پی؛ فقط سمت سرور

ست آزمون‌های `npm test` پاسخ‌های درگاه را با stub جایگزین می‌کند؛ برای go-live باید اجرای
migration، یک چرخهٔ کامل آزمایشی (ساخت تراکنش ← پرداخت در صفحهٔ بانک ← بازگشت ←
تسویهٔ سرور) و سپس یک تراکنش واقعی کوچک روی دامنهٔ production انجام شود.
