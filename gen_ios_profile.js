const fs = require('fs');

// Read the opaque (navy-background) webclip icon and convert to base64.
// iOS renders transparent PNGs on the home screen with a black fill, so this
// must be the composited icon from gen_app_icons.js, not the raw transparent
// logo.png.
const logoBuffer = fs.readFileSync('ios-webclip-icon.png');
const logoBase64 = logoBuffer.toString('base64');

const mobileConfigContent = `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>PayloadContent</key>
	<array>
		<dict>
			<key>FullScreen</key>
			<true/>
			<key>Icon</key>
			<data>
${logoBase64}
			</data>
			<key>IsRemovable</key>
			<true/>
			<key>Label</key>
			<string>Chust One</string>
			<key>PayloadDescription</key>
			<string>Chust One Academy Rasmiy Mobil Ilovasi</string>
			<key>PayloadDisplayName</key>
			<string>Chust One Academy</string>
			<key>PayloadIdentifier</key>
			<string>uz.chustone.academy.webclip</string>
			<key>PayloadType</key>
			<string>com.apple.webClip.managed</string>
			<key>PayloadUUID</key>
			<string>9F82B3E4-1234-4567-89AB-CDEF01234567</string>
			<key>PayloadVersion</key>
			<integer>1</integer>
			<key>URL</key>
			<string>https://one.temdon.uz/app/</string>
		</dict>
	</array>
	<key>PayloadDisplayName</key>
	<string>Chust One Academy iOS Ilovasi</string>
	<key>PayloadIdentifier</key>
	<string>uz.chustone.academy.profile</string>
	<key>PayloadRemovalDisallowed</key>
	<false/>
	<key>PayloadType</key>
	<string>Configuration</string>
	<key>PayloadUUID</key>
	<string>8F82B3E4-1234-4567-89AB-CDEF01234568</string>
	<key>PayloadVersion</key>
	<integer>1</integer>
</dict>
</plist>`;

fs.writeFileSync('mobile/web/chust-one-ios.mobileconfig', mobileConfigContent);
console.log('chust-one-ios.mobileconfig created successfully!');
