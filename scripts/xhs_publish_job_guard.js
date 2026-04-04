#!/usr/bin/env node
"use strict";

const fs = require("node:fs");
const path = require("node:path");

function usage() {
  console.log(
    [
      "Usage:",
      "  node scripts/xhs_publish_job_guard.js --job <publish_job.json> [--json]",
      "",
      "Checks:",
      "  - required keys and types",
      "  - stop_before_publish must be true",
      "  - image files exist under material_dir",
      "  - no placeholder token like <...> in key fields",
      "  - operator_checklist must include stop-before-publish semantics",
    ].join("\n")
  );
}

function parseArgs(argv) {
  const opts = {
    jobPath: "",
    json: false,
  };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--job") {
      opts.jobPath = argv[i + 1] || "";
      i += 1;
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
  if (!opts.jobPath) {
    throw new Error("Missing required argument: --job <publish_job.json>");
  }
  return opts;
}

function isNonEmptyString(v) {
  return typeof v === "string" && v.trim() !== "";
}

function hasPlaceholder(v) {
  if (!isNonEmptyString(v)) {
    return false;
  }
  return /<[^>]*>/.test(v);
}

function checkArrayOfStrings(v) {
  return Array.isArray(v) && v.length > 0 && v.every((x) => typeof x === "string" && x.trim() !== "");
}

function addIssue(arr, code, detail) {
  arr.push({ code, detail });
}

function main() {
  const opts = parseArgs(process.argv.slice(2));
  const jobAbs = path.resolve(opts.jobPath);

  const errors = [];
  const warnings = [];

  if (!fs.existsSync(jobAbs)) {
    addIssue(errors, "job_not_found", jobAbs);
    reportAndExit({
      ok: false,
      job: jobAbs,
      errors,
      warnings,
      json: opts.json,
    });
    return;
  }

  let raw = "";
  let job = null;
  try {
    raw = fs.readFileSync(jobAbs, "utf8");
  } catch (err) {
    addIssue(errors, "job_read_failed", String(err.message || err));
    reportAndExit({
      ok: false,
      job: jobAbs,
      errors,
      warnings,
      json: opts.json,
    });
    return;
  }

  try {
    job = JSON.parse(raw);
  } catch (err) {
    addIssue(errors, "job_invalid_json", String(err.message || err));
    reportAndExit({
      ok: false,
      job: jobAbs,
      errors,
      warnings,
      json: opts.json,
    });
    return;
  }

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
    if (!isNonEmptyString(job[key])) {
      addIssue(errors, "missing_or_empty_string", key);
    }
  }

  if (job.stop_before_publish !== true) {
    addIssue(errors, "stop_before_publish_not_true", "stop_before_publish must be true");
  }

  if (!checkArrayOfStrings(job.title_candidates)) {
    addIssue(errors, "invalid_title_candidates", "title_candidates must be non-empty string array");
  }
  if (!checkArrayOfStrings(job.hashtags)) {
    addIssue(errors, "invalid_hashtags", "hashtags must be non-empty string array");
  }
  if (!checkArrayOfStrings(job.image_files)) {
    addIssue(errors, "invalid_image_files", "image_files must be non-empty string array");
  }
  if (!checkArrayOfStrings(job.operator_checklist)) {
    addIssue(errors, "invalid_operator_checklist", "operator_checklist must be non-empty string array");
  }
  if (!job.evidence_ref || typeof job.evidence_ref !== "object" || Array.isArray(job.evidence_ref)) {
    addIssue(errors, "invalid_evidence_ref", "evidence_ref must be object");
  }

  const placeholderCheckKeys = [
    "final_title",
    "body_text",
    "first_comment",
    "material_dir",
    "cover_file",
  ];
  for (const key of placeholderCheckKeys) {
    if (hasPlaceholder(job[key])) {
      addIssue(errors, "placeholder_token_detected", key);
    }
  }

  if (Array.isArray(job.hashtags)) {
    for (let i = 0; i < job.hashtags.length; i += 1) {
      if (hasPlaceholder(job.hashtags[i])) {
        addIssue(errors, "placeholder_token_detected", `hashtags[${i}]`);
      }
    }
  }

  if (Array.isArray(job.image_files)) {
    for (let i = 0; i < job.image_files.length; i += 1) {
      if (hasPlaceholder(job.image_files[i])) {
        addIssue(errors, "placeholder_token_detected", `image_files[${i}]`);
      }
    }
  }

  if (Array.isArray(job.operator_checklist)) {
    const merged = job.operator_checklist.join(" ");
    if (!/发布按钮前|stop_before_publish|不自动点击发布|手动确认/.test(merged)) {
      addIssue(
        errors,
        "checklist_missing_stop_gate",
        "operator_checklist must include stop-before-publish semantics"
      );
    }
  }

  if (isNonEmptyString(job.material_dir) && Array.isArray(job.image_files)) {
    const materialDir = path.resolve(job.material_dir);
    for (const image of job.image_files) {
      const imagePath = path.resolve(materialDir, image);
      if (!fs.existsSync(imagePath)) {
        addIssue(errors, "image_not_found", imagePath);
      }
    }
    const coverPath = path.resolve(materialDir, String(job.cover_file || ""));
    if (!fs.existsSync(coverPath)) {
      addIssue(errors, "cover_not_found", coverPath);
    }
  }

  if (isNonEmptyString(job.platform) && !/xiaohongshu|小红书/i.test(job.platform)) {
    addIssue(warnings, "platform_unexpected", String(job.platform));
  }

  const ok = errors.length === 0;
  reportAndExit({
    ok,
    job: jobAbs,
    errors,
    warnings,
    json: opts.json,
  });
}

function reportAndExit({ ok, job, errors, warnings, json }) {
  const summary = {
    action: "xhs_publish_job_guard",
    ok,
    job,
    errors,
    warnings,
  };
  if (json) {
    process.stdout.write(`${JSON.stringify(summary, null, 2)}\n`);
  } else if (ok) {
    console.log(`[xhs-job-guard] ok: ${job}`);
  } else {
    console.log(`[xhs-job-guard] blocked: ${job}`);
    for (const e of errors) {
      console.log(`- ERROR ${e.code}: ${e.detail}`);
    }
    for (const w of warnings) {
      console.log(`- WARN  ${w.code}: ${w.detail}`);
    }
  }
  process.exit(ok ? 0 : 2);
}

main();
