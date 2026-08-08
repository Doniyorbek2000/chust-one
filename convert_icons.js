const { execSync } = require('child_process');
const fs = require('fs');

const srcLogo = "C:/Users/Comp X/.gemini/antigravity/brain/f096944e-e2cd-4275-b83d-d62215c0feb2/chust_one_logo_1785925454401.jpg";

const { Jimp } = require('jimp');

const sizes = {
  'mobile/android/app/src/main/res/mipmap-mdpi': 48,
  'mobile/android/app/src/main/res/mipmap-hdpi': 72,
  'mobile/android/app/src/main/res/mipmap-xhdpi': 96,
  'mobile/android/app/src/main/res/mipmap-xxhdpi': 144,
  'mobile/android/app/src/main/res/mipmap-xxxhdpi': 192,
};

async function main() {
  const img = await Jimp.read(srcLogo);
  
  for (const [dir, size] of Object.entries(sizes)) {
    if (fs.existsSync(dir)) {
      const resized = img.clone().resize({ w: size, h: size });
      await resized.write(dir + '/ic_launcher.png');
      await resized.write(dir + '/ic_launcher_round.png');
      console.log(`Done: ${dir} (${size}x${size})`);
    }
  }
  
  // Web icons dir
  if (!fs.existsSync('mobile/web/icons')) fs.mkdirSync('mobile/web/icons', { recursive: true });
  
  await img.clone().resize({ w: 192, h: 192 }).write('mobile/web/icons/Icon-192.png');
  await img.clone().resize({ w: 512, h: 512 }).write('mobile/web/icons/Icon-512.png');
  await img.clone().resize({ w: 192, h: 192 }).write('mobile/web/icons/Icon-maskable-192.png');
  await img.clone().resize({ w: 512, h: 512 }).write('mobile/web/icons/Icon-maskable-512.png');
  await img.clone().resize({ w: 32, h: 32 }).write('mobile/web/favicon.png');
  
  console.log('All icons generated successfully!');
}

main().catch(console.error);
