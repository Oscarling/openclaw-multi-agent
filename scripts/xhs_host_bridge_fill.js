#!/usr/bin/env node
"use strict";

const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const readline = require("node:readline");

function usage() {
  console.log(
    [
      "Usage:",
      "  node scripts/xhs_host_bridge_fill.js --job <publish_job.json> [options]",
      "",
      "Options:",
      "  --publish-url <url>     Xiaohongshu entry URL (profile or publish page)",
      "  --entry-url <url>       Alias of --publish-url",
      "  --fallback-publish-url <url>  Fallback publish URL when profile page has no upload input",
      "  --browser <name>        chromium (default) | webkit | safari(=webkit)",
      "  --keep-open             Keep browser open after fill; close only when you type CLOSE",
      "  --headless              Run browser in headless mode (default: false)",
      "  --run-dir <dir>         Output run directory (default: runtime/host_bridge_runs/<ts>)",
      "  --timeout-ms <ms>       Selector wait timeout (default: 12000)",
      "  --no-hashtag-fallback   Do not append hashtags to body when no hashtag input is found",
    ].join("\n")
  );
}

function parseArgs(argv) {
  const envEntryUrl = (process.env.XHS_BRIDGE_ENTRY_URL || "").trim();
  const envFallbackUrl = (process.env.XHS_BRIDGE_FALLBACK_PUBLISH_URL || "").trim();
  const envBrowser = (process.env.XHS_BRIDGE_BROWSER || "").trim();
  const opts = {
    publishUrl: envEntryUrl || "https://creator.xiaohongshu.com/publish/publish",
    fallbackPublishUrl: envFallbackUrl || "https://creator.xiaohongshu.com/publish/publish",
    browser: envBrowser || "chromium",
    keepOpen: false,
    headless: false,
    runDir: "",
    timeoutMs: 12000,
    hashtagFallback: true,
  };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--job") {
      opts.jobPath = argv[i + 1];
      i += 1;
      continue;
    }
    if (arg === "--publish-url" || arg === "--entry-url") {
      opts.publishUrl = argv[i + 1];
      i += 1;
      continue;
    }
    if (arg === "--fallback-publish-url") {
      opts.fallbackPublishUrl = argv[i + 1];
      i += 1;
      continue;
    }
    if (arg === "--browser") {
      opts.browser = argv[i + 1];
      i += 1;
      continue;
    }
    if (arg === "--keep-open") {
      opts.keepOpen = true;
      continue;
    }
    if (arg === "--headless") {
      opts.headless = true;
      continue;
    }
    if (arg === "--run-dir") {
      opts.runDir = argv[i + 1];
      i += 1;
      continue;
    }
    if (arg === "--timeout-ms") {
      opts.timeoutMs = Number(argv[i + 1]);
      i += 1;
      continue;
    }
    if (arg === "--no-hashtag-fallback") {
      opts.hashtagFallback = false;
      continue;
    }
    if (arg === "--help" || arg === "-h") {
      usage();
      process.exit(0);
    }
    throw new Error(`Unknown argument: ${arg}`);
  }

  if (!opts.jobPath) {
    throw new Error("Missing required argument: --job <publish_job.json>");
  }
  if (!Number.isFinite(opts.timeoutMs) || opts.timeoutMs <= 0) {
    throw new Error("--timeout-ms must be a positive number");
  }
  const normalized = (opts.browser || "").trim().toLowerCase();
  if (!["chromium", "webkit", "safari"].includes(normalized)) {
    throw new Error("--browser must be one of: chromium, webkit, safari");
  }
  opts.browser = normalized === "safari" ? "webkit" : normalized;
  return opts;
}

function readJson(jsonPath) {
  const raw = fs.readFileSync(jsonPath, "utf8");
  return JSON.parse(raw);
}

function ensureArrayOfStrings(value, key) {
  if (!Array.isArray(value) || value.length === 0 || value.some((v) => typeof v !== "string")) {
    throw new Error(`Invalid ${key}: must be a non-empty array of strings`);
  }
}

function validateJob(job) {
  const requiredStringKeys = [
    "task_id",
    "post_id",
    "platform",
    "material_dir",
    "final_title",
    "body_text",
    "first_comment",
    "cover_file",
  ];
  for (const key of requiredStringKeys) {
    if (typeof job[key] !== "string" || job[key].trim() === "") {
      throw new Error(`Invalid ${key}: must be a non-empty string`);
    }
  }
  if (job.stop_before_publish !== true) {
    throw new Error("Gate blocked: stop_before_publish must be true");
  }
  ensureArrayOfStrings(job.title_candidates, "title_candidates");
  ensureArrayOfStrings(job.hashtags, "hashtags");
  ensureArrayOfStrings(job.image_files, "image_files");
  ensureArrayOfStrings(job.operator_checklist, "operator_checklist");
  if (typeof job.evidence_ref !== "object" || job.evidence_ref === null) {
    throw new Error("Invalid evidence_ref: must be an object");
  }
}

function sha256OfFile(filePath) {
  const hash = crypto.createHash("sha256");
  hash.update(fs.readFileSync(filePath));
  return hash.digest("hex");
}

function timestampUtc() {
  const now = new Date();
  const pad = (n) => String(n).padStart(2, "0");
  return (
    `${now.getUTCFullYear()}` +
    `${pad(now.getUTCMonth() + 1)}` +
    `${pad(now.getUTCDate())}T` +
    `${pad(now.getUTCHours())}` +
    `${pad(now.getUTCMinutes())}` +
    `${pad(now.getUTCSeconds())}Z`
  );
}

function promptEnter(message) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });
  return new Promise((resolve) => {
    rl.question(`${message}\n`, () => {
      rl.close();
      resolve();
    });
  });
}

function promptText(message) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });
  return new Promise((resolve) => {
    rl.question(`${message}\n`, (answer) => {
      rl.close();
      resolve((answer || "").trim());
    });
  });
}

async function closeWithPolicy(context, keepOpen) {
  if (!keepOpen) {
    await context.close();
    return;
  }
  while (true) {
    const answer = await promptText(
      "[xhs-bridge] 浏览器保持打开。完成人工操作后输入 CLOSE 并回车，我再关闭浏览器。"
    );
    if (answer.toUpperCase() === "CLOSE") {
      await context.close();
      return;
    }
    console.log("[xhs-bridge] 未收到 CLOSE，浏览器继续保持打开。");
  }
}

async function findFirstLocator(page, selectors, timeoutMs) {
  const frames = page.frames();
  for (const frame of frames) {
    for (const selector of selectors) {
      const locator = frame.locator(selector).first();
      try {
        await locator.waitFor({ state: "attached", timeout: Math.min(timeoutMs, 2000) });
        return { selector, locator, frameUrl: frame.url() };
      } catch (_err) {
        // Keep trying next selector.
      }
    }
  }
  return null;
}

async function findFirstVisibleLocator(page, selectors, timeoutMs) {
  const frames = page.frames();
  for (const frame of frames) {
    for (const selector of selectors) {
      const locator = frame.locator(selector).first();
      try {
        await locator.waitFor({ state: "visible", timeout: Math.min(timeoutMs, 2200) });
        return { selector, locator, frameUrl: frame.url() };
      } catch (_err) {
        // Keep trying next selector.
      }
    }
  }
  return null;
}

function normalizeTag(tag) {
  const trimmed = tag.trim();
  if (!trimmed) {
    return "";
  }
  return trimmed.startsWith("#") ? trimmed : `#${trimmed}`;
}

async function fillWithLocator(locator, text) {
  await locator.click({ timeout: 5000 });
  await locator.fill(text, { timeout: 5000 });
}

function resolveActivePage(context, currentPage) {
  const pages = context.pages().filter((p) => !p.isClosed());
  if (pages.length === 0) {
    return currentPage;
  }
  return pages[pages.length - 1];
}

async function switchToNewestPageIfNeeded(context, pageRef, reason) {
  const newest = resolveActivePage(context, pageRef.current);
  if (newest && newest !== pageRef.current) {
    pageRef.current = newest;
    try {
      await pageRef.current.bringToFront();
    } catch (_err) {
      // ignore bringToFront errors
    }
    console.log(`[xhs-bridge] switched to newest page (${reason}): ${pageRef.current.url()}`);
  }
}

function frameUrls(page) {
  return page
    .frames()
    .map((f) => f.url() || "<empty>")
    .slice(0, 8);
}

async function tryUploadViaFileChooser(page, imagePaths) {
  const selectors = [
    'button:has-text("上传图文")',
    'button:has-text("上传图片")',
    'button:has-text("上传")',
    'button:has-text("发布图文")',
    'button:has-text("创作")',
    '[role="button"]:has-text("上传")',
    '[class*="upload"]',
    '[class*="Upload"]',
    '[aria-label*="上传"]',
  ];
  for (const frame of page.frames()) {
    for (const selector of selectors) {
      const locator = frame.locator(selector).first();
      try {
        await locator.waitFor({ state: "visible", timeout: 1200 });
        const chooserPromise = page.waitForEvent("filechooser", { timeout: 2500 });
        await locator.click({ timeout: 2500 });
        const chooser = await chooserPromise;
        await chooser.setFiles(imagePaths);
        return { ok: true, selector, frameUrl: frame.url() };
      } catch (_err) {
        // keep trying next candidate
      }
    }
  }
  return { ok: false };
}

async function switchToImageTab(page) {
  const selectors = [
    'button:has-text("图文")',
    '[role="tab"]:has-text("图文")',
    'text=图文',
    'button:has-text("发布图文")',
  ];
  for (const frame of page.frames()) {
    for (const selector of selectors) {
      const locator = frame.locator(selector).first();
      try {
        await locator.waitFor({ state: "visible", timeout: 900 });
        await locator.click({ timeout: 1200 });
        await page.waitForTimeout(350);
        return true;
      } catch (_err) {
        // keep trying
      }
    }
  }
  return false;
}

async function uploadImagesWithRetry({
  context,
  pageRef,
  imagePaths,
  timeoutMs,
  manualHint,
  maxAttempts = 3,
}) {
  const uploadSelectors = [
    'input[type="file"][accept*="image"]',
    'input[type="file"][accept*=".png"]',
    'input[type="file"][accept*=".jpg"]',
    'input[type="file"][accept*=".jpeg"]',
    'input[type="file"][accept*=".webp"]',
  ];
  for (let i = 1; i <= maxAttempts; i += 1) {
    await switchToNewestPageIfNeeded(context, pageRef, `upload-attempt-${i}`);
    const page = pageRef.current;
    if (page.url().includes("creator.xiaohongshu.com/publish")) {
      await switchToImageTab(page);
    }
    const uploadField = await findFirstLocator(page, uploadSelectors, timeoutMs);
    if (uploadField) {
      try {
        await uploadField.locator.setInputFiles(imagePaths);
        return {
          ok: true,
          method: "input_file",
          selector: uploadField.selector,
          frameUrl: uploadField.frameUrl || "",
        };
      } catch (err) {
        const msg = String(err && err.message ? err.message : err);
        console.log(`[xhs-bridge] input upload rejected: ${msg.split("\n")[0]}`);
      }
    }

    const chooserResult = await tryUploadViaFileChooser(page, imagePaths);
    if (chooserResult.ok) {
      return {
        ok: true,
        method: "filechooser_click",
        selector: chooserResult.selector,
        frameUrl: chooserResult.frameUrl || "",
      };
    }

    if (i < maxAttempts) {
      console.log(`[xhs-bridge] image upload controls not found (attempt ${i}/${maxAttempts}).`);
      console.log(`[xhs-bridge] current_url=${page.url()}`);
      console.log(`[xhs-bridge] frame_urls=${frameUrls(page).join(" | ")}`);
      await promptEnter(`[xhs-bridge] ${manualHint}\n完成后按回车继续重试...`);
    }
  }
  return { ok: false };
}

async function requireLocatorWithManualRetry({
  context,
  pageRef,
  selectors,
  timeoutMs,
  label,
  manualHint,
  maxAttempts = 3,
}) {
  for (let i = 1; i <= maxAttempts; i += 1) {
    await switchToNewestPageIfNeeded(context, pageRef, `${label}-attempt-${i}`);
    const page = pageRef.current;
    const found = await findFirstLocator(page, selectors, timeoutMs);
    if (found) {
      return found;
    }
    if (i < maxAttempts) {
      console.log(`[xhs-bridge] ${label} not found (attempt ${i}/${maxAttempts}).`);
      console.log(`[xhs-bridge] current_url=${page.url()}`);
      console.log(`[xhs-bridge] frame_urls=${frameUrls(page).join(" | ")}`);
      await promptEnter(`[xhs-bridge] ${manualHint}\n完成后按回车继续重试...`);
    }
  }
  return null;
}

async function locateAndMarkPublishButton(page, timeoutMs) {
  const publishSelectors = [
    'button:has-text("发布笔记")',
    'button:has-text("立即发布")',
    'button:has-text("发布")',
    '[role="button"]:has-text("发布")',
    'text=发布笔记',
    'text=发布',
  ];
  const found = await findFirstVisibleLocator(page, publishSelectors, timeoutMs);
  if (!found) {
    return null;
  }
  try {
    await found.locator.scrollIntoViewIfNeeded();
    await found.locator.evaluate((el) => {
      el.style.outline = "3px solid #ff2d55";
      el.style.outlineOffset = "2px";
      el.style.boxShadow = "0 0 0 4px rgba(255,45,85,0.2)";
    });
  } catch (_err) {
    // marker is best-effort
  }
  return found;
}

async function main() {
  const opts = parseArgs(process.argv.slice(2));
  const jobPath = path.resolve(opts.jobPath);
  if (!fs.existsSync(jobPath)) {
    throw new Error(`publish_job.json not found: ${jobPath}`);
  }

  const job = readJson(jobPath);
  validateJob(job);

  const runDir = path.resolve(
    opts.runDir || path.join(process.cwd(), "runtime", "host_bridge_runs", timestampUtc())
  );
  fs.mkdirSync(runDir, { recursive: true, mode: 0o700 });

  const jobSha256 = sha256OfFile(jobPath);
  const firstCommentPath = path.join(runDir, "first_comment.txt");
  const reportPath = path.join(runDir, "bridge_report.json");
  const screenshotPath = path.join(runDir, "stop_before_publish.png");
  const profileDir = path.resolve(path.join(process.cwd(), "runtime", "host_bridge_profile"));
  fs.mkdirSync(profileDir, { recursive: true, mode: 0o700 });

  fs.writeFileSync(firstCommentPath, `${job.first_comment}\n`, { mode: 0o600 });

  const imagePaths = job.image_files.map((f) => {
    if (path.isAbsolute(f)) {
      return f;
    }
    const direct = path.resolve(job.material_dir, f);
    if (fs.existsSync(direct)) {
      return direct;
    }
    const exportFallback = path.resolve(job.material_dir, "export", f);
    if (fs.existsSync(exportFallback)) {
      return exportFallback;
    }
    return direct;
  });
  const missing = imagePaths.filter((f) => !fs.existsSync(f));
  if (missing.length > 0) {
    throw new Error(`Missing image files:\n${missing.join("\n")}`);
  }

  let playwright;
  try {
    playwright = await import("playwright");
  } catch (_err) {
    throw new Error(
      'Missing dependency "playwright". Install with:\n' +
        "  cd \"/Users/lingguozhong/Codex工作室/openclaw multi -agent\"\n" +
        "  npm install playwright"
    );
  }

  console.log(`[xhs-bridge] job: ${jobPath}`);
  console.log(`[xhs-bridge] sha256: ${jobSha256}`);
  console.log(`[xhs-bridge] run_dir: ${runDir}`);
  console.log("[xhs-bridge] gate: stop_before_publish=true");
  console.log(`[xhs-bridge] browser=${opts.browser}`);
  console.log(`[xhs-bridge] keep_open=${opts.keepOpen ? "yes" : "no"}`);
  console.log(`[xhs-bridge] entry_url=${opts.publishUrl}`);
  console.log(`[xhs-bridge] fallback_publish_url=${opts.fallbackPublishUrl}`);

  const browserType = playwright[opts.browser];
  if (!browserType) {
    throw new Error(`Unsupported browser type: ${opts.browser}`);
  }

  let context;
  try {
    context = await browserType.launchPersistentContext(profileDir, {
      headless: opts.headless,
      viewport: { width: 1440, height: 960 },
    });
  } catch (err) {
    const message = String(err && err.message ? err.message : err);
    const hint =
      opts.browser === "webkit"
        ? "npx playwright install webkit"
        : "npx playwright install chromium";
    throw new Error(`${message}\nHint: ${hint}`);
  }
  const pageRef = { current: context.pages()[0] || (await context.newPage()) };
  try {
    await pageRef.current.goto(opts.publishUrl, { waitUntil: "domcontentloaded", timeout: 90000 });

    const editorSignal = await findFirstLocator(
      pageRef.current,
      [
        'input[placeholder*="标题"]',
        'textarea[placeholder*="正文"]',
        'textarea[placeholder*="描述"]',
        '[contenteditable="true"]',
      ],
      opts.timeoutMs
    );

    if (!editorSignal) {
      console.log("[xhs-bridge] login or publish page not ready; please complete login manually.");
      await promptEnter("[xhs-bridge] 完成登录并打开发布页面后，按回车继续...");
      await switchToNewestPageIfNeeded(context, pageRef, "post-manual-nav");
    }

    let uploadResult = await uploadImagesWithRetry({
      context,
      pageRef,
      imagePaths,
      timeoutMs: opts.timeoutMs,
      manualHint:
        "请手动切到“小红书图文发布页”（可从个人页点发布/创作入口进入），并确保页面出现可上传图片的区域",
      maxAttempts: 3,
    });

    if (
      !uploadResult.ok &&
      opts.fallbackPublishUrl &&
      pageRef.current.url() !== opts.fallbackPublishUrl
    ) {
      console.log("[xhs-bridge] trying fallback publish URL...");
      await pageRef.current.goto(opts.fallbackPublishUrl, {
        waitUntil: "domcontentloaded",
        timeout: 90000,
      });
      await promptEnter(
        "[xhs-bridge] 已跳转到 fallback 发布页。若页面要求登录或有弹窗，请手动处理后按回车继续..."
      );
      await switchToNewestPageIfNeeded(context, pageRef, "post-fallback-nav");
      uploadResult = await uploadImagesWithRetry({
        context,
        pageRef,
        imagePaths,
        timeoutMs: opts.timeoutMs,
        manualHint: "请确认当前页面是“图文发布编辑页”，且上传区域可见",
        maxAttempts: 2,
      });
    }

    if (!uploadResult.ok) {
      throw new Error(
        `Cannot find image upload controls after retries. current_url=${pageRef.current.url()} frame_urls=${frameUrls(
          pageRef.current
        ).join(" | ")}`
      );
    }
    console.log(`[xhs-bridge] uploaded images: ${imagePaths.length}`);
    console.log(
      `[xhs-bridge] upload_method=${uploadResult.method} selector=${uploadResult.selector || "<unknown>"}`
    );

    if (job.image_files[0] !== job.cover_file) {
      console.log(
        `[xhs-bridge] warning: cover_file (${job.cover_file}) is not first in image_files; please verify cover manually.`
      );
    }

    const titleField = await requireLocatorWithManualRetry({
      context,
      pageRef,
      selectors: [
        'input[placeholder*="标题"]',
        'textarea[placeholder*="标题"]',
        '[contenteditable="true"][aria-label*="标题"]',
        '[contenteditable="true"][data-placeholder*="标题"]',
        '[contenteditable="true"]',
      ],
      timeoutMs: opts.timeoutMs,
      label: "title field",
      manualHint: "请确认当前仍在发布编辑页，并手动点击一次标题区域",
      maxAttempts: 2,
    });
    if (!titleField) {
      throw new Error("Cannot find title field");
    }
    await fillWithLocator(titleField.locator, job.final_title);
    console.log(`[xhs-bridge] title filled`);

    const bodyField = await requireLocatorWithManualRetry({
      context,
      pageRef,
      selectors: [
        'textarea[placeholder*="正文"]',
        'textarea[placeholder*="描述"]',
        '[contenteditable="true"][aria-label*="正文"]',
        '[contenteditable="true"][data-placeholder*="正文"]',
        '[contenteditable="true"][data-placeholder*="描述"]',
        'textarea',
        '[contenteditable="true"]',
      ],
      timeoutMs: opts.timeoutMs,
      label: "body field",
      manualHint: "请确认正文输入区域可编辑，并手动点击正文输入框",
      maxAttempts: 2,
    });
    if (!bodyField) {
      throw new Error("Cannot find body field");
    }
    await fillWithLocator(bodyField.locator, job.body_text);
    console.log(`[xhs-bridge] body filled`);

    const hashtagInput = await findFirstLocator(
      pageRef.current,
      [
        'input[placeholder*="话题"]',
        'input[placeholder*="标签"]',
        'textarea[placeholder*="话题"]',
        '[contenteditable="true"][data-placeholder*="话题"]',
        '[contenteditable="true"][aria-label*="话题"]',
      ],
      opts.timeoutMs
    );

    const normalizedTags = job.hashtags.map(normalizeTag).filter(Boolean);
    let hashtagMode = "control";
    if (hashtagInput) {
      for (const tag of normalizedTags) {
        await hashtagInput.locator.click({ timeout: 5000 });
        await hashtagInput.locator.fill(tag, { timeout: 5000 });
        await pageRef.current.keyboard.press("Enter");
        await pageRef.current.waitForTimeout(200);
      }
    } else if (opts.hashtagFallback) {
      const bodyWithTags = `${job.body_text}\n\n${normalizedTags.join(" ")}`;
      await fillWithLocator(bodyField.locator, bodyWithTags);
      hashtagMode = "body_fallback";
      console.log("[xhs-bridge] hashtag input not found; appended hashtags to body");
    } else {
      hashtagMode = "manual_pending";
      console.log("[xhs-bridge] hashtag input not found; please add hashtags manually");
    }

    const publishButton = await locateAndMarkPublishButton(pageRef.current, opts.timeoutMs);
    if (publishButton) {
      console.log(
        `[xhs-bridge] publish_button_found selector=${publishButton.selector} frame=${publishButton.frameUrl || "<unknown>"}`
      );
      console.log("[xhs-bridge] 发布按钮已高亮，请人工确认后再点击。");
    } else {
      console.log("[xhs-bridge] publish_button_not_found_by_selector，请手动在页面右上或底部查找“发布/发布笔记”。");
    }

    await pageRef.current.screenshot({ path: screenshotPath, fullPage: true });

    const report = {
      task_id: job.task_id,
      post_id: job.post_id,
      platform: job.platform,
      job_path: jobPath,
      job_sha256: jobSha256,
      publish_url: opts.publishUrl,
      stop_before_publish: true,
      status: "filled_and_stopped_before_publish",
      run_dir: runDir,
      screenshot: screenshotPath,
      first_comment_file: firstCommentPath,
      page_url_at_stop: pageRef.current.url(),
      upload_method: uploadResult.method,
      upload_selector: uploadResult.selector || "",
      upload_frame_url: uploadResult.frameUrl || "",
      publish_button_found: Boolean(publishButton),
      publish_button_selector: publishButton ? publishButton.selector : "",
      publish_button_frame_url: publishButton ? publishButton.frameUrl || "" : "",
      hashtag_mode: hashtagMode,
      checklist: job.operator_checklist,
      note: "Script never clicks publish. Manual confirmation is required.",
    };
    fs.writeFileSync(reportPath, `${JSON.stringify(report, null, 2)}\n`, { mode: 0o600 });

    console.log("");
    console.log("[xhs-bridge] 已完成自动填充并停在发布按钮前。");
    console.log("[xhs-bridge] 请你人工检查后再决定是否点击发布。");
    console.log(`[xhs-bridge] screenshot: ${screenshotPath}`);
    console.log(`[xhs-bridge] first_comment: ${firstCommentPath}`);
    console.log(`[xhs-bridge] report: ${reportPath}`);
    console.log("[xhs-bridge] checklist:");
    for (const item of job.operator_checklist) {
      console.log(`  - [ ] ${item}`);
    }

    await closeWithPolicy(context, opts.keepOpen);
  } catch (err) {
    console.log(`[xhs-bridge] error: ${err.message}`);
    if (!opts.headless) {
      console.log("[xhs-bridge] 浏览器将保持打开，便于你手动检查当前页面。");
      if (!opts.keepOpen) {
        console.log("[xhs-bridge] 检查完成后按回车关闭浏览器并结束脚本。");
        await promptEnter("[xhs-bridge] 按回车关闭浏览器...");
      }
    }
    await closeWithPolicy(context, opts.keepOpen);
    throw err;
  }
}

main().catch((err) => {
  console.error(`[xhs-bridge] error: ${err.message}`);
  process.exit(1);
});
