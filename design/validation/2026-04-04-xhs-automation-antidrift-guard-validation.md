# 2026-04-04 XHS 自动化防跑偏与一键流水线验证

## 目标

- 将 `publish_job` 进入 bridge 前的人工审读替换为脚本闸门。
- 将“发布后回执登记 + 24h 采集同步”改为一键执行路径，减少人工步骤。

## 变更清单

- 新增：`scripts/xhs_publish_job_guard.js`
- 新增：`scripts/xhs_argus_prep_gate.sh`
- 新增：`scripts/xhs_publish_receipt_autoreg.js`
- 新增：`scripts/xhs_post_publish_oneclick.sh`
- 更新：`scripts/xhs_bridge_run.sh`（接入 publish_job guard）
- 更新：`scripts/xhs_pull_publish_job.sh`（容器图片路径归一化）
- 更新：`scripts/xhs_review24h_autocollect.js`（新增 `--no-prompt`）

## 关键验证

### 1) 防跑偏闸门阻断验证（失败路径）

- 命令：
  - `bash ./scripts/xhs_argus_prep_gate.sh --task-id GOAL-XHS-ASSET-001 --post-id P02 --json`
- 结果：
  - 首次返回 `ok=false`
  - 错误包含 `image_not_found` / `cover_not_found`（容器绝对路径在宿主不可用）
- 结论：
  - 闸门可识别“路径口径跑偏”，并阻断继续进入 bridge。

### 2) 路径归一化修复后通过验证（成功路径）

- 修复：
  - `xhs_pull_publish_job.sh` 自动将 `cover_file/image_files` 的容器绝对路径归一化为文件名。
- 命令：
  - `bash ./scripts/xhs_argus_prep_gate.sh --task-id GOAL-XHS-ASSET-001 --post-id P02 --json`
- 结果：
  - 返回 `ok=true`
  - 输出下一步命令可直接进入 host bridge。
- 结论：
  - 发布包可被稳定拉取并通过宿主机桥接验收。

### 3) 发布回执自动登记验证

- 命令：
  - `node ./scripts/xhs_publish_receipt_autoreg.js --task-id GOAL-XHS-ASSET-001 --post-id P02 --operator lingguozhong --browser webkit --headless --json`
- 结果：
  - 返回 `ok=true`
  - 自动识别 `note_id=69d0c4a9000000001d01ecce`
  - 自动写入容器 `publish_receipt.json`
- 结论：
  - 不再需要手工回填 `note_id/post_url/publish_time/operator`。

### 4) 一键流水线脚本静态验证

- 命令：
  - `bash -n ./scripts/xhs_post_publish_oneclick.sh`
  - `node --check ./scripts/xhs_publish_receipt_autoreg.js`
  - `node --check ./scripts/xhs_review24h_autocollect.js`
- 结果：
  - 语法检查通过。
- 结论：
  - 一键脚本满足可执行条件，可进入运行期验证。

## 运行口径（事件驱动）

- 发布完成事件触发：
  - 执行 `xhs_post_publish_oneclick.sh`
  - 自动完成回执登记
- 若未到 24h：
  - 自动返回 `review_pending` 与下一次可执行提示
- 若已到 24h 或强制补录：
  - 自动执行 `xhs_review24h_autocollect --no-prompt --sync`

## 边界保持

- 不自动点击发布按钮
- 不扩容
- 不改阈值
- 不关闭 RH-T5-B01
