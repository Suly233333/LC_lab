# Project Moon Life Record · L-Corp Definitive Edition

> 一款基于脑叶公司（Lobotomy Corporation）工业风格的 **沉浸式生活记录与模拟管理 App**。
> 用 Flutter 开发，目标平台 **Android（v1.0）**。

主管，欢迎回到设施。
你今日记录下的每一段观测，都会成为某只未解锁异想体的低语。

---

## 1. 项目定位

- **观测**：写日记 → 大模型按"认知滤网（标签）"匹配未解锁异想体的语义特征 → 累计共鸣度
- **解锁**：满足共鸣度阈值与累计天数后进入提取池，每日 3 选 1 仪式提取
- **管理**：对已解锁异想体执行四种工作（本能 / 洞察 / 沟通 / 压迫），产出 PE Box，兑换 EGO 装备
- **危机**：忽视会触发逆卡巴拉计数器衰减、突破事件、出逃与镇压

> ⚠️ **神秘感原则**：共鸣度数值（`currentResonance` / `resonanceDeltas` / `requiredResonance`）
> **永远不会**在 UI 上以任何形式展示给用户。用户只能通过档案的"遮盖状态变化"
> 与"可提取提醒"来感知进度。

---

## 2. 技术栈

| 层 | 选型 |
| -- | -- |
| UI | Flutter 3.x · Material 3 · Dark theme |
| 状态管理 | flutter_riverpod 3.x（`AsyncNotifier` / `Provider`） |
| 本地存储 | sqflite + path_provider |
| 多媒体 | image_picker · permission_handler |
| 大模型 | 智谱 GLM（OpenAI 兼容 API） |
| - 共鸣度匹配 | `glm-4-flash`，`response_format=json_object` |
| - 沟通对话 | `charglm-4`，配合 `meta.bot_info` / `user_info` 严格扮演 |

---

## 3. 目录结构

```
lib/
├── core/                  # 主题、数据库、仓库、GLM 客户端、密钥
│   ├── theme.dart
│   ├── database_helper.dart
│   ├── abnormality_repository.dart
│   ├── diary_repository.dart
│   ├── work_log_repository.dart
│   ├── agent_repository.dart
│   ├── ego_repository.dart
│   ├── preset_loader.dart
│   ├── glm_client.dart
│   ├── secrets.dart        # ⚠️ 本地真实密钥（已 gitignore）
│   └── secrets.example.dart
├── models/                # 纯数据模型（含 fromJson / toJson）
├── services/              # 业务服务（计算 / 调度 / 大模型）
│   ├── resonance_service.dart
│   ├── extraction_service.dart
│   ├── work_service.dart
│   ├── attachment_service.dart
│   ├── breach_service.dart
│   ├── ego_shop_service.dart
│   └── qliphoth_scheduler.dart
├── state/                 # Riverpod Provider
│   └── app_providers.dart
├── pages/                 # 页面
│   ├── observation_logs_page.dart   # 观测日志列表（首页）
│   ├── new_entry_page.dart          # 新建观测
│   ├── abnormality_gallery_page.dart# 档案库 + 提取仪式入口
│   ├── abnormality_detail_page.dart # 工作控制台
│   ├── attachment_chat_page.dart    # 沟通对话
│   ├── ego_shop_page.dart           # EGO 商店
│   └── agent_panel_page.dart        # 主管面板
└── widgets/               # 可复用组件
    ├── lcorp_grid_background.dart
    ├── lcorp_button.dart            # 扫描线动效按钮
    ├── caution_overlay.dart         # 黄黑斜纹机密遮盖板
    ├── abnormality_image.dart       # 异想体图片（带回退）
    ├── extraction_ceremony_widget.dart
    ├── qliphoth_counter_widget.dart
    └── breach_alert_overlay.dart
assets/
├── presets/
│   ├── abnormalities.json    # 异想体预设档案
│   └── ego_gears.json        # EGO 装备目录
└── abnormalities/
    ├── icons/                # 档案库缩略：{id}.png
    └── portraits/            # 详情 / 仪式立绘：{id}.png
```

---

## 4. 开发环境与运行

### 4.1 前置依赖

- Flutter 3.x（Dart SDK ≥ 3.12）
- Android Studio + Android SDK
- 真机或模拟器（**最低 Android 8.0 / API 26**）

### 4.2 配置 GLM 密钥

复制密钥模板，填入你自己的 API Key（在 [bigmodel.cn](https://bigmodel.cn) 申请）：

```bash
cp lib/core/secrets.example.dart lib/core/secrets.dart
# 编辑 secrets.dart，填入 glmApiKey
```

> `lib/core/secrets.dart` 已加入 `.gitignore`，**不会被纳入版本控制**。

### 4.3 拉取依赖 + 运行

```bash
flutter pub get
flutter run                       # 运行到当前连接的设备
flutter analyze                   # 静态分析（应输出 No issues found）
```

### 4.4 添加异想体素材

把 PNG 图片按异想体 ID 命名后丢进对应目录，无需改任何代码：

```
assets/abnormalities/icons/O-03-03.png        # 档案库缩略
assets/abnormalities/portraits/O-03-03.png    # 详情立绘
```

缺图时 UI 会自动回退到 L-Corp 黄色图标占位。

---

## 5. 核心系统

### 5.1 日记系统

- Markdown 文本 + 图片附件 + 认知滤网（预设标签 + 自定义标签）
- 提交后 `ResonanceService` 调用 GLM 对所有未解锁异想体的 `featureTags` 做语义匹配
- 大模型严格输出 `{abnormalityId: delta}` JSON，写入 `DiaryEntry.resonanceDeltas`（隐藏字段）并累加到 `Abnormality.currentResonance`
- 失败自动降级为本地启发式匹配，保障流程不中断

### 5.2 提取与解锁

- 资格判定：`currentResonance ≥ requiredResonance` **且** 累计独立日记天数 ≥ `requiredDays`
- 日记天数硬上限 **30 天**
- 每日 3 选 1，每日上限解锁 1 个，自然日 0:00 重置
- 仪式动画：黄色光栅扫描线上下滚动 → 揭晓立绘

### 5.3 工作系统

| 工作 | 说明 |
| ---- | ---- |
| 本能 Instinct | 物质需求处理 |
| 洞察 Insight | 档案碎片解锁 |
| 沟通 Attachment | **CharGLM-4 自由对话**，按异想体设定严格扮演 |
| 压迫 Repression | 强制指令 |

公式：
- 成功率 = `clamp(weight × aptitude / 10, 0.05, 0.95)`，消极状态权重 ×0.5
- 大失败：成功率 < 20% 且判定失败 → `qliphothCounter -= 1`
- PE Box 产出 = `floor(weight × aptitude × 2)`（仅成功）
- 能量值：成功 +10 / 失败 -15，消极状态保底 +5；归零进入消极，恢复 ≥30 解除
- 失败员工 HP -5，HP 归零进入"受伤"无法工作

### 5.4 突破机制

| breachType | 效果 |
| ---------- | ---- |
| `none` | 仅重置计数器 |
| `penaltyBox` | 立即扣除 `penaltyAmount`% PE Box（clamp ≥ 0） |
| `escape` | 异想体出逃，每分钟扣 `escapeDrain` PE Box |

出逃后可选：
- **不镇压** → 30 分钟后自动返回，期间持续扣 PE Box
- **镇压** → 成功率 `clamp(Σsuppression × 0.1 + 0.2, 0.1, 0.9)`
  - 成功：奖励 `floor(qliphothMax × 2)` PE Box，立即返回
  - 失败：员工 HP -20，可再次尝试

### 5.5 后台调度器

`QliphothScheduler` 在应用启动时启动，包含三类周期任务：

| 周期 | 任务 |
| ---- | ---- |
| 启动一次 + 每 30 分钟 | 8 小时未互动衰减检测（仅工作记录算互动，写日记不算） |
| 每 1 分钟 | 出逃巡检：扣 PE Box、检查 30 分钟自动返回 |
| 每 1 小时 | 员工 HP 自然恢复 +10（clamp 至 maxHp） |

---

## 6. UI/UX 规范（L-Corp）

| 用途 | 色值 |
| ---- | ---- |
| 主背景 Background | `#1A2A3A` 深蓝 |
| 主色 / 强调 Primary | `#6E8AA6` 工业蓝灰 |
| 次级表面 Surface | `#233447` 深蓝灰 |
| 警告 / 活跃 Alert | `#E53935` 警报红 |

视觉语言：
- 全局 `LCorpGridBackground` 蓝灰网格底
- `LCorpButton` 方角静态按钮（点击 ripple 反馈，无持续动画）
- `CautionOverlay` 警报红 / 深蓝斜纹机密遮盖板
- `QliphothCounterWidget` 分段式 LED 风格，归零红色闪烁
- `BreachAlertOverlay` 全屏深蓝 / 警报红交替闪烁 + ERROR 像素抖动

> ⚠️ **核心禁令**：界面禁止出现任何代表共鸣度进度的百分比、数字或进度条组件。

---

## 7. 数据模型摘要

```dart
class Abnormality {
  String id, name, grade;
  List<String> featureTags;          // 共鸣度匹配语义
  Map<String, double> workTypeWeights;
  int requiredDays;                  // ≤ 30
  int requiredResonance;             // ⚠️ Hidden from UI
  int currentResonance;              // ⚠️ Hidden from UI
  bool isUnlocked, isInitial, isEscaped;
  int energyLevel;                   // 0~100
  int qliphothCounter, qliphothMax;
  BreachType breachType;
  int? penaltyAmount, escapeDrain;
  Map<String, String> workReactions; // {workType}_{success|fail}
}

class DiaryEntry {
  String content;
  List<String> attachments, cognitiveFilters;
  Map<String, int> resonanceDeltas;  // ⚠️ Hidden from UI
  DateTime createdAt;
  // 不包含 abnormalityId / workType
}
```

---

## 8. 大模型接入

### 8.1 共鸣度匹配 — `glm-4-flash`

低成本档，强制 JSON 输出。System prompt 限定：
- 仅基于 `featureTags` 判断
- delta 范围 0~15
- 仅输出 `{abnormalityId: delta}` JSON

调用失败自动降级为 `HeuristicLlmMatcher`（基于子串命中的本地启发式）。

### 8.2 沟通对话 — `charglm-4`

智谱专用角色扮演模型。`meta` 字段结构化注入：
- `bot_name` / `bot_info`：异想体档案 + workReactions 作为语气样本
- `user_name` / `user_info`：玩家身份固定为"主管"

约束：保持人格 / 短句克制 / 允许括号描写动作 / 不暴露共鸣度数值 / 不替主管说话。

---

## 9. 路线图

| 阶段 | 状态 |
| ---- | ---- |
| 1 · 项目初始化与 UI 基建 | ✅ |
| 2 · 核心数据模型 | ✅ |
| 3 · 本地数据库层 | ✅ |
| 4 · 状态管理与共鸣度引擎 | ✅ |
| 5 · 日记系统 UI | ✅ |
| 6 · 异想体管理与工作系统 UI | ✅ |
| 7 · 突破 / 出逃镇压 / EGO 商店 | ✅ |
| 8 · 收尾与调试 | ✅ |

详细任务清单见 [TODO.md](TODO.md)，规则与设计原则见 [AGENT.md](AGENT.md)。

---

## 10. 安全提示

- **永远不要把真实 API Key 提交到 git**。`secrets.dart` 已被 `.gitignore` 屏蔽
- 切勿在 PR / Issue / 截图 / 日志中粘贴 Key 明文
- 一旦 Key 泄露：去 [bigmodel.cn](https://bigmodel.cn) 立即撤销并重置

---

> *"Face the fear, build the future."*
