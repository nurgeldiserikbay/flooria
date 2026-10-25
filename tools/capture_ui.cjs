// Browser-side visual QA for the *compiled* Flutter web app.
// Generates real screenshots; never uses the reference mockup as a screenshot.
const { chromium } = require('playwright');
const fs = require('node:fs');
const path = require('node:path');

(async () => {
  const out = path.resolve('screenshots');
  fs.mkdirSync(out, { recursive: true });
  const errors = [];
  const browser = await chromium.launch({ headless: true });
  const url = 'http://127.0.0.1:8765/flooria/';

  async function createPage(width, height) {
    const page = await browser.newPage({
      viewport: { width, height },
      deviceScaleFactor: 1,
      reducedMotion: 'reduce',
    });
    page.on('pageerror', (e) => errors.push('JS: ' + e.message));
    page.on('response', (response) => {
      if (response.status() >= 400 &&
          response.url().includes('/flooria/assets/')) {
        errors.push(response.status() + ' ' + response.url());
      }
    });
    await page.goto(url, { waitUntil: 'load', timeout: 30000 });
    await page.waitForTimeout(4700); // Flutter bootstrap and image decode
    return page;
  }

  for (const [width, height] of [[360, 800], [390, 844], [430, 932]]) {
    const page = await createPage(width, height);
    await page.screenshot({
      path: path.join(out, 'home-' + width + 'x' + height + '.png'),
      animations: 'disabled',
    });

    if (width === 390) {
      // Three visible navigation portals: map / games / profile.
      await page.mouse.click(195, height - 40);
      await page.waitForTimeout(700);
      await page.screenshot({
        path: path.join(out, 'games-390x844.png'),
      });
      await page.mouse.click(310, height - 40);
      await page.waitForTimeout(750);
      await page.screenshot({
        path: path.join(out, 'profile-390x844.png'),
      });
      // Scroll the profile to capture records (not a non-existent fourth tab).
      await page.mouse.move(200, 480);
      await page.mouse.wheel(0, 590);
      await page.waitForTimeout(700);
      await page.screenshot({
        path: path.join(out, 'records-390x844.png'),
      });
    }
    await page.close();
  }
  await browser.close();
  fs.writeFileSync(path.join(out, 'runtime-check.json'),
    JSON.stringify({ pages: 6, errors }, null, 2));
  if (errors.length) {
    console.error('Flutter browser errors:\n' + errors.join('\n'));
    process.exitCode = 1;
  } else {
    console.log('Flutter mobile runtime screenshots captured without asset 404/page errors');
  }
})().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
