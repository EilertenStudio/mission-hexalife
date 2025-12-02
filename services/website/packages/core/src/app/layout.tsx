import "./globals.css";

import React, {Suspense} from "react";

export default function RootLayout(
  {
    children
  }: {
    children: React.ReactNode
  }
) {
  return (
    <html lang="en">
    <head>
      <meta charSet="UTF-8"/>
      <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
      <title>Mission HeXalife</title>
    </head>
    <body>
    <Suspense fallback={null}>
      {children}
    </Suspense>
    </body>
    </html>
  );
}
