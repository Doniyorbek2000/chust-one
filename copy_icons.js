const fs = require('fs');
const srcLogo = "C:/Users/Comp X/.gemini/antigravity/brain/f096944e-e2cd-4275-b83d-d62215c0feb2/chust_one_logo_1785925454401.jpg";

// Copy as favicon (browsers also accept jpg as ico)
fs.copyFileSync(srcLogo, 'mobile/web/favicon.png');
fs.copyFileSync(srcLogo, 'mobile/web/favicon.ico');

// Make icons dir if not exists
if (!fs.existsSync('mobile/web/icons')) {
  fs.mkdirSync('mobile/web/icons', { recursive: true });
}

// Copy as web manifest icons
fs.copyFileSync(srcLogo, 'mobile/web/icons/Icon-192.png');
fs.copyFileSync(srcLogo, 'mobile/web/icons/Icon-512.png');
fs.copyFileSync(srcLogo, 'mobile/web/icons/Icon-maskable-192.png');
fs.copyFileSync(srcLogo, 'mobile/web/icons/Icon-maskable-512.png');

// Also copy to android res folders for launcher icon
const androidMipmapDirs = [
  'mobile/android/app/src/main/res/mipmap-mdpi',
  'mobile/android/app/src/main/res/mipmap-hdpi',
  'mobile/android/app/src/main/res/mipmap-xhdpi',
  'mobile/android/app/src/main/res/mipmap-xxhdpi',
  'mobile/android/app/src/main/res/mipmap-xxxhdpi',
];

for (const dir of androidMipmapDirs) {
  if (fs.existsSync(dir)) {
    fs.copyFileSync(srcLogo, dir + '/ic_launcher.png');
    fs.copyFileSync(srcLogo, dir + '/ic_launcher_round.png');
    console.log('Copied to: ' + dir);
  } else {
    console.log('Dir not found: ' + dir);
  }
}

// iOS
const iosAssets = 'mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset';
if (fs.existsSync(iosAssets)) {
  fs.copyFileSync(srcLogo, iosAssets + '/Icon-App-1024x1024@1x.png');
  console.log('Copied iOS icon');
}

console.log('All icons copied successfully!');
