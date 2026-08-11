// Generates iOS "apple-touch-startup-image" splash screens so Safari shows
// the brand mark on a navy background while the app loads, instead of a
// plain white flash. Covers the common modern iPhone portrait viewports.
const { Jimp } = require('jimp');

const NAVY = 0x041426ff;

// [width, height, device-width, device-height, pixel-ratio]
const SPLASH_SIZES = [
  [1170, 2532, 390, 844, 3],   // iPhone 12/13/14
  [1179, 2556, 393, 852, 3],   // iPhone 14/15 Pro
  [1284, 2778, 428, 926, 3],   // iPhone 12/13/14 Pro Max
  [1290, 2796, 430, 932, 3],   // iPhone 15/16 Pro Max
  [1080, 2340, 360, 780, 3],   // iPhone SE-class / smaller Android-ish fallback
  [750, 1334, 375, 667, 2],    // iPhone SE / 8
];

async function main() {
  const mark = await Jimp.read('logo.png');
  const links = [];

  for (const [w, h] of SPLASH_SIZES) {
    const canvas = new Jimp({ width: w, height: h, color: NAVY });
    const markSize = Math.round(Math.min(w, h) * 0.32);
    const resizedMark = mark.clone().resize({ w: markSize, h: markSize });
    canvas.composite(resizedMark, Math.round((w - markSize) / 2), Math.round((h - markSize) / 2));
    const filename = `splash-${w}x${h}.png`;
    await canvas.write(`mobile/web/${filename}`);
    console.log('splash done:', filename);
  }

  console.log('\n✅ ALL SPLASH SCREENS GENERATED!');
}

main().catch(console.error);
