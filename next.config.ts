import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Anciennes adresses des modes de jeu
  async redirects() {
    return [
      { source: "/jouer", destination: "/solo", permanent: false },
      { source: "/duel", destination: "/multi", permanent: false },
      { source: "/a-propos", destination: "/", permanent: false },
      { source: "/methodologie", destination: "/", permanent: false },
    ];
  },
};

export default nextConfig;
