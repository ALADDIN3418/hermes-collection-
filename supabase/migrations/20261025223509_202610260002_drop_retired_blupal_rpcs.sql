-- Remove database entry points for the retired BluPal checkout.
-- Historical provider values remain permitted by the payments CHECK constraint,
-- but only BitPay RPCs are retained for live checkout and settlement.

drop function if exists public.attach_blupal_payment(uuid, text, text, text, bigint, bigint, text);
drop function if exists public.settle_blupal_payment(uuid, text, text, bigint, text, text, jsonb);
drop function if exists public.expire_stale_blupal_checkouts(integer);

notify pgrst, 'reload schema';
