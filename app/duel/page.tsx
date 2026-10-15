import { redirect } from "next/navigation";

/** Les anciens liens /duel?id= et /duel?code= ouvrent le même écran que Jouer. */
export default async function DuelPage({
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
