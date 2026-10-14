import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  images: {
    remotePatterns: [{ protocol: "https", hostname: "*.supabase.co" }],
  },
  async redirects() {
    return [{ source: "/duel", destination: "/jouer?mode=duel", permanent: false }];
  },
};

export default nextConfig;
