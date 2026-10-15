import type { Metadata, Viewport } from "next";
import { Bricolage_Grotesque, Crimson_Pro } from "next/font/google";
import { AuthProvider } from "@/components/AuthProvider";
import { Header } from "@/components/Header";
import { RequireAccount } from "@/components/RequireAccount";
import "./globals.css";

// Serif pour les citations, display arrondie et expressive pour l'interface
const serif = Crimson_Pro({ subsets: ["latin"], weight: ["400", "500", "600"], style: ["normal", "italic"], variable: "--font-serif" });
const display = Bricolage_Grotesque({ subsets: ["latin"], weight: ["400", "600", "800"], variable: "--font-display" });

export const metadata: Metadata = {
  title: "Qui l'a dit ? · Le jeu des citations politiques",
  description: "Une vraie citation, deux personnalités : qui l'a dit ? Jouez, ouvrez des boosters et collectionnez les phrases cultes de la politique française.",
};

export const viewport: Viewport = {
  themeColor: "#fff8ec",
  width: "device-width",
  initialScale: 1,
  viewportFit: "cover",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="fr" className={`${serif.variable} ${display.variable}`}>
      <body>
        <AuthProvider>
          <div className="backdrop" aria-hidden>
            <span className="blob blob-blue" />
            <span className="blob blob-red" />
            <span className="blob blob-gold" />
          </div>
          <RequireAccount>
            <Header />
            <main className="page">{children}</main>
          </RequireAccount>
        </AuthProvider>
      </body>
    </html>
  );
}
