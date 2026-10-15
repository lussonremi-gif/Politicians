"use client";

import { useEffect, useLayoutEffect, useRef, useState } from "react";

// Taille d'origine d'une carte (voir .ccard)
const CARD_W = 230;
const CARD_H = 360;
const GAP = 12;
const ZOOMS = [1, 0.95, 0.9, 0.85, 0.8, 0.75, 0.7, 0.65, 0.6, 0.56, 0.52, 0.48, 0.45];

/**
 * Grille de cartes qui tient dans la place disponible, sans défilement :
 * les cartes sont mises à l'échelle et réparties en pages (flèches ou glissé du doigt).
 */
export function CardPager<T>({
  items,
  render,
  resetKey,
}: {
  items: T[];
  render: (item: T) => React.ReactNode;
  resetKey?: string;
}) {
  const box = useRef<HTMLDivElement>(null);
  const [layout, setLayout] = useState({ zoom: 0.8, cols: 4, rows: 2 });
  const [page, setPage] = useState(0);
  const touchX = useRef<number | null>(null);

  useLayoutEffect(() => {
    const el = box.current;
    if (!el) return;
    function fit() {
      if (!el) return;
      const w = el.clientWidth;
      const h = el.clientHeight;
      const target = Math.min(items.length || 1, w < 600 ? 4 : 8);
      let best = { zoom: ZOOMS[ZOOMS.length - 1], cols: 1, rows: 1 };
      for (const z of ZOOMS) {
        const cols = Math.max(1, Math.floor((w + GAP) / (CARD_W * z + GAP)));
        const rows = Math.max(1, Math.floor((h + GAP) / (CARD_H * z + GAP)));
        best = { zoom: z, cols, rows };
        if (cols * rows >= target && CARD_H * z <= h) break;
      }
      setLayout(best);
    }
    fit();
    const ro = new ResizeObserver(fit);
    ro.observe(el);
    return () => ro.disconnect();
  }, [items.length]);

  useEffect(() => setPage(0), [resetKey]);

  const perPage = layout.cols * layout.rows;
  const pages = Math.max(1, Math.ceil(items.length / perPage));
  const current = Math.min(page, pages - 1);
  const shown = items.slice(current * perPage, current * perPage + perPage);

  return (
    <div className="pager">
      <div
        className="pager-box"
        ref={box}
        onTouchStart={(e) => (touchX.current = e.touches[0].clientX)}
        onTouchEnd={(e) => {
          if (touchX.current === null) return;
          const dx = e.changedTouches[0].clientX - touchX.current;
          if (dx < -40) setPage(Math.min(pages - 1, current + 1));
          if (dx > 40) setPage(Math.max(0, current - 1));
          touchX.current = null;
        }}
      >
        <div
          className="pager-grid"
          key={`${resetKey}-${current}`}
          style={{ gridTemplateColumns: `repeat(${Math.min(layout.cols, shown.length || 1)}, ${CARD_W * layout.zoom}px)`, gap: GAP }}
        >
          {shown.map((item, i) => (
            <div key={i} className="pager-cell" style={{ zoom: layout.zoom }}>
              {render(item)}
            </div>
          ))}
        </div>
      </div>
      {pages > 1 && (
        <div className="pager-nav">
          <button className="pager-btn" onClick={() => setPage(Math.max(0, current - 1))} disabled={current === 0} aria-label="Page précédente">
            ‹
          </button>
          <span className="pager-count">
            {current + 1} / {pages}
          </span>
          <button className="pager-btn" onClick={() => setPage(Math.min(pages - 1, current + 1))} disabled={current >= pages - 1} aria-label="Page suivante">
            ›
          </button>
        </div>
      )}
    </div>
  );
}
