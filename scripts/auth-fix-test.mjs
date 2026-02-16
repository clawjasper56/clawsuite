import { chromium } from 'playwright';
import fs from 'fs/promises';

const baseUrl = 'http://localhost:3001';
const screenshotPath = '/home/jasper/.openclaw/workspace/reports/auth-fix-test-screenshot.png';

const consoleErrors = [];
const consoleMessages = [];

const browser = await chromium.launch({ headless: true });
const context = await browser.newContext(); // fresh incognito-like context
const page = await context.newPage();

page.on('console', msg => {
  const text = msg.text();
  const entry = `[${msg.type()}] ${text}`;
  consoleMessages.push(entry);
  if (msg.type() === 'error') consoleErrors.push(entry);
});

page.on('pageerror', err => {
  consoleErrors.push(`[pageerror] ${err.message}`);
});

let gotoStatus = null;
let gotoError = null;
let title = '';
let currentUrl = '';
let bodyTextSnippet = '';
let loginIndicators = {};
let authCheck = null;

try {
  const resp = await page.goto(baseUrl, { waitUntil: 'domcontentloaded', timeout: 30000 });
  await page.waitForTimeout(2000);
  gotoStatus = resp?.status() ?? null;
  currentUrl = page.url();
  title = await page.title();

  bodyTextSnippet = (await page.locator('body').innerText()).slice(0, 600);

  const passwordFieldCount = await page.locator('input[type="password"]').count();
  const loginTextVisible = await page.getByText(/login|sign in|password/i).first().isVisible().catch(() => false);
  loginIndicators = {
    passwordFieldCount,
    loginTextVisible,
  };

  authCheck = await page.evaluate(async () => {
    try {
      const res = await fetch('/api/auth-check', { method: 'GET', credentials: 'include' });
      const contentType = res.headers.get('content-type') || '';
      let body;
      if (contentType.includes('application/json')) {
        body = await res.json();
      } else {
        body = await res.text();
      }
      return {
        ok: res.ok,
        status: res.status,
        contentType,
        body,
      };
    } catch (e) {
      return { error: String(e) };
    }
  });

  await page.screenshot({ path: screenshotPath, fullPage: true });
} catch (e) {
  gotoError = String(e);
}

await browser.close();

const result = {
  testedAt: new Date().toISOString(),
  baseUrl,
  gotoStatus,
  gotoError,
  title,
  currentUrl,
  bodyTextSnippet,
  loginIndicators,
  authCheck,
  consoleErrors,
  consoleMessages,
  screenshotPath,
};

await fs.mkdir('/home/jasper/.openclaw/workspace/reports', { recursive: true });
await fs.writeFile('/home/jasper/.openclaw/workspace/reports/auth-fix-test-data.json', JSON.stringify(result, null, 2));
console.log(JSON.stringify(result, null, 2));
