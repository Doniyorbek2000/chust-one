// Generates solid-background (navy) app icons from the transparent brand
// mark (logo.png) for every platform surface: iOS AppIcon.appiconset, the
// iOS Web Clip profile icon, Android launcher icons, and the PWA manifest
// icons (regular + maskable). Icons on iOS home screens render transparent
// PNGs with a black fill, so every icon-shaped asset must be fully opaque.
const fs = require('fs');
const { Jimp } = require('jimp');
const { PNG } = require('pngjs');

const srcLogo = 'logo.png';
const NAVY = 0x041426ff; // Jimp RGBA hex (0xRRGGBBAA)

async function composite(mark, canvasSize, markScale) {
  const bg = new Jimp({ width: canvasSize, height: canvasSize, color: NAVY });
  const markSize = Math.round(canvasSize * markScale);
  const resizedMark = mark.clone().resize({ w: markSize, h: markSize });
  const offset = Math.round((canvasSize - markSize) / 2);
  bg.composite(resizedMark, offset, offset);
  return bg;
}

// Writes a Jimp image as a true opaque RGB PNG (no alpha channel at all),
// which App Store validation requires for app icons. Jimp's own
// `.write(path, { inputHasAlpha: false })` only flips the PNG color-type
// flag without actually removing the alpha byte from the pixel buffer,
// which desyncs every pixel's RGB triplet and renders as scrambled static
// once installed — this manually strips the 4th (alpha) byte per pixel
// before handing pngjs a correctly-sized RGB buffer.
function writeOpaquePng(image, path) {
  const { width, height, data } = image.bitmap; // RGBA, 4 bytes/pixel
  const rgb = Buffer.alloc(width * height * 3);
  for (let i = 0, j = 0; i < data.length; i += 4, j += 3) {
    rgb[j] = data[i];
    rgb[j + 1] = data[i + 1];
    rgb[j + 2] = data[i + 2];
  }
  const png = new PNG({ width, height, colorType: 2 });
  png.data = rgb;
  fs.writeFileSync(path, PNG.sync.write(png, { colorType: 2, inputHasAlpha: false }));
}

async function main() {
  const mark = await Jimp.read(srcLogo);
  console.log('Logo loaded successfully!');

  // --- favicon (browser tab) ---
  const favicon = await composite(mark, 64, 0.7);
  await favicon.clone().resize({ w: 32, h: 32 }).write('mobile/web/favicon.png');
  fs.copyFileSync('mobile/web/favicon.png', 'mobile/web/favicon.ico');
  console.log('favicon done');

  // --- apple-touch-icon (iOS Safari bookmark / add-to-home-screen) ---
  const touchIcon = await composite(mark, 180, 0.72);
  await touchIcon.write('mobile/web/apple-touch-icon.png');
  console.log('apple-touch-icon.png done');

  // --- iOS Web Clip profile icon (embedded in chust-one-ios.mobileconfig) ---
  const webClipIcon = await composite(mark, 180, 0.72);
  await webClipIcon.write('ios-webclip-icon.png');
  console.log('ios-webclip-icon.png done');

  // --- PWA manifest icons ---
  if (!fs.existsSync('mobile/web/icons')) fs.mkdirSync('mobile/web/icons', { recursive: true });
  const icon192 = await composite(mark, 192, 0.72);
  await icon192.write('mobile/web/icons/Icon-192.png');
  const icon512 = await composite(mark, 512, 0.72);
  await icon512.write('mobile/web/icons/Icon-512.png');
  // Maskable icons need extra safe-zone padding (OS applies its own mask shape)
  const maskable192 = await composite(mark, 192, 0.6);
  await maskable192.write('mobile/web/icons/Icon-maskable-192.png');
  const maskable512 = await composite(mark, 512, 0.6);
  await maskable512.write('mobile/web/icons/Icon-maskable-512.png');
  console.log('Web manifest icons done');

  // --- Android launcher icons ---
  const androidSizes = {
    'mobile/android/app/src/main/res/mipmap-mdpi': 48,
    'mobile/android/app/src/main/res/mipmap-hdpi': 72,
    'mobile/android/app/src/main/res/mipmap-xhdpi': 96,
    'mobile/android/app/src/main/res/mipmap-xxhdpi': 144,
    'mobile/android/app/src/main/res/mipmap-xxxhdpi': 192,
  };
  for (const [dir, size] of Object.entries(androidSizes)) {
    if (fs.existsSync(dir)) {
      const icon = await composite(mark, size, 0.72);
      await icon.write(dir + '/ic_launcher.png');
      await icon.write(dir + '/ic_launcher_round.png');
      console.log(`Android icon done: ${dir} (${size}px)`);
    }
  }

  // --- iOS AppIcon.appiconset (used if/when a native iOS build happens) ---
  const iosDir = 'mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset';
  if (fs.existsSync(iosDir)) {
    const iosSizes = {
      'Icon-App-1024x1024@1x.png': 1024,
      'Icon-App-60x60@1x.png': 60,
      'Icon-App-60x60@2x.png': 120,
      'Icon-App-60x60@3x.png': 180,
      'Icon-App-76x76@1x.png': 76,
      'Icon-App-76x76@2x.png': 152,
      'Icon-App-83.5x83.5@2x.png': 167,
      'Icon-App-40x40@1x.png': 40,
      'Icon-App-40x40@2x.png': 80,
      'Icon-App-40x40@3x.png': 120,
      'Icon-App-29x29@1x.png': 29,
      'Icon-App-29x29@2x.png': 58,
      'Icon-App-29x29@3x.png': 87,
      'Icon-App-20x20@1x.png': 20,
      'Icon-App-20x20@2x.png': 40,
      'Icon-App-20x20@3x.png': 60,
    };
    for (const [file, size] of Object.entries(iosSizes)) {
      const icon = await composite(mark, size, 0.72);
      // App Store validation rejects any app icon (especially the 1024
      // marketing icon) that carries an alpha channel, even if fully opaque.
      writeOpaquePng(icon, `${iosDir}/${file}`);
    }
    console.log('iOS AppIcon.appiconset done');
  }

  // --- iOS LaunchImage (LaunchScreen.storyboard logo, transparent over navy) ---
  const launchImageDir = 'mobile/ios/Runner/Assets.xcassets/LaunchImage.imageset';
  if (fs.existsSync(launchImageDir)) {
    const LAUNCH_BOX_W = 168;
    const LAUNCH_BOX_H = 185;
    const LAUNCH_MARK_SIZE = 140;
    const launchScales = { 'LaunchImage.png': 1, 'LaunchImage@2x.png': 2, 'LaunchImage@3x.png': 3 };
    for (const [file, scale] of Object.entries(launchScales)) {
      const canvas = new Jimp({ width: LAUNCH_BOX_W * scale, height: LAUNCH_BOX_H * scale, color: 0x00000000 });
      const markSize = LAUNCH_MARK_SIZE * scale;
      const resizedMark = mark.clone().resize({ w: markSize, h: markSize });
      const offsetX = Math.round((LAUNCH_BOX_W * scale - markSize) / 2);
      const offsetY = Math.round((LAUNCH_BOX_H * scale - markSize) / 2);
      canvas.composite(resizedMark, offsetX, offsetY);
      await canvas.write(`${launchImageDir}/${file}`);
    }
    console.log('iOS LaunchImage.imageset done');
  }

  console.log('\n✅ ALL APP ICONS REGENERATED (opaque navy background) FROM logo.png!');
}

main().catch(console.error);
