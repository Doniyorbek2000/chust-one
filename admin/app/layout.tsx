import './globals.css';
import React from 'react';

export const metadata = {
  title: 'Chust One Academy — Admin Control Panel',
  description: 'Management dashboard for Chust One Academy',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="uz">
      <body className="bg-[#041426] text-white min-h-screen">
        {children}
      </body>
    </html>
  );
}
