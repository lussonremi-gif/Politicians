import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Anciennes adresses Solo/Multi → écran Jouer unifié (les liens d'invitation gardent id/code)
  async redirects() {
    return [
      { source: "/a-propos", destination: "/", permanent: false },
      { source: "/methodologie", destination: "/", permanent: false },
    ];
  },
};

export default nextConfig;
