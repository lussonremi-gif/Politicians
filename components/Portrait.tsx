import type { Option } from "@/lib/types";

function initials(name: string) {
  return name
    .split(/\s+/)
    .filter(Boolean)
    .map((w) => w[0])
    .slice(0, 2)
    .join("")
    .toUpperCase();
}

/** Photo de la personnalité si disponible, sinon monogramme neutre (même traitement pour tous). */
export function Portrait({ person }: { person: Pick<Option, "name" | "image_url"> }) {
  if (person.image_url) {
    // eslint-disable-next-line @next/next/no-img-element
    return <img className="portrait-img" src={person.image_url} alt={person.name} />;
  }
  return (
    <div className="portrait-fallback" aria-hidden>
      <span>{initials(person.name)}</span>
    </div>
  );
}
