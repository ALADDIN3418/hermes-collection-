# HERMES COLLECTION — کالکشن فارسی RTL کیف و کفش با Supabase

فروشگاه فارسی RTL و پنل مدیریت با احراز هویت Supabase، کاتالوگ و تنظیمات پایدار در PostgreSQL، سبد خرید و عملیات سفارش متکی به RPCهای امن، و ذخیرهٔ تصویر محصول در Supabase Storage. هیچ کاتالوگ، سفارش، کاربر، آمار یا تنظیم فروشگاهی از Demo/LocalStorage بارگذاری نمی‌شود؛ در نبود اتصال معتبر یا migration هماهنگ، برنامه عمداً fail-closed است و صفحهٔ خطای اتصال نشان می‌دهد.

## اجرا و بررسی محلی

- نیازمندی: Node.js 22+.
- نصب وابستگی‌ها: `npm install`.
- اجرای سرور: `npm start` (روی `0.0.0.0` و پورت `PORT` یا 3000؛ پیش‌فرض این شاخه 3000 است).
- آزمون: `npm test`.
- Build: `npm run build`؛ خروجی وب و Supabase browser SDK در `public/` ساخته می‌شود.
- سرور محلی بدون کلید عمومی Supabase، دیتای ساختگی نمایش نمی‌دهد. برای تجربهٔ فروشگاه باید `SUPABASE_URL` و `SUPABASE_PUBLISHABLE_KEY` یا `SUPABASE_ANON_KEY` را در `.env` محلی یا Environment Variables سرور تنظیم کنید.

## اتصال Supabase

در Environment Variables محیط Vercel:

- `SUPABASE_URL`: URL پروژه.
- `SUPABASE_PUBLISHABLE_KEY`: کلید عمومی/publishable؛ در پروژه‌های قدیمی `SUPABASE_ANON_KEY` قابل استفاده است.

این مقادیر عمومی‌اند و برای Auth مرورگر استفاده می‌شوند. هرگز `SUPABASE_SERVICE_ROLE_KEY`، رمز دیتابیس، GitHub Actions token یا credential پرداخت را به مرورگر ندهید.

در پروژهٔ Supabase متصل، Email provider فعال است، تأیید ایمیل لازم است و Site URL روی `https://hermes-collection.vercel.app` است؛ redirectهای تأیید/بازیابی همین دامنه و `http://localhost:3000` تنظیم شده‌اند. SMTP اختصاصی هنوز پیکربندی/آزمایش نشده؛ برای تحویل مطمئن ایمیل تأیید و بازیابی در Production باید SMTP دامنهٔ تأییدشده راه‌اندازی شود. ثبت‌نام عمومی فقط حساب `customer` می‌سازد؛ نقش مدیر باید از مسیر مورداعتماد مالک در Supabase به‌روزرسانی شود.

Migrationهای schema روی پروژهٔ واقعی Supabase با ref `rqdwqrmjwzlpgrxizggw` اعمال و بررسی شده‌اند: ۲۰ جدول عمومی با RLS فعال، RPC سلامت و سفارش، درگاه نهایی BitPay-only، و bucket تصویر آماده‌اند. کاتالوگ آزمایش/محصول خالی مانده و تنظیمات پیش‌فرض با برند Hermes Collection هم‌خوان شده‌اند. در preview محلی `/api/supabase-config` هنوز `configured=false`/`enabled=false` است چون env محلی وجود ندارد؛ این بررسی متغیرهای Vercel را نمی‌بیند، بنابراین پس از تغییر Environment Variables باید Production redeploy و config را بدون نمایش کلیدها بررسی کنید.

### Migrationهای پایگاه داده

Migrationهای نسخه‌بندی‌شده در `supabase/migrations/` هستند؛ prefixها با versionهای remote ثبت‌شده هماهنگ شده‌اند. `20261025222644_202610030001_live_commerce.sql` RPCهای سلامت schema، سبد خرید و ثبت اتمیک سفارش/رزرو موجودی را فراهم می‌کند. migration seed قدیمی عمداً no-op است تا کاتالوگ آزمایشی درج نشود؛ درگاه BitPay در migrationهای بعدی تنها درگاه قابل‌نوشت باقی می‌ماند (`provider = 'bitpay'`, RPCهای `attach_/settle_/record_/expire_stale_bitpay_*`, کف سفارش ۵۰۰ تومان). همهٔ این migrations روی پروژهٔ واقعی Supabase اعمال و بررسی شده‌اند؛ `commerce_health()` نسخهٔ پایهٔ `202610030001` را می‌دهد و app در نبود runtime config همچنان fail-closed می‌ماند.

GitHub Actions برای migrationهای جدید روی `main` اجرا می‌شود؛ اجرای دستی نیازمند تأیید ورودی `confirm` است. Secrets لازم: `SUPABASE_ACCESS_TOKEN`، `SUPABASE_PROJECT_REF` و `SUPABASE_DB_PASSWORD`. `supabase db push --dry-run` را بررسی کنید؛ فایل‌های فعلی با history remote هم‌ترازند و نباید دوباره pending شوند. در صورت drift جدید، پیش از اجرای مجدد migration وضعیت و history را جداگانه بررسی کنید.

جزئیات و مسیر راه‌اندازی در [`supabase/README.md`](supabase/README.md) آمده است.

## داده، کاتالوگ و پنل

- `services/data-provider.js` فقط state اولیهٔ خالی می‌سازد و داده را از `repositories/supabase-repository.js` می‌گیرد؛ persistence کل state در مرورگر عمداً خاموش است.
- محصول، دسته، کوپن، تنظیمات، بنر، محتوا، نظر، پیام تماس، مشتری و آمار از ردیف‌های پایگاه داده و RLS خوانده می‌شوند. آمار فروش فقط از سفارش‌هایی محاسبه می‌شود که پرداخت آن‌ها تأیید شده است.
- سبد مشتری از RPC امن ثبت می‌شود؛ سفارش، مبلغ authoritative، تخفیف، shipping و رزرو موجودی در `create_order_with_payment` اعتبارسنجی می‌شوند. مرورگر اجازهٔ درج مستقیم سفارش یا تغییر وضعیت پرداخت ندارد.
- فایل‌های تصویر انتخابی/تولیدشده به bucket عمومی `product-images` در Supabase Storage می‌روند و اطلاعات رسانه در جدول DB نگهداری می‌شود. آدرس بیرونی فقط HTTPS پذیرفته می‌شود.
- پنل مدیریت در موبایل ناوبری کشویی و جدول‌های افقیِ محدودشده دارد؛ storefront نوار پایین و نوار خرید موبایل را جداگانه ارائه می‌کند.

## Checkout و بیت‌پی (BitPay · bitpay.ir — پرداخت مستقیم بانکی)

درگاه‌های قبلی به‌طور کامل حذف شده‌اند و **بیت‌پی** تنها درگاه فعال است: پرداخت
مستقیم به صفحهٔ بانک. Checkout فقط برای حساب فعال مشتری است؛ سفارش به‌صورت تراکنشی در
Supabase ساخته می‌شود، سپس `/api/payment/bitpay/request` مبلغ authoritative را از همان
رکورد سفارش می‌خواند، به **ریال** تبدیل می‌کند و با `POST /payment/gateway-send` (مرچنت‌کد
درگاه) شناسهٔ `id_get` می‌گیرد. مرورگر به نشانی `gateway-<id_get>-get` هدایت می‌شود و
پرداخت را در صفحهٔ رسمی بانک انجام می‌دهد؛ بانک مشتری را با `trans_id` و `id_get` به
مسیر بازگشت فروشگاه می‌فرستد. بازگشت مشتری هرگز مبنای تأیید نیست: تسویه فقط با
`POST /payment/gateway-result-second` روی سرور (وضعیت ۱ یا ۱۱) و با تطبیق مبلغ با
سفارش انجام می‌شود. مسیر `/api/payment/bitpay/callback` مشتری را به
`/payment/result/<uuid>` می‌فرستد و صفحهٔ نتیجه وضعیت را از سرور استعلام می‌کند.
شماره کارت و رمز بانکی مشتری هرگز از سایت عبور نمی‌کند و هیچ SDK بیرونی در صفحه
بارگذاری نمی‌شود.

حد مبلغ هر تراکنش (مستندات درگاه): از **۵٬۰۰۰ ریال** (۵۰۰ تومان) به بالا؛ کف سفارش
در `create_order_with_payment` هم روی همین مقدار تنظیم شده است.

تنظیم فقط سمت سرور (Vercel Environment Variables یا `.env` خارج از Git):

- `BITPAY_API_KEY`: کلید ۵۲ کاراکتری «بخش توسعه ← فعال‌سازی API» پنل بیت‌پی (مرچنت‌کد درگاه)؛ هرگز در مرورگر یا Git قرار ندهید. مقدار خالی = پرداخت خاموش (fail-closed).
- دامنهٔ دقیق سایت (همان `https://…` نهایی) باید در پنل بیت‌پی ثبت شده باشد؛ ناهمخوانی آدرس باعث خطای درگاه (کد ۴) می‌شود.

مستند رسمی: مستندات درگاه بیت‌پی (نسخهٔ قرارداد BP_PGW_DOC 2.2).

### متغیرهای محیطی Vercel

الگوی کامل همهٔ کلیدهایی که کد می‌خواند در `vercel.env.example` است (`BITPAY_API_KEY`، Supabase، `GEMINI_API_KEY`، `PORT`).
مقدار رازها در Git خالی نگه داشته می‌شود و آزمون `node tests/runtime-smoke.js` مطمئن می‌شود هیچ کلید مصرفی از الگوها جا نمانده باشد.

```bash
cp vercel.env.example vercel.env.local      # فقط مقدارهای خالی را پر کنید (این فایل در Git نیست)
VERCEL_TOKEN=vcp_xxx npm run vercel:env -- --project <name> --dry-run   # پیش‌نمایش، بدون نوشتن
VERCEL_TOKEN=vcp_xxx npm run vercel:env -- --project <name>             # ساخت/به‌روزرسانی با upsert
npm run vercel:env:list -- --project <name>                             # تأیید؛ مقدار رازها چاپ نمی‌شود
```

`scripts/vercel-env.js` از REST API ورسل (`POST /v10/projects/<id>/env?upsert=true`) استفاده می‌کند؛
متغیرهای موجود را به‌روزرسانی می‌کند، هرگز مقدارها را لاگ نمی‌کند، و با `--secret-type=sensitive`
رازها را write-only می‌سازد. پس از اعمال، یک **Redeploy** لازم است. «Callback URL»ای که در
پنل بیت‌پی ثبت می‌شود `https://<دامنه>/api/payment/bitpay/callback` است و بقیهٔ مراحل در
`PRODUCTION_READINESS.md` آمده است.

## ابزارهای هوش مصنوعی

- **Product AI Studio** تصویر مرجع را در مرورگر با Puter.js و مدل‌های مجاز در دسترس حساب کاربر ویرایش می‌کند؛ هزینه/سهمیه به Puter و مدل انتخابی وابسته است و رایگان/نامحدود تضمین نمی‌شود. مدل Gemini برای استودیوی تصویر ارائه نمی‌شود؛ مدل‌های Cloudflare (در صورت نمایش) فقط از طریق Puter فراخوانی می‌شوند. تصویر خروجی از Supabase Storage و repository محصول ثبت می‌شود.
- **دستیار جداگانهٔ نگارش توضیحات محصول** قابلیت مستقلی است. کلید اختیاری `GEMINI_API_KEY` فقط سمت سرور استفاده می‌شود؛ هر ادعای فنی متن تولیدشده باید با مشخصات واقعی محصول بررسی شود.
- نشانگر سازگاری قدیمی `ComfyUI / Qwen-Image-Edit` در کد استودیو حفظ شده است و به‌معنی مسیر تولید مستقل از Puter نیست.

## تست و وضعیت انتشار

`npm test` شامل تست‌های آفلاین repository Supabase، Puter AI Studio، API، Auth، درگاه بیت‌پی (قرارداد gateway-send/result-second، حدود مبلغ ریالی، تسویهٔ یک‌مصرف، مهاجرت SQL و سیم‌کشی storefront) و fail-closed storefront است. این تست‌ها از stub استفاده می‌کنند و **جایگزین اجرای migration، مرورگر واقعی یا تراکنش Sandbox پذیرنده نیستند**.

وضعیت فعلی: `npm test` و `npm run build` موفق‌اند و schema واقعی Supabase اعمال/بررسی شده است؛ با این حال E2E ورود ایمیلی، SMTP، Storage با مدیر واقعی، مرورگر موبایل، کاتالوگ واقعی و پرداخت Sandbox انجام نشده‌اند. Production Vercel env از workspace قابل‌مشاهده نیست و preview محلی فعلاً بدون کلیدهای عمومی است. تا تکمیل این موارد و بازبینی اطلاعات فروشنده/قیمت/ارسال/موجودی، پروژه را Production-ready یا مجاز برای سفارش/پرداخت واقعی تلقی نکنید. جزئیات در [`PRODUCTION_READINESS.md`](PRODUCTION_READINESS.md).
