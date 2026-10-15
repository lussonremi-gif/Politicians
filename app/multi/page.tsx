"use client";

import { Suspense } from "react";
import { DuelRoot } from "@/components/DuelPlay";
import { Gate } from "@/components/Gate";

/** Mode Multi : duel 1 contre 1 en temps réel (création, invitation, partie, résultat). */
export default function MultiPage() {
  return (
    <Gate>
      <Suspense fallback={<p className="muted center">Chargement…</p>}>
        <DuelRoot />
      </Suspense>
    </Gate>
  );
}
