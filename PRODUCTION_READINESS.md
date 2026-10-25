# گزارش آمادگی انتشار — HERMES COLLECTION

**آخرین بررسی:** 2026-10-26
**پروژهٔ Supabase:** `hermes-collection-` (`rqdwqrmjwzlpgrxizggw`)
**وضعیت:** schema واقعی اعمال و بررسی شده؛ فروشگاه هنوز برای پذیرش سفارش/پرداخت Production-ready نیست.

## آنچه روی Supabase اعمال و تأیید شد

- ۱۳ migration در تاریخچهٔ پروژه ثبت شد؛ از جمله schema/RLS، commerce RPCها، سهمیهٔ تولید تصویر، BitPay-only، تنظیمات پیش‌فرض Hermes Collection و حذف RPCهای BluPal بازنشسته. Prefix فایل‌های محلی با versionهای remote هم‌تراز شده تا workflow آینده migrationها را دوباره اجرا نکند.
- `commerce_health()` مقدار `schemaVersion = 202610030001` و `orders = payments = products = true` برمی‌گرداند.
- ۲۰ جدول عمومی وجود دارد و RLS روی هر ۲۰ جدول فعال است.
- هیچ دسته، محصول، variant، تصویر، کوپن، بنر، سفارش یا پرداخت آزمایشی درج نشد. کاتالوگ عمداً خالی است؛ ۹ تنظیم پایهٔ فروشگاه وجود دارد و نام/متن‌های پیش‌فرض با برند «کالکشن هرمس» هماهنگ‌اند.
- Storage bucket عمومی `product-images` حاضر است: JPEG/PNG/WebP، سقف ۵ MiB؛ policy دانلود عمومی و upload/update/delete مدیر فعال دارد.
- RPCهای سفارش، سبد، کوپن، BitPay، سهمیهٔ تصویر و مدیریت پیام تماس در DB هستند؛ توابع حساس `SECURITY DEFINER` و `search_path` خالی دارند.
- سرویس‌های Auth، DB، REST و Storage همگی `ACTIVE_HEALTHY` گزارش شدند.
- `npm test` و `npm run build` هر دو موفق‌اند. این تست‌های محلی/stub به‌تنهایی آزمون end-to-end روی سرویس واقعی نیستند.

## تنظیم Auth فعلی و محدودیت‌های باقیمانده

- Email provider فعال، ثبت‌نام باز، تأیید ایمیل الزامی و SMS غیرفعال است.
- در Supabase Authentication → **URL Configuration**، Site URL روی `https://hermes-collection.vercel.app` تنظیم شده؛ allow-list شامل `https://hermes-collection.vercel.app/login?verified=1`, `https://hermes-collection.vercel.app/reset-password`, `http://localhost:3000/login?verified=1` و `http://localhost:3000/reset-password` است.
- SMTP اختصاصی Supabase تنظیم/آزمایش نشده است؛ تحویل ایمیل تأیید و بازیابی در Production هنوز تأییدشده نیست. سیاست طول رمز Supabase را نیز با نیاز سایت (حداقل ۱۲ نویسه در فرم) هماهنگ کنید.
- متغیرهای محیطی Production در Vercel از این workspace قابل مشاهده نیستند. Preview محلی `/api/supabase-config` با `configured=false` و `enabled=false` پاسخ می‌دهد، چون فایل `.env` محلی در دسترس نیست. این پاسخ وضعیت Vercel را مشخص نمی‌کند؛ پس از تنظیم متغیرها Vercel باید redeploy شود.
- migrationها هیچ حساب مدیر یا محصولی ایجاد نمی‌کنند. پس از ثبت‌نام و تأیید حساب مالک، نقش مدیر را فقط از مسیر امن Supabase مطابق راهنمای `supabase/README.md` تنظیم کنید.

## دامنه و نمادهای اعتماد

دامنهٔ فعلی Production برای کالکشن هرمس `https://hermes-collection.vercel.app` است؛ دامنهٔ اختصاصی هنوز ثبت نشده. Site URL/redirectهای Auth، canonicalها، sitemap و BitPay باید فقط به همین دامنهٔ متعلق به Hermes اشاره کنند. اگر بعداً دامنهٔ اختصاصی اضافه شد، همهٔ این تنظیمات را هم‌زمان به دامنهٔ جدید منتقل کنید.

نمادهای اعتماد تا وقتی شناسه و گواهیِ تأییدشدهٔ متعلق به خود کالکشن هرمس وارد نشده باشد نمایش داده نمی‌شوند. لینک گواهی BitPay قبلی به دامنهٔ دیگری اشاره می‌کرد و مقدارهای ثابت Enamad برای این فروشگاه تأیید نشده بودند؛ بنابراین از UI حذف/پنهان شدند. پس از دریافت مدارک واقعی، دامنهٔ ثبت‌شده در هر پنل را با دامنهٔ سایت تطبیق دهید؛ اینماد فقط از تنظیمات مدیر و با جفت `id`/`Code` متعلق به همین فروشگاه نمایش داده می‌شود.

## کارهای لازم پیش از Production

1. **Runtime secrets:** در Vercel برای محیط Production `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` (یا `SUPABASE_ANON_KEY`) و رازهای لازم سمت سرور را تنظیم کنید. `SUPABASE_SERVICE_ROLE_KEY`, رمز DB و `BITPAY_API_KEY` هرگز نباید به مرورگر یا Git برسند. redeploy کنید و فقط flagهای endpoint پیکربندی را بررسی کنید؛ مقدار کلیدها را چاپ نکنید.
2. **Auth/ایمیل:** SMTP معتبر دامنه را تنظیم و آزمون کنید: signup، تأیید ایمیل، ورود، فراموشی/بازیابی رمز و مسیرهای بازگشت. اگر دامنه عوض شد، Site URL و allow-list را هم به‌روز کنید.
3. **مدیر و دادهٔ واقعی:** حساب مالک را ایجاد و پس از تأیید، role را از SQL Editor مورداعتماد به `super_admin` ارتقا دهید. سپس دسته، محصول، variant/موجودی، تصاویر، قیمت، هزینهٔ ارسال و اطلاعات تماس واقعی را از پنل ثبت و پس از refresh بررسی کنید. هیچ دادهٔ ساختگی تولید نکنید.
4. **Storage:** با حساب مدیر واقعی upload/download/delete در bucket `product-images` را بررسی کنید؛ تأیید کنید کاربر ناشناس نمی‌تواند upload یا delete کند و فرمت/حجم نامعتبر رد می‌شود.
5. **سفارش بدون پرداخت:** با حساب مشتری و محصول واقعی، سفارش را بسازید؛ `cancel_pending_order` و انقضای سفارش را بررسی کنید؛ موجودی و ظرفیت کوپن باید دقیقاً یک بار آزاد شوند. هم‌زمانی دو checkout را آزمایش کنید تا stock منفی نشود.
6. **پرداخت BitPay:** migration نهایی `20261025222849_202610200001_bitpay_only.sql` بیت‌پی را تنها درگاه قابل‌نوشت می‌کند. دامنهٔ فعلی `https://hermes-collection.vercel.app` است؛ پیش از افزودن کلید، مطمئن شوید BitPay این دامنه را برای پذیرندهٔ خود تأیید می‌کند. اگر BitPay به دامنهٔ اختصاصی نیاز دارد، پرداخت واقعی را تا تهیه/ثبت آن فعال نکنید. کلید پذیرنده را فقط سمت سرور بگذارید و `BITPAY_SITE_ORIGIN` را با دامنهٔ تأییدشده هماهنگ کنید. یک چرخهٔ کم‌مبلغ در محیط مجاز اجرا کنید: ساخت تراکنش → صفحهٔ بانک → بازگشت → استعلام سروربه‌سرور `gateway-result-second` → verified شدن سفارش. بازگشت مرورگر به‌تنهایی نباید پرداخت را تأیید کند. یک تلاش ناموفق/منقضی را هم بررسی کنید.
7. **عملیات و محتوا:** قوانین بازگشت/حریم خصوصی، قیمت/موجودی، مالیات/ارز، مجوز تصاویر، backup/restore و alertها را مالک فروشگاه تأیید کند. مرورگرهای واقعی دسکتاپ/iOS/Android، RTL، دسترس‌پذیری و پنل موبایل را دستی بررسی کنید.
8. **Migration pipeline:** GitHub Actions به secrets `SUPABASE_ACCESS_TOKEN`, `SUPABASE_PROJECT_REF`, `SUPABASE_DB_PASSWORD` نیاز دارد. پس از merge به `main`، خروجی `supabase db push --dry-run` را ببینید؛ نباید ۱۳ migration اعمال‌شده را دوباره pending نشان دهد. برای اجرای دستی `confirm=true` لازم است.

## بررسی فنی فعلی

- تست‌ها: `npm test`
- build و asset check: `npm run build`
- `commerce_health()` نسخهٔ برنامه را از `202610030001` می‌خواند؛ migrations بعدی commerce/provider را تکمیل می‌کنند و مقدار version این RPC عمداً همان schema baseline می‌ماند.
- گزارش کامل RLS، Storage، Auth و migrationها در [`supabase/README.md`](supabase/README.md) ثبت شده است.
- پوشهٔ `supabase/migrations/` نسخهٔ منبع migrationهاست. Migration اعمال‌شده را ویرایش نکنید؛ تغییر تازه را با timestamp جدید اضافه و پس از آن history remote را بررسی کنید.

> **نتیجه:** لایهٔ دیتابیس Supabase ساخته و بررسی شد، اما تا زمان تأیید Vercel env، SMTP، حساب مدیر، دادهٔ واقعی و آزمون E2E BitPay، سفارش/پرداخت Production را فعال نکنید.
