import type { Metadata, Viewport } from "next";
import "./globals.css";

const assetBase = process.env.NEXT_PUBLIC_BASE_PATH ?? "";

export const metadata: Metadata = {
  title: {
    default: "WhoopScope — Your WHOOP history, at home on Mac",
    template: "%s · WhoopScope",
  },
  description:
    "A free, open-source, privacy-first macOS dashboard for your WHOOP data.",
  applicationName: "WhoopScope",
  keywords: [
    "WHOOP",
    "macOS",
    "SwiftUI",
    "health data",
    "fitness",
    "open source",
  ],
  authors: [{ name: "WhoopScope contributors" }],
  openGraph: {
    title: "WhoopScope",
    description: "Your WHOOP history, at home on Mac.",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "WhoopScope",
    description: "Your WHOOP history, at home on Mac.",
  },
  icons: {
    icon: `${assetBase}/icon.png`,
    apple: `${assetBase}/icon.png`,
  },
};

export const viewport: Viewport = {
  colorScheme: "dark",
  themeColor: "#0a0b0d",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
