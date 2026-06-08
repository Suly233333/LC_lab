# TODO.md - Project Moon Life Record (L-Corp Edition)

> 目标平台：**Android**（v1.0 仅发布安卓端）。开发期间使用 Android 真机或模拟器调试。
> v1.1 精简版：仅保留**日记记录 / 共鸣度累计 / 异想体对话**三大核心模块。

## 第一阶段：项目初始化与 UI 基建

- [x] **1.1** 执行 `flutter create --platforms=android`，在 `pubspec.yaml` 中引入依赖：`flutter_riverpod`, `sqflite`, `path`, `intl`, `image_picker`, `permission_handler`, `path_provider`
- [x] **1.2** 在 `android/app/build.gradle` 中设置 `minSdkVersion 26`、`targetSdkVersion` 跟随 Flutter 默认；在 `AndroidManifest.xml` 申请权限：`RECORD_AUDIO` / `READ_MEDIA_IMAGES`
- [x] **1.3** 在 `lib/core/theme.dart` 中定义 `AppTheme`：背景色 `#0F1620`，主强调色 `#2D7DF6`，次背景 `#1B2330`，警告色 `#E53935`
- [x] **1.4** 开发 `LCorpGridBackground` 组件，在全局背景上渲染极细半透明蓝色网格线
- [x] **1.5** 配置 `TerminalText` 等宽字体样式，封装 `LCorpButton`

---

## 第二阶段：核心数据模型

- [x] **2.1** 实现 `lib/models/abnormality.dart`，包含 `Abnormality` 类，字段精简为：`id` / `name` / `grade` / `featureTags` / `requiredDays` / `requiredResonance` / `currentResonance`（隐藏字段）/ `isUnlocked` / `isInitial` / `unlockDate` / `description` / `manageNote`
- [x] **2.2** 实现 `lib/models/diary_entry.dart`，字段包括：`content`（Markdown）、`attachments`、`cognitiveFilters`、`resonanceDeltas`（隐藏字段，对各异想体的共鸣度增量）、`createdAt`；**不包含** `abnormalityId`
- [x] **2.6** 编写 `assets/presets/abnormalities.json`，包含「一罪与百善」与「老妇人」两条初始预设（字段需与 AGENT.md 6.1 / 6.2 完全对齐：`requiredResonance` / `requiredDays` / `description` / `manageNote`），并实现解析加载逻辑

---

## 第三阶段：本地数据库层（sqflite）

- [x] **3.1** 编写 `lib/core/database_helper.dart`，初始化并创建 `diary_entries`、`abnormalities` 两张表
- [x] **3.2** 实现异想体的 CRUD：解锁状态、`currentResonance` 的持久化
- [x] **3.3** 实现日记条目的存储，并支持按日期索引查询

---

## 第四阶段：状态管理与共鸣度引擎（Riverpod）

- [x] **4.1** 使用 `AsyncNotifierProvider` 建立全局状态：异想体列表、日记列表；新增 `pendingUnlocksProvider` 用于驱动解锁仪式动画
- [x] **4.2** 实现共鸣度引擎 `ResonanceService`：将日记内容（文本 + cognitiveFilters）提交给大模型，要求其返回结构化 JSON `{abnormalityId: delta}`，写入 `DiaryEntry.resonanceDeltas` 并累加到对应 `Abnormality.currentResonance`；**严禁将共鸣度数值暴露给 UI 层**
- [x] **4.3** 实现 `UnlockService.evaluateAutoUnlock()`：当 `currentResonance ≥ requiredResonance` **且** 累计天数 ≥ `requiredDays` 时立即自动解锁，并通过 `pendingUnlocksProvider` 通知 UI 弹仪式动画

---

## 第五阶段：日记系统 UI

- [x] **5.1** 开发日志列表页 `ObservationLogsPage`：L-Corp 风格卡片列表，不显示任何共鸣度进度条
- [x] **5.2** 开发日志编辑页 `NewEntryPage`（**仅记录观测，不选择异想体**）：
  - Markdown 文本输入
  - 用户可添加预设或自定义标签
  - 图片/音频附件上传（`image_picker`）
  - 认知滤网标签输入（支持预设 + 自定义，带机密标签样式）

---

## 第六阶段：异想体档案库与对话 UI

- [x] **6.1** 开发异想体档案库页 `AbnormalityGalleryPage`：未解锁项显示警报红/近黑斜纹"Caution"遮盖板；点击已解锁卡片进入详情/对话页
- [x] **6.2** 实现自动解锁仪式动画 `ExtractionCeremonyWidget`：扫描线上下滚动，揭晓档案立绘；由 `pendingUnlocksProvider` 驱动
- [x] **6.5** 开发独立的异想体对话页 `AttachmentChatPage`：接入 CharGLM/GLM；异想体偶尔主动反问；不再有"工作结算"流程

---

## 第八阶段：收尾与调试

- [x] **8.2** 全页面主题一致性检查：确保 L-Corp 配色在所有页面正确渲染
- [x] **8.3** 运行 `flutter analyze` + `flutter test` 修复所有警告与报错
- [x] **8.4** 回归验证：所有共鸣度数值（`currentResonance` / `resonanceDeltas` / `requiredResonance`）在任何 UI 界面均不可见

---

## 第九阶段：精简化重构（v1.1）

- [x] **9.1** 删除工作系统：`work_service` / `work_log` 模型 / `work_log_repository`
- [x] **9.2** 删除突破 / 镇压 / 出逃：`breach_service` / `breach_alert_overlay` / `qliphoth_counter_widget` / `qliphoth_scheduler`
- [x] **9.3** 删除员工 Agent：`agent` 模型 / `agent_repository` / `agent_panel_page`
- [x] **9.4** 删除 EGO 装备：`ego_gear` 模型 / `ego_repository` / `ego_shop_service` / `ego_shop_page` / `ego_gears.json`
- [x] **9.5** 删除 PE Box 余额、`DailyState`、每日 3 选 1 提取池逻辑
- [x] **9.6** 精简 `Abnormality` 模型：去除 `workTypeWeights` / `workReactions` / `qliphothCounter` / `qliphothMax` / `breachType` / `penaltyAmount` / `escapeDrain` / `isEscaped` / `escapeStartedAt` / `energyLevel` / `BreachType` 枚举
- [x] **9.7** 数据库 schema 升级 v3：DROP 所有旧表后重建，仅保留 `abnormalities` 与 `diary_entries`
- [x] **9.8** 详情页重写为简化版：立绘 + 等级 + 描述 + 管理备注 + `BEGIN COMMUNICATION` 按钮
- [x] **9.9** 同步更新 AGENT.md / TODO.md / README.md
