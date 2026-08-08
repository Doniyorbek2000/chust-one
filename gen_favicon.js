const fs = require('fs');
const { Jimp } = require('jimp');

const srcLogo = "C:/Users/Comp X/.gemini/antigravity/brain/f096944e-e2cd-4275-b83d-d62215c0feb2/chust_one_logo_1785925454401.jpg";

async function main() {
  const img = await Jimp.read(srcLogo);
  
  // favicon.png for browsers (32x32)
  await img.clone().resize({ w: 32, h: 32 }).write('mobile/web/favicon.png');
  console.log('favicon.png done (32x32)');
  
  // favicon.ico — overwrite with same PNG (most browsers accept PNG renamed as ico)
  await img.clone().resize({ w: 32, h: 32 }).write('mobile/web/favicon.ico');
  console.log('favicon.ico done (32x32)');

  // Also make a larger apple-touch-icon
  await img.clone().resize({ w: 180, h: 180 }).write('mobile/web/apple-touch-icon.png');
  console.log('apple-touch-icon.png done (180x180)');
  
  // Web icons
  if (!fs.existsSync('mobile/web/icons')) fs.mkdirSync('mobile/web/icons', { recursive: true });
  await img.clone().resize({ w: 192, h: 192 }).write('mobile/web/icons/Icon-192.png');
  await img.clone().resize({ w: 512, h: 512 }).write('mobile/web/icons/Icon-512.png');
  await img.clone().resize({ w: 192, h: 192 }).write('mobile/web/icons/Icon-maskable-192.png');
  await img.clone().resize({ w: 512, h: 512 }).write('mobile/web/icons/Icon-maskable-512.png');
  console.log('Web manifest icons done');

  console.log('ALL FAVICONS DONE!');
}

main().catch(console.error);
