// One-off: extracts the new hexagon mark (logiuz.png, solid navy background)
// into a transparent-background logo.png, matching the format gen_app_icons.js
// and gen_ios_splash.js expect (they composite logo.png onto their own navy
// canvases, so the source must not carry its own background).
const { Jimp } = require('jimp');

async function main() {
  const img = await Jimp.read('logiuz.png');
  const { width, height, data } = img.bitmap;

  // Sample the background color from the four corners (averaged).
  const corners = [[0, 0], [width - 1, 0], [0, height - 1], [width - 1, height - 1]];
  let br = 0, bg = 0, bb = 0;
  for (const [x, y] of corners) {
    const idx = (y * width + x) * 4;
    br += data[idx]; bg += data[idx + 1]; bb += data[idx + 2];
  }
  br /= 4; bg /= 4; bb /= 4;
  console.log('background sample:', br.toFixed(0), bg.toFixed(0), bb.toFixed(0));

  const lowThresh = 40;   // distance below this => fully transparent
  const highThresh = 90;  // distance above this => fully opaque

  for (let i = 0; i < data.length; i += 4) {
    const r = data[i], g = data[i + 1], b = data[i + 2];
    const dist = Math.sqrt((r - br) ** 2 + (g - bg) ** 2 + (b - bb) ** 2);
    let alpha;
    if (dist <= lowThresh) alpha = 0;
    else if (dist >= highThresh) alpha = 255;
    else alpha = Math.round(((dist - lowThresh) / (highThresh - lowThresh)) * 255);
    data[i + 3] = alpha;
  }

  await img.write('logo.png');
  console.log('done -> logo.png', width + 'x' + height);
}

main().catch(console.error);
