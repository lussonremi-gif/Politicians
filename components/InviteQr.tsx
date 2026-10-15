"use client";

import { useEffect, useMemo, useState } from "react";
import qrcode from "qrcode-generator";

/** Adresse publique du jeu : NEXT_PUBLIC_SITE_URL si elle est définie, sinon l'adresse affichée. */
function siteUrl() {
  const configured = process.env.NEXT_PUBLIC_SITE_URL;
  if (configured) return configured.replace(/\/$/, "");
  return typeof window === "undefined" ? "" : window.location.origin;
}

/** QR code dessiné en SVG (un carré par module, net à toutes les tailles). */
function QrSvg({ text }: { text: string }) {
  const { size, path } = useMemo(() => {
    const qr = qrcode(0, "M");
    qr.addData(text);
    qr.make();
    const n = qr.getModuleCount();
    let d = "";
    for (let r = 0; r < n; r++) for (let c = 0; c < n; c++) if (qr.isDark(r, c)) d += `M${c} ${r}h1v1h-1z`;
    return { size: n, path: d };
  }, [text]);
  return (
    <svg className="qr-svg" viewBox={`-2 -2 ${size + 4} ${size + 4}`} role="img" aria-label={`QR code vers ${text}`} shapeRendering="crispEdges">
      <rect x={-2} y={-2} width={size + 4} height={size + 4} fill="#fff" />
      <path d={path} fill="#16193b" />
    </svg>
  );
}

/** Bouton d'en-tête qui ouvre le QR code d'accès au jeu. */
export function InviteQr() {
  const [open, setOpen] = useState(false);
  const [copied, setCopied] = useState(false);
  const [url, setUrl] = useState("");

  useEffect(() => setUrl(siteUrl()), []);

  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && setOpen(false);
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open]);

  async function copy() {
    await navigator.clipboard?.writeText(url);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  }

  return (
    <>
      <button className="share-btn" onClick={() => setOpen(true)} aria-label="Afficher le QR code du jeu">
        <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden>
          <rect x="3" y="3" width="7" height="7" rx="1" />
          <rect x="14" y="3" width="7" height="7" rx="1" />
          <rect x="3" y="14" width="7" height="7" rx="1" />
          <path d="M14 14h3v3h-3zM20 14v.01M14 20h.01M17 20h4v-3" />
        </svg>
        <span className="share-label">QR code</span>
      </button>
      {open && url && (
        <div className="qr-overlay" role="dialog" aria-modal="true" aria-label="QR code du jeu" onClick={() => setOpen(false)}>
          <div className="qr-card" onClick={(e) => e.stopPropagation()}>
            <p className="qr-kicker">Scannez pour jouer</p>
            <h2 className="qr-title">Qui l&apos;a dit&nbsp;?</h2>
            <QrSvg text={url} />
            <p className="qr-url">{url.replace(/^https?:\/\//, "")}</p>
            <div className="qr-actions">
              <button className="btn" onClick={copy}>
                {copied ? "Lien copié !" : "Copier le lien"}
              </button>
              <button className="btn primary" onClick={() => setOpen(false)}>
                Fermer
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
