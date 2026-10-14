import type { Metadata, Viewport } from "next";
import { Crimson_Pro } from "next/font/google";
import { AuthProvider } from "@/components/AuthProvider";
import { Header } from "@/components/Header";
import { RequireAccount } from "@/components/RequireAccount";
import "./globals.css";

const serif = Crimson_Pro({ subsets: ["latin"], weight: ["400", "500", "600"], variable: "--font-serif" });

export const metadata: Metadata = {
  title: "Qui l'a dit ? · Présidentielle 2027",
  description: "Le jeu de cartes qui fait découvrir les candidats à la présidentielle 2027 à travers leurs propres citations.",
};

export const viewport: Viewport = {
  themeColor: "#f7f5f1",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="fr" className={serif.variable}>
      <body>
        <AuthProvider>
          <div className="backdrop" aria-hidden />
          <RequireAccount>
            <Header />
            <main className="page">{children}</main>
            <footer className="site-footer">
              <span className="tricolor small" aria-hidden />
              <p>Un jeu neutre : même traitement pour chaque candidat, chaque citation sourcée.</p>
            </footer>
          </RequireAccount>
        </AuthProvider>
      </body>
    </html>
  );
}
