const { Jimp } = require('jimp');

async function createTransparentLogo() {
  const size = 512;
  const image = new Jimp({ width: size, height: size, color: 0x00000000 });

  function pointInPoly(x, y, poly) {
    let inside = false;
    for (let i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      const xi = poly[i][0], yi = poly[i][1];
      const xj = poly[j][0], yj = poly[j][1];
      const intersect = ((yi > y) !== (yj > y)) &&
        (x < (xj - xi) * (y - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  const outerPoly = [
    [50, 5], [90, 27.5], [90, 72.5], [50, 95], [10, 72.5], [10, 27.5]
  ].map(([x, y]) => [x * 5.12, y * 5.12]);

  const outerHolePoly = [
    [50, 13], [83, 30.5], [83, 69.5], [50, 87], [17, 69.5], [17, 30.5]
  ].map(([x, y]) => [x * 5.12, y * 5.12]);

  const innerPoly = [
    [50, 22], [75, 36.5], [75, 63.5], [50, 78], [25, 63.5], [25, 36.5]
  ].map(([x, y]) => [x * 5.12, y * 5.12]);

  // Color #C6F432 in RGBA integer (0xC6F432FF)
  const colorHex = 0xC6F432FF;

  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const inOuter = pointInPoly(x, y, outerPoly);
      const inOuterHole = pointInPoly(x, y, outerHolePoly);
      const inInner = pointInPoly(x, y, innerPoly);

      if ((inOuter && !inOuterHole) || inInner) {
        image.setPixelColor(colorHex, x, y);
      }
    }
  }

  await image.write('logo.png');
  console.log('✅ Transparent logo.png successfully created!');
}

createTransparentLogo().catch(console.error);
