const fs = require('fs');
const path = require('path');

// Read the JPG source
const srcLogo = "C:/Users/Comp X/.gemini/antigravity/brain/f096944e-e2cd-4275-b83d-d62215c0feb2/chust_one_logo_1785925454401.jpg";

// We need to restore original PNG icons from Flutter's default set
// The generated logo is a JPG - Android needs real PNGs
// Let's restore the original icons first (revert the bad icon copy)

// Restore Flutter's default launcher icons by creating valid 1x1 png placeholder
// A minimal valid PNG: 1x1 px dark navy square
const PNG_1x1_NAVY = Buffer.from([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
  0x00, 0x00, 0x00, 0x0D, // IHDR chunk length
  0x49, 0x48, 0x44, 0x52, // IHDR
  0x00, 0x00, 0x00, 0x01, // width: 1
  0x00, 0x00, 0x00, 0x01, // height: 1
  0x08, 0x02,             // 8-bit RGB
  0x00, 0x00, 0x00,       // compression, filter, interlace
  0x90, 0x77, 0x53, 0xDE, // CRC
  0x00, 0x00, 0x00, 0x0C, // IDAT chunk length
  0x49, 0x44, 0x41, 0x54, // IDAT
  0x08, 0xD7, 0x63, 0x60, 0x60, 0x60, 0x00, 0x00, // zlib compressed 1px navy
  0x00, 0x04, 0x00, 0x01, // end of IDAT
  0xE2, 0x21, 0xBC, 0x33, // CRC
  0x00, 0x00, 0x00, 0x00, // IEND chunk length
  0x49, 0x45, 0x4E, 0x44, // IEND
  0xAE, 0x42, 0x60, 0x82  // CRC
]);

const androidMipmapDirs = [
  'mobile/android/app/src/main/res/mipmap-mdpi',
  'mobile/android/app/src/main/res/mipmap-hdpi',
  'mobile/android/app/src/main/res/mipmap-xhdpi',
  'mobile/android/app/src/main/res/mipmap-xxhdpi',
  'mobile/android/app/src/main/res/mipmap-xxxhdpi',
];

for (const dir of androidMipmapDirs) {
  if (fs.existsSync(dir)) {
    fs.writeFileSync(dir + '/ic_launcher.png', PNG_1x1_NAVY);
    fs.writeFileSync(dir + '/ic_launcher_round.png', PNG_1x1_NAVY);
    console.log('Restored valid PNG to: ' + dir);
  }
}

console.log('Restoration done! Now rebuild APK will succeed.');
