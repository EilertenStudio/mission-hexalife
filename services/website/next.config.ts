import type { NextConfig } from "next";

const nextConfig: NextConfig = {
    output: "export",
    basePath: process.env.PAGES_BASE_PATH,

    // Optional: Change links `/me` -> `/me/` and emit `/me.html` -> `/me/index.html`
    // trailingSlash: true,

    // Optional: Prevent automatic `/me` -> `/me/`, instead preserve `href`
    // skipTrailingSlashRedirect: true,

    // Optional: Change the output directory `out` -> `dist`
    distDir: 'build/html',
};

export default nextConfig;
