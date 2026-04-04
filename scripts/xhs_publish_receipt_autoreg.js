#!/usr/bin/env node
"use strict";

const fs = require("node:fs");
const path = require("node:path");
const { spawnSync } = require("node:child_process");

function usage() {
  console.log(
    [
      "Usage:",
      "  node scripts/xhs_publish_receipt_autoreg.js [options]",
      "",
      "Options:",
      "  --task-id <id>         default GOAL-XHS-ASSET-001",
      "  --post-id <id>         default P02",
      "  --operator <name>      default lingguozhong",
      "  --container <name>     default agent_argus",
      "  --profile-url <url>    default env XHS_PROFILE_URL or public profile URL",
      "  --browser <name>       chromium | webkit | safari(=webkit), default webkit",
      "  --headless             run in headless mode",
      "  --json                 print JSON summary",
      "  -h, --help             show help",
      "",
      "What it does:",
      "  1) Find latest publish_job in Argus container for task/post",
      "  2) Open profile page and auto-detect latest /explore/<note_id> link",
      "  3) Build publish_receipt.json using current local time",
      "  4) Copy publish_receipt.json to container target output dir",
    ].join("\n")
  );
}

function parseArgs(argv) {
  const opts = {
    taskId: "GOAL-XHS-ASSET-001",
    postId: "P02",
    operator: "lingguozhong",
    container: "agent_argus",
    profileUrl:
      process.env.XHS_PROFILE_URL ||
      "https://www.xiaohongshu.com/user/profile/69cb5578000000003402cff4",
    browser: "webkit",
    headless: false,
    json: false,
  };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--task-id") {
      opts.taskId = argv[i + 1] || "";
      i += 1;
      continue;
    }
    if (arg === "--post-id") {
      opts.postId = argv[i + 1] || "";
      i += 1;
      continue;
    }
    if (arg === "--operator") {
      opts.operator = argv[i + 1] || "";
      i += 1;
      continue;
    }
    if (arg === "--container") {
      opts.container = argv[i + 1] || "";
      i += 1;
      continue;
    }
    if (arg === "--profile-url") {
      opts.profileUrl = argv[i + 1] || "";
      i += 1;
      continue;
    }
    if (arg === "--browser") {
      opts.browser = argv[i + 1] || "";
      i += 1;
      continue;
    }
    if (arg === "--headless") {
      opts.headless = true;
      continue;
    }
    if (arg === "--json") {
      opts.json = true;
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
  return opts;
}

function mustRun(cmd, args, opts = {}) {
  const result = spawnSync(cmd, args, { encoding: "utf8", ...opts });
  if (result.status !== 0) {
    const stderr = (result.stderr || "").trim();
    const stdout = (result.stdout || "").trim();
    throw new Error(
      `${cmd} ${args.join(" ")} failed (exit=${result.status})\n` +
        [stdout, stderr].filter(Boolean).join("\n")
    );
  }
  return result.stdout || "";
}

function timestampUtcCompact() {
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

function normalizePostUrl(url) {
  const raw = String(url || "").trim();
  if (!raw) {
    return "";
  }
  try {
    const u = new URL(raw.startsWith("http") ? raw : `https://www.xiaohongshu.com${raw}`);
    const matched = u.pathname.match(/\/explore\/([0-9a-z]{24,})/i);
    if (!matched) {
      return "";
    }
    return `https://www.xiaohongshu.com/explore/${matched[1]}`;
  } catch (_err) {
    return "";
  }
}

async function detectLatestNote({ profileUrl, browserName, headless, profileDir }) {
  const playwright = await import("playwright");
  const browserType = playwright[browserName];
  if (!browserType) {
    throw new Error(`Unsupported browser: ${browserName}`);
  }

  const context = await browserType.launchPersistentContext(profileDir, {
    headless,
    viewport: { width: 1440, height: 960 },
  });
  const page = context.pages()[0] || (await context.newPage());

  try {
    await page.goto(profileUrl, { waitUntil: "domcontentloaded", timeout: 90000 });
    await page.waitForTimeout(2200);

    const result = await page.evaluate(() => {
      const links = Array.from(document.querySelectorAll("a[href]"))
        .map((a) => a.getAttribute("href") || "")
        .filter(Boolean);
      const innerText = (document.body && document.body.innerText) || "";
      return {
        url: location.href,
        title: document.title || "",
        links,
        innerText,
      };
    });

    const candidates = [];
    for (const href of result.links) {
      if (/\/explore\/[0-9a-z]{24,}/i.test(href)) {
        const normalized = normalizePostUrl(href);
        if (normalized) {
          candidates.push(normalized);
        }
      }
    }

    const dedup = [...new Set(candidates)];
    const postUrl = dedup[0] || "";
    const noteIdMatch = postUrl.match(/\/explore\/([0-9a-z]{24,})/i);
    const noteId = noteIdMatch ? noteIdMatch[1] : "";

    const accountMatch = result.innerText.match(/小红书号[:：]\s*([0-9]+)/);
    const accountId = accountMatch ? accountMatch[1] : "";

    return {
      sourceUrl: result.url,
      sourceTitle: result.title,
      postUrl,
      noteId,
      accountId,
    };
  } finally {
    await context.close();
  }
}

async function main() {
  const opts = parseArgs(process.argv.slice(2));
  const ts = timestampUtcCompact();
  const projectRoot = process.cwd();
  const outDir = path.resolve(projectRoot, "runtime", "publish_evidence", `publish_receipt_auto_${ts}`);
  fs.mkdirSync(outDir, { recursive: true, mode: 0o700 });

  const jobPathRaw = mustRun(
    "docker",
    [
      "exec",
      opts.container,
      "sh",
      "-lc",
      `ls -1dt /root/.openclaw/workspace/steward/outputs/${opts.taskId}/${opts.postId}/*/publish_job.json 2>/dev/null | head -n 1`,
    ],
    {}
  ).trim();

  if (!jobPathRaw) {
    throw new Error(`publish_job not found in container for task=${opts.taskId} post=${opts.postId}`);
  }

  const targetDir = path.posix.dirname(jobPathRaw);
  const publishJobRaw = mustRun("docker", ["exec", opts.container, "sh", "-lc", `cat '${jobPathRaw}'`], {});
  const publishJob = JSON.parse(publishJobRaw);

  const profileDir = path.resolve(projectRoot, "runtime", "host_bridge_profile");
  fs.mkdirSync(profileDir, { recursive: true, mode: 0o700 });

  const detected = await detectLatestNote({
    profileUrl: opts.profileUrl,
    browserName: opts.browser,
    headless: opts.headless,
    profileDir,
  });

  if (!detected.noteId || !detected.postUrl) {
    const probePath = path.join(outDir, "probe_result.json");
    fs.writeFileSync(
      probePath,
      `${JSON.stringify(
        {
          action: "xhs_publish_receipt_autoreg",
          ok: false,
          error: "latest_note_not_detected",
          profileUrl: opts.profileUrl,
          detected,
        },
        null,
        2
      )}\n`,
      { mode: 0o600 }
    );
    throw new Error(`latest note not detected from profile page, see ${probePath}`);
  }

  const now = new Date();
  const receipt = {
    task_id: opts.taskId,
    post_id: opts.postId,
    platform: "xiaohongshu",
    account_id: detected.accountId || "",
    status: "published",
    publish_time_local: localIsoWithOffset(now),
    publish_time_utc: now.toISOString().replace(/\.\d{3}Z$/, "Z"),
    operator: opts.operator,
    publish_mode: "人工粘贴 + 人工点击发布",
    note_id: detected.noteId,
    post_url: detected.postUrl,
    evidence_ref: {
      export: publishJob?.evidence_ref?.export || "",
      preview: publishJob?.evidence_ref?.preview || "",
      manifest: publishJob?.evidence_ref?.manifest || "",
      publish:
        publishJob?.evidence_ref?.publish && publishJob.evidence_ref.publish !== "TBD_AFTER_MANUAL_PUBLISH"
          ? publishJob.evidence_ref.publish
          : `${opts.taskId}/${opts.postId}/publish/v1/${ts}`,
    },
  };

  const localReceiptPath = path.join(outDir, "publish_receipt.json");
  const localReportPath = path.join(outDir, "autoreg_report.json");
  fs.writeFileSync(localReceiptPath, `${JSON.stringify(receipt, null, 2)}\n`, { mode: 0o600 });

  mustRun("docker", ["cp", localReceiptPath, `${opts.container}:${targetDir}/publish_receipt.json`], {});

  const report = {
    action: "xhs_publish_receipt_autoreg",
    ok: true,
    task_id: opts.taskId,
    post_id: opts.postId,
    container: opts.container,
    source_profile_url: opts.profileUrl,
    container_publish_job_path: jobPathRaw,
    container_target_dir: targetDir,
    detected_note_id: detected.noteId,
    detected_post_url: detected.postUrl,
    local_receipt_path: localReceiptPath,
    local_report_path: localReportPath,
    next_event: "run 24h autocollect+sync after review window",
  };
  fs.writeFileSync(localReportPath, `${JSON.stringify(report, null, 2)}\n`, { mode: 0o600 });

  if (opts.json) {
    process.stdout.write(`${JSON.stringify(report, null, 2)}\n`);
  } else {
    console.log("[xhs-publish-receipt-auto] ok");
    console.log(`note_id=${detected.noteId}`);
    console.log(`post_url=${detected.postUrl}`);
    console.log(`container_target=${targetDir}/publish_receipt.json`);
    console.log(`local_receipt=${localReceiptPath}`);
    console.log(`report=${localReportPath}`);
  }
}

main().catch((err) => {
  console.error(`[xhs-publish-receipt-auto] error: ${err && err.message ? err.message : String(err)}`);
  process.exit(1);
});
