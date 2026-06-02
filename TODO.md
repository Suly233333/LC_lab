# TODO.md - Project Moon Life Record (L-Corp Edition)

> 目标平台：**Android**（v1.0 仅发布安卓端）。开发期间使用 Android 真机或模拟器调试。

## 第一阶段：项目初始化与 UI 基建

- [x] **1.1** 执行 `flutter create --platforms=android`，在 `pubspec.yaml` 中引入依赖：`flutter_riverpod`, `sqflite`, `path`, `intl`, `image_picker`, `permission_handler`, `path_provider`
- [x] **1.2** 在 `android/app/build.gradle` 中设置 `minSdkVersion 26`、`targetSdkVersion` 跟随 Flutter 默认；在 `AndroidManifest.xml` 申请权限：`RECORD_AUDIO` / `READ_MEDIA_IMAGES`
- [ ] **1.3** 在 `lib/core/theme.dart` 中定义 `AppTheme`：背景色 `#121212`，主强调色 `#FFD700`，次背景 `#262626`，警告色 `#FF8F00`
- [ ] **1.4** 开发 `LCorpGridBackground` 组件，在全局背景上渲染极细暗黄网格线
- [ ] **1.5** 配置 `TerminalText` 等宽字体样式，封装带扫描线动效的 `LCorpButton`

---

## 第二阶段：核心数据模型

- [x] **2.1** 实现 `lib/models/abnormality.dart`，包含 `Abnormality` 类与 `BreachType` 枚举（escape / penaltyBox / none），并包含字段：`requiredResonance` / `currentResonance`（标注为隐藏字段）、`energyLevel`（默认 50）、`qliphothCounter` / `qliphothMax`、`penaltyAmount`、`escapeDrain`、`workReactions`（key 格式 `{workType}_{result}`）
- [x] **2.2** 实现 `lib/models/diary_entry.dart`，字段包括：`content`（Markdown）、`attachments`、`cognitiveFilters`、`resonanceDeltas`（隐藏字段，对各异想体的共鸣度增量）、`createdAt`；**不包含** `abnormalityId` 与 `workType`
- [x] **2.3** 实现 `lib/models/work_log.dart`：包含 `abnormalityId` / `agentId` / `workType` / `success` / `isCriticalFail` / `peBoxGained` / `createdAt`，作为工作执行的独立记录
- [x] **2.4** 实现 `lib/models/agent.dart`（HP、`maxHp` 默认 100、四维 `aptitude`、装备槽 `equippedEgoIds`）与 `lib/models/ego_gear.dart`（包含 `bonusStats.suppression` 用于镇压加成）
- [x] **2.5** 实现 `lib/models/daily_state.dart`，管理每日提取候选与解锁配额（按自然日 0:00 重置）
- [x] **2.6** 编写 `assets/presets/abnormalities.json`，包含「一罪与百善」与「老妇人」两条初始预设（字段需与 AGENT.md 6.1 / 6.2 完全对齐：`requiredResonance` / `escapeDrain` / 完整 `workReactions` 含 success 与 fail），并实现解析加载逻辑

---

## 第三阶段：本地数据库层（sqflite）

- [ ] **3.1** 编写 `lib/core/database_helper.dart`，初始化并创建 `diary_entries`、`work_logs`、`abnormalities`、`agents`、`ego_inventory` 五张表
- [ ] **3.2** 实现异想体的 CRUD：解锁状态、`currentResonance`、`qliphothCounter`、`energyLevel`、PE Box 余额（全局）的持久化
- [ ] **3.3** 实现日记条目与工作记录的存储，并支持按日期索引查询

---

## 第四阶段：状态管理与共鸣度引擎（Riverpod）

- [ ] **4.1** 使用 `StateNotifierProvider` 建立全局状态：已解锁异想体列表、日记列表、PE Box 计数（下限 0）、当日提取状态
- [ ] **4.2** 实现共鸣度引擎 `ResonanceService`：将日记内容（文本 + cognitiveFilters）提交给大模型，要求其返回结构化 JSON `{abnormalityId: delta}`，写入 `DiaryEntry.resonanceDeltas` 并累加到对应 `Abnormality.currentResonance`；**严禁将共鸣度数值暴露给 UI 层**
- [ ] **4.3** 实现每日提取逻辑：当 `currentResonance ≥ requiredResonance` **且** 累计天数 ≥ `requiredDays` 时进入候选池；每天随机抽取 3 个候选，按自然日 0:00 重置；用户每日最多解锁 1 个
- [ ] **4.4** 实现定时任务：每 8 小时检测每个已解锁异想体是否有互动（写日记不算，需为工作执行），无互动则 `qliphothCounter -1`

---

## 第五阶段：日记系统 UI

- [ ] **5.1** 开发日志列表页 `ObservationLogsPage`：L-Corp 风格卡片列表，不显示任何共鸣度进度条
- [ ] **5.2** 开发日志编辑页 `NewEntryPage`（**仅记录观测，不选择异想体也不选择工作类型**）：
  - Markdown 文本输入
  - 用户可添加预设或自定义标签
  - 图片/音频附件上传（`image_picker`）
  - 认知滤网标签输入（支持预设 + 自定义，带机密标签样式）

---

## 第六阶段：异想体管理与工作系统 UI

- [ ] **6.1** 开发异想体档案库页 `AbnormalityGalleryPage`：未解锁项显示黄黑斜纹"Caution"遮盖板
- [ ] **6.2** 实现提取仪式动画 `ExtractionCeremonyWidget`：黄色光栅扫描线上下滚动，揭晓档案立绘
- [ ] **6.3** 开发工作交互界面：四种工作按钮（本能/洞察/沟通/压迫），实现成功率公式 `clamp(weight × aptitude / 10, 0.05, 0.95)`，处理大失败（成功率 < 20% 且判定失败时 `qliphothCounter -1`），PE Box 产出 `floor(weight × aptitude × 2)`，每次工作生成 `WorkLog` 记录
- [ ] **6.4** 实现 `energyLevel` 变化与消极状态：成功 +10 / 失败 -15（消极状态下保底 +5），归零进入消极状态（权重 ×0.5），恢复到 30 以上解除
- [ ] **6.5** 实现沟通工作的对话气泡 UI，预留大模型 API 调用占位符（`AttachmentService.mockResponse()`）
- [ ] **6.6** 实现工作反馈展示：根据 `success/fail` 从 `workReactions[{workType}_{result}]` 读取文案

---

## 第七阶段：突破机制、出逃镇压与 EGO 商店

- [ ] **7.1** 开发 LED 风格逆卡巴拉计数器组件 `QliphothCounterWidget`，实时反映计数器变化
- [ ] **7.2** 实现突破警报 `BreachAlertOverlay`：全屏黑黄交替闪烁 + "ERROR"像素化抖动动效
- [ ] **7.3** 根据 `breachType` 实现惩罚逻辑：
  - `none` → 仅重置计数器
  - `penaltyBox` → 立即扣除 `penaltyAmount`% 的 PE Box（PE Box clamp ≥ 0）
  - `escape` → 进入出逃状态，每分钟扣除 `escapeDrain` PE Box
- [ ] **7.4** 实现出逃与镇压：主管可选镇压或不镇压；不镇压则 30 分钟后自动返回；镇压成功率 `clamp(Σ(equippedEgo.bonusStats[suppression] × 0.1) + 0.2, 0.1, 0.9)`，成功奖励 `floor(qliphothMax × 2)` PE Box，失败员工 HP -20（HP clamp ≥ 0）
- [ ] **7.5** 实现员工受伤机制：HP 归零进入"受伤"状态无法工作，每小时自然恢复 10 HP（clamp 至 `maxHp`）
- [ ] **7.6** 实现 EGO 装备商店 `EgoShopPage`：PE Box 消费兑换装备，员工详情页支持穿脱

---

## 第八阶段：收尾与调试

- [ ] **8.1** 每日解锁限额校验：硬限制每日最多解锁 1 个，累计记录天数上限 30 天
- [ ] **8.2** 全页面主题一致性检查：确保黄黑配色在所有页面正确渲染
- [ ] **8.3** 运行 `flutter analyze` + `flutter test` 修复所有警告与报错
- [ ] **8.4** 回归验证：所有共鸣度数值（`currentResonance` / `resonanceDeltas` / `requiredResonance`）在任何 UI 界面均不可见