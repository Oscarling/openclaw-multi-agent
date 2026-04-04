#!/usr/bin/env node
"use strict";

const fs = require("node:fs");
const path = require("node:path");
const readline = require("node:readline");
const { spawnSync } = require("node:child_process");

function usage() {
  console.log(
    [
      "Usage:",
      "  node scripts/xhs_review24h_autocollect.js [options]",
      "",
      "Options:",
      "  --entry-url <url>        Start URL (default: https://creator.xiaohongshu.com/statistics/note-detail?noteId=<note_id>)",
      "  --browser <name>         chromium | webkit | safari(=webkit), default webkit",
      "  --headless               Run headless mode (default: false)",
      "  --task-id <id>           default GOAL-XHS-ASSET-001",
      "  --post-id <id>           default P01",
      "  --note-id <id>           default 69ce60270000000021005d6c",
      "  --operator <name>        default lingguozhong",
      "  --out-dir <dir>          Output directory (default runtime/publish_evidence/review_24h_auto_<ts>)",
      "  --sync                   Run xhs_review24h_sync.sh after collect success",
      "  --keep-open              Keep browser open until you input CLOSE",
      "  --no-prompt              Skip manual Enter prompt and collect immediately",
      "  -h, --help               Show help",
      "",
      "What it collects:",
      "  views, likes, saves, comments, shares, follows, profile_visits, private_inquiries, note_status",
    ].join("\n")
  );
}

function parseArgs(argv) {
  const opts = {
    entryUrl: "",
    browser: "webkit",
    headless: false,
    taskId: "GOAL-XHS-ASSET-001",
    postId: "P01",
    noteId: "69ce60270000000021005d6c",
    operator: "lingguozhong",
    outDir: "",
    sync: false,
    keepOpen: false,
    noPrompt: false,
  };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--entry-url") {
      opts.entryUrl = argv[i + 1];
      i += 1;
      continue;
    }
    if (arg === "--browser") {
      opts.browser = argv[i + 1];
      i += 1;
      continue;
    }
    if (arg === "--headless") {
      opts.headless = true;
      continue;
    }
    if (arg === "--task-id") {
      opts.taskId = argv[i + 1];
      i += 1;
      continue;
    }
    if (arg === "--post-id") {
      opts.postId = argv[i + 1];
      i += 1;
      continue;
    }
    if (arg === "--note-id") {
      opts.noteId = argv[i + 1];
      i += 1;
      continue;
    }
    if (arg === "--operator") {
      opts.operator = argv[i + 1];
      i += 1;
      continue;
    }
    if (arg === "--out-dir") {
      opts.outDir = argv[i + 1];
      i += 1;
      continue;
    }
    if (arg === "--sync") {
      opts.sync = true;
      continue;
    }
    if (arg === "--keep-open") {
      opts.keepOpen = true;
      continue;
    }
    if (arg === "--no-prompt") {
      opts.noPrompt = true;
      continue;
    }
    if (arg === "--help" || arg === "-h") {
      usage();
      process.exit(0);
    }
    throw new Error(`Unknown argument: ${arg}`);
  }

  const normalized = (opts.browser || "").trim().toLowerCase();
  if (!["chromium", "webkit", "safari"].includes(normalized)) {
    throw new Error("--browser must be one of: chromium, webkit, safari");
  }
  opts.browser = normalized === "safari" ? "webkit" : normalized;
  if (!opts.entryUrl) {
    opts.entryUrl = `https://creator.xiaohongshu.com/statistics/note-detail?noteId=${encodeURIComponent(
      opts.noteId
    )}`;
  }
  return opts;
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

function localIsoWithOffset(date = new Date()) {
  const pad = (n) => String(n).padStart(2, "0");
  const y = date.getFullYear();
  const m = pad(date.getMonth() + 1);
  const d = pad(date.getDate());
  const hh = pad(date.getHours());
  const mm = pad(date.getMinutes());
  const ss = pad(date.getSeconds());
  const offsetMin = -date.getTimezoneOffset();
  const sign = offsetMin >= 0 ? "+" : "-";
  const abs = Math.abs(offsetMin);
  const oh = pad(Math.floor(abs / 60));
  const om = pad(abs % 60);
  return `${y}-${m}-${d}T${hh}:${mm}:${ss}${sign}${oh}:${om}`;
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
      "[xhs-review24h-auto] 浏览器保持打开。完成人工确认后输入 CLOSE 并回车，我再关闭浏览器。"
    );
    if (answer.toUpperCase() === "CLOSE") {
      await context.close();
      return;
    }
    console.log("[xhs-review24h-auto] 未收到 CLOSE，浏览器继续保持打开。");
  }
}

function parseNumberToken(token) {
  if (!token) {
    return null;
  }
  const cleaned = token.replace(/,/g, "").replace(/\s+/g, "");
  const matched = cleaned.match(/^([0-9]+(?:\.[0-9]+)?)(万|亿)?$/);
  if (!matched) {
    return null;
  }
  const base = Number.parseFloat(matched[1]);
  if (!Number.isFinite(base)) {
    return null;
  }
  const unit = matched[2] || "";
  let value = base;
  if (unit === "万") {
    value = base * 10000;
  } else if (unit === "亿") {
    value = base * 100000000;
  }
  return Math.round(value);
}

function extractFirstNumberFromLine(line) {
  if (!line) {
    return null;
  }
  // Some XHS metric cards show "-" when value is zero or temporarily unavailable.
  // Treat this as 0 so collection can continue without manual fallback.
  if (/(^|[^0-9])-($|[^0-9])/.test(line)) {
    return 0;
  }
  const matched = line.match(/([0-9]+(?:\.[0-9]+)?\s*(?:万|亿)?)/);
  if (!matched) {
    return null;
  }
  return parseNumberToken(matched[1]);
}

function lineContainsAny(line, regexes) {
  return regexes.some((re) => re.test(line));
}

function extractMetricByLabels(lines, labelRegexes) {
  for (let i = 0; i < lines.length; i += 1) {
    const line = lines[i];
    if (!lineContainsAny(line, labelRegexes)) {
      continue;
    }

    const sameLineValue = extractFirstNumberFromLine(line);
    if (sameLineValue !== null) {
      return sameLineValue;
    }

    const nearbyOffsets = [1, -1, 2, -2];
    for (const offset of nearbyOffsets) {
      const candidate = lines[i + offset];
      const nearbyValue = extractFirstNumberFromLine(candidate || "");
      if (nearbyValue !== null) {
        return nearbyValue;
      }
    }
  }
  return null;
}

function inferNoteStatusFromText(text) {
  if (/(违规|下线|不可见|封禁|处罚)/.test(text)) {
    return "down";
  }
  if (/(限流|异常|风险提示|审核中|降权)/.test(text)) {
    return "limited";
  }
  return "normal";
}

function parseMetricsFromText(rawText) {
  const text = String(rawText || "");
  const lines = text
    .split(/\n+/)
    .map((line) => line.trim())
    .filter(Boolean);

  const metrics = {
    views: extractMetricByLabels(lines, [/阅读/, /曝光/, /浏览/, /曝光数/, /阅读数/]),
    likes: extractMetricByLabels(lines, [/点赞/]),
    saves: extractMetricByLabels(lines, [/收藏/]),
    comments: extractMetricByLabels(lines, [/评论/]),
    shares: extractMetricByLabels(lines, [/分享/]),
    follows: extractMetricByLabels(lines, [/新增关注/, /新增粉丝/, /涨粉/, /关注新增/]),
    profile_visits: extractMetricByLabels(lines, [/主页访问/, /访问主页/, /主页访客/]),
    private_inquiries: extractMetricByLabels(lines, [/私信咨询/, /私信\/咨询/, /私信/, /咨询/]),
  };

  const missing = Object.entries(metrics)
    .filter(([, value]) => value === null)
    .map(([key]) => key);

  return {
    metrics,
    missing,
    note_status: inferNoteStatusFromText(text),
  };
}

function isLikelyNoteMetricsPage(url, text) {
  const pageUrl = String(url || "");
  const pageText = String(text || "");
  if (/\/statistics\/note-detail/.test(pageUrl)) {
    return true;
  }
  return /(笔记数据详情|核心数据|曝光数|观看数|点赞数|评论数|收藏数|分享数)/.test(pageText);
}

async function main() {
  const opts = parseArgs(process.argv.slice(2));

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

  const browserType = playwright[opts.browser];
  if (!browserType) {
    throw new Error(`Unsupported browser type: ${opts.browser}`);
  }

  const profileDir = path.resolve(path.join(process.cwd(), "runtime", "host_bridge_profile"));
  fs.mkdirSync(profileDir, { recursive: true, mode: 0o700 });

  const ts = timestampUtc();
  const outDir = path.resolve(
    opts.outDir || path.join(process.cwd(), "runtime", "publish_evidence", `review_24h_auto_${ts}`)
  );
  fs.mkdirSync(outDir, { recursive: true, mode: 0o700 });

  const metricsPath = path.join(outDir, "p01_24h_metrics.json");
  const reportPath = path.join(outDir, "autocollect_report.json");
  const textPath = path.join(outDir, "autocollect_page_text.txt");

  console.log(`[xhs-review24h-auto] browser=${opts.browser}`);
  console.log(`[xhs-review24h-auto] entry_url=${opts.entryUrl}`);
  console.log(`[xhs-review24h-auto] out_dir=${outDir}`);

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

  let page = context.pages()[0] || (await context.newPage());

  try {
    await page.goto(opts.entryUrl, { waitUntil: "domcontentloaded", timeout: 90000 });
    if (opts.noPrompt) {
      console.log("[xhs-review24h-auto] --no-prompt enabled, auto-collecting from current page.");
      await page.waitForTimeout(700);
    } else {
      console.log("[xhs-review24h-auto] 请手动切到目标笔记的数据页（24h指标可见页面）。");
      await promptEnter("[xhs-review24h-auto] 页面准备好后按回车继续采集...");
    }

    const pages = context.pages().filter((p) => !p.isClosed());
    page = pages[pages.length - 1] || page;
    await page.bringToFront().catch(() => {});
    await page.waitForTimeout(800);

    const pageData = await page.evaluate(() => {
      const text = (document.body && document.body.innerText) || "";
      return {
        url: location.href,
        title: document.title || "",
        text,
      };
    });

    fs.writeFileSync(textPath, `${pageData.text}\n`, { mode: 0o600 });

    if (!isLikelyNoteMetricsPage(pageData.url, pageData.text)) {
      const report = {
        action: "xhs_review24h_autocollect",
        source_url: pageData.url,
        source_title: pageData.title,
        task_id: opts.taskId,
        post_id: opts.postId,
        note_id: opts.noteId,
        snapshot_time: localIsoWithOffset(new Date()),
        error: "not_note_metrics_page",
        message: "当前页面不是笔记数据详情页，已停止采集以避免误采。",
        output_page_text: textPath,
      };
      fs.writeFileSync(reportPath, `${JSON.stringify(report, null, 2)}\n`, { mode: 0o600 });
      console.log("[xhs-review24h-auto] 当前页面不是目标笔记数据页，已停止。");
      console.log(`[xhs-review24h-auto] report saved: ${reportPath}`);
      await closeWithPolicy(context, opts.keepOpen);
      process.exit(2);
    }

    const parsed = parseMetricsFromText(pageData.text);
    const snapshotTime = localIsoWithOffset(new Date());
    const autoFilled = [];
    for (const key of Object.keys(parsed.metrics)) {
      if (parsed.metrics[key] === null) {
        parsed.metrics[key] = 0;
        autoFilled.push(key);
      }
    }

    const payload = {
      task_id: opts.taskId,
      post_id: opts.postId,
      note_id: opts.noteId,
      snapshot_time: snapshotTime,
      snapshot_mode: "delayed_backfill",
      note_status: parsed.note_status,
      views: parsed.metrics.views,
      likes: parsed.metrics.likes,
      saves: parsed.metrics.saves,
      comments: parsed.metrics.comments,
      shares: parsed.metrics.shares,
      follows: parsed.metrics.follows,
      profile_visits: parsed.metrics.profile_visits,
      private_inquiries: parsed.metrics.private_inquiries,
      comment_topics: ["auto_collected_pending_manual_semantic_review"],
      negative_signals: ["none"],
      operator: opts.operator,
      auto_filled_fields: autoFilled,
    };

    const report = {
      action: "xhs_review24h_autocollect",
      source_url: pageData.url,
      source_title: pageData.title,
      task_id: opts.taskId,
      post_id: opts.postId,
      note_id: opts.noteId,
      snapshot_time: snapshotTime,
      missing_fields: parsed.missing,
      auto_filled_fields: autoFilled,
      output_metrics_json: metricsPath,
      output_page_text: textPath,
    };

    fs.writeFileSync(reportPath, `${JSON.stringify(report, null, 2)}\n`, { mode: 0o600 });

    fs.writeFileSync(metricsPath, `${JSON.stringify(payload, null, 2)}\n`, { mode: 0o600 });
    console.log(`[xhs-review24h-auto] metrics saved: ${metricsPath}`);
    console.log(`[xhs-review24h-auto] report saved: ${reportPath}`);
    if (autoFilled.length > 0) {
      console.log(
        `[xhs-review24h-auto] auto-filled missing fields as 0: ${autoFilled.join(", ")}`
      );
    }

    if (opts.sync) {
      const syncCmd = ["./scripts/xhs_review24h_sync.sh", "--review-json", metricsPath, "--json"];
      console.log(`[xhs-review24h-auto] sync: bash ${syncCmd.join(" ")}`);
      const result = spawnSync("bash", syncCmd, {
        stdio: "inherit",
        cwd: process.cwd(),
      });
      if (result.status !== 0) {
        await closeWithPolicy(context, opts.keepOpen);
        process.exit(result.status || 1);
      }
    }

    await closeWithPolicy(context, opts.keepOpen);
  } catch (err) {
    await closeWithPolicy(context, opts.keepOpen);
    throw err;
  }
}

main().catch((err) => {
  const message = err && err.stack ? err.stack : String(err);
  console.error(`[xhs-review24h-auto] error: ${message}`);
  process.exit(1);
});
