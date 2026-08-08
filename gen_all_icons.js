const fs = require('fs');
const { Jimp } = require('jimp');

const srcLogo = "logo.png";

async function main() {
  const img = await Jimp.read(srcLogo);
  console.log('Logo loaded successfully!');

  // favicon.png (32x32) for browser tab
  await img.clone().resize({ w: 32, h: 32 }).write('mobile/web/favicon.png');
  console.log('favicon.png done (32x32)');

  // favicon.ico copy from favicon.png
  fs.copyFileSync('mobile/web/favicon.png', 'mobile/web/favicon.ico');
  console.log('favicon.ico done');

  // apple-touch-icon (180x180)
  await img.clone().resize({ w: 180, h: 180 }).write('mobile/web/apple-touch-icon.png');
  console.log('apple-touch-icon.png done');

  // Web manifest icons
  if (!fs.existsSync('mobile/web/icons')) fs.mkdirSync('mobile/web/icons', { recursive: true });
  await img.clone().resize({ w: 192, h: 192 }).write('mobile/web/icons/Icon-192.png');
  await img.clone().resize({ w: 512, h: 512 }).write('mobile/web/icons/Icon-512.png');
  await img.clone().resize({ w: 192, h: 192 }).write('mobile/web/icons/Icon-maskable-192.png');
  await img.clone().resize({ w: 512, h: 512 }).write('mobile/web/icons/Icon-maskable-512.png');
  console.log('Web manifest icons done');

  // Android launcher icons
  const sizes = {
    'mobile/android/app/src/main/res/mipmap-mdpi': 48,
    'mobile/android/app/src/main/res/mipmap-hdpi': 72,
    'mobile/android/app/src/main/res/mipmap-xhdpi': 96,
    'mobile/android/app/src/main/res/mipmap-xxhdpi': 144,
    'mobile/android/app/src/main/res/mipmap-xxxhdpi': 192,
  };
  for (const [dir, size] of Object.entries(sizes)) {
    if (fs.existsSync(dir)) {
      await img.clone().resize({ w: size, h: size }).write(dir + '/ic_launcher.png');
      await img.clone().resize({ w: size, h: size }).write(dir + '/ic_launcher_round.png');
      console.log(`Android icon done: ${dir} (${size}px)`);
    }
  }

  // iOS AppIcon
  const iosDir = 'mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset';
  if (fs.existsSync(iosDir)) {
    await img.clone().resize({ w: 1024, h: 1024 }).write(iosDir + '/Icon-App-1024x1024@1x.png');
    await img.clone().resize({ w: 60, h: 60 }).write(iosDir + '/Icon-App-60x60@1x.png');
    await img.clone().resize({ w: 120, h: 120 }).write(iosDir + '/Icon-App-60x60@2x.png');
    await img.clone().resize({ w: 180, h: 180 }).write(iosDir + '/Icon-App-60x60@3x.png');
    await img.clone().resize({ w: 76, h: 76 }).write(iosDir + '/Icon-App-76x76@1x.png');
    await img.clone().resize({ w: 152, h: 152 }).write(iosDir + '/Icon-App-76x76@2x.png');
    await img.clone().resize({ w: 83, h: 83 }).write(iosDir + '/Icon-App-83.5x83.5@2x.png');
    await img.clone().resize({ w: 40, h: 40 }).write(iosDir + '/Icon-App-40x40@1x.png');
    await img.clone().resize({ w: 80, h: 80 }).write(iosDir + '/Icon-App-40x40@2x.png');
    await img.clone().resize({ w: 120, h: 120 }).write(iosDir + '/Icon-App-40x40@3x.png');
    await img.clone().resize({ w: 29, h: 29 }).write(iosDir + '/Icon-App-29x29@1x.png');
    await img.clone().resize({ w: 58, h: 58 }).write(iosDir + '/Icon-App-29x29@2x.png');
    await img.clone().resize({ w: 87, h: 87 }).write(iosDir + '/Icon-App-29x29@3x.png');
    await img.clone().resize({ w: 20, h: 20 }).write(iosDir + '/Icon-App-20x20@1x.png');
    await img.clone().resize({ w: 40, h: 40 }).write(iosDir + '/Icon-App-20x20@2x.png');
    await img.clone().resize({ w: 60, h: 60 }).write(iosDir + '/Icon-App-20x20@3x.png');
    console.log('iOS icons done');
  }

  console.log('\n✅ ALL ICONS GENERATED FROM logo.png SUCCESSFULLY!');
}

main().catch(console.error);
