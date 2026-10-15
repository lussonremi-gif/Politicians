import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Anciennes adresses : /jouer et /duel (les liens d'invitation /jouer?code=… ouvrent le Multi)
  async redirects() {
    return [
      { source: "/jouer", has: [{ type: "query", key: "code" }], destination: "/multi", permanent: false },
      { source: "/jouer", has: [{ type: "query", key: "id" }], destination: "/multi", permanent: false },
      { source: "/jouer", has: [{ type: "query", key: "mode", value: "duel" }], destination: "/multi", permanent: false },
      { source: "/jouer", destination: "/solo", permanent: false },
      { source: "/duel", destination: "/multi", permanent: false },
      { source: "/a-propos", destination: "/", permanent: false },
      { source: "/methodologie", destination: "/", permanent: false },
    ];
  },
};

export default nextConfig;
