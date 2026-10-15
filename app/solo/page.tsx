import { redirect } from "next/navigation";

/** Ancienne adresse Solo → écran Jouer (mode solo). */
export default function SoloRedirect() {
  redirect("/jouer?mode=solo");
}
