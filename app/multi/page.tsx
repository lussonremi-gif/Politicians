import { redirect } from "next/navigation";

/** Ancienne adresse Multi → écran Jouer (duel), en conservant id/code. */
export default async function MultiRedirect({
  searchParams,
}: {
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}) {
  const params = await searchParams;
  const qs = new URLSearchParams();
  for (const [key, value] of Object.entries(params)) {
    if (typeof value === "string") qs.set(key, value);
    else if (Array.isArray(value)) for (const item of value) qs.append(key, item);
  }
  if (!qs.has("id") && !qs.has("code") && !qs.has("mode")) qs.set("mode", "duel");
  const query = qs.toString();
  redirect(query ? `/jouer?${query}` : "/jouer?mode=duel");
}
