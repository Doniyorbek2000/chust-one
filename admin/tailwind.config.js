/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        limeAccent: "#D7FF00",
        navyBg: "#041426",
        navyCard: "#082039",
        navyBorder: "#23415D",
      },
    },
  },
  plugins: [],
}
