# Project Moon Life Record · L-Corp Edition

> 一款基于脑叶公司（Lobotomy Corporation）工业风格的 **沉浸式生活记录与异想体对话 App**。
> 用 Flutter 开发，目标平台 **Android**。

主管，欢迎回到设施。
你今日记录下的每一段观测，都会成为某只未解锁异想体的低语。

---

## 1. 项目定位

v1.1 精简版只做三件事：

- **观测**：写日记 → 大模型按"认知滤网（标签）"匹配未解锁异想体的语义特征 → 累计共鸣度
- **解锁**：满足共鸣度阈值与累计天数后，**自动解锁**并播放仪式动画
- **对话**：对已解锁异想体进行自由对话（CharGLM 严格扮演）

> ⚠️ **神秘感原则**：共鸣度数值（`currentResonance` / `resonanceDeltas` / `requiredResonance`）
> **永远不会**在 UI 上以任何形式展示给用户。用户只能通过档案的"遮盖状态变化"
> 来感知进度。

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
│   ├── preset_loader.dart
│   ├── glm_client.dart
│   ├── secrets.dart        # ⚠️ 本地真实密钥（已 gitignore）
│   └── secrets.example.dart
├── models/                # 纯数据模型（含 fromJson / toJson）
│   ├── abnormality.dart
│   └── diary_entry.dart
├── services/              # 业务服务（计算 / 大模型）
│   ├── resonance_service.dart    # 共鸣度匹配
│   ├── unlock_service.dart       # 自动解锁判定
│   └── attachment_service.dart   # 异想体对话
├── state/                 # Riverpod Provider
│   └── app_providers.dart
├── pages/                 # 页面
│   ├── main_shell_page.dart         # 底部 Tab 主壳
│   ├── observation_logs_page.dart   # 观测日志列表
│   ├── new_entry_page.dart          # 新建观测
│   ├── abnormality_gallery_page.dart# 档案库（自动弹仪式动画）
│   ├── communication_list_page.dart # 已解锁异想体对话列表
│   ├── settings_page.dart           # 系统设置 / 导出 / 重置
│   ├── abnormality_detail_page.dart # 档案详情 + 进入对话
│   └── attachment_chat_page.dart    # 与异想体对话
└── widgets/               # 可复用组件
    ├── lcorp_grid_background.dart
    ├── lcorp_button.dart
    ├── caution_overlay.dart         # 警报红 / 近黑斜纹机密遮盖板
    ├── abnormality_image.dart       # 异想体图片（带回退）
    └── extraction_ceremony_widget.dart
assets/
├── presets/
│   └── abnormalities.json    # 异想体预设档案
└── abnormalities/
    ├── icons/                # 档案库缩略：{id}.png
    └── portraits/            # 详情 / 仪式立绘：{id}.png
docs/
├── references/               # 用户放置的游戏截图参考
└── wiki/                     # 离线 wiki 摘录缓存（默认忽略内容）
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

缺图时 UI 会自动回退到 L-Corp 蓝色图标占位。

---

## 5. 核心系统

### 5.1 日记系统

- Markdown 文本 + 图片附件 + 认知滤网（预设标签 + 自定义标签）
- 提交后 `ResonanceService` 调用 GLM 对所有未解锁异想体的 `featureTags` 做语义匹配
- 大模型严格输出 `{abnormalityId: delta}` JSON，写入 `DiaryEntry.resonanceDeltas`（隐藏字段）并累加到 `Abnormality.currentResonance`
- 失败自动降级为本地启发式匹配，保障流程不中断
- 写入完成后立即触发 `UnlockService.evaluateAutoUnlock()`

### 5.2 自动解锁

- 资格判定：`currentResonance ≥ requiredResonance` **且** 累计独立日记天数 ≥ `requiredDays`
- 满足条件 → 立即解锁；通过 `pendingUnlocksProvider` 通知档案库页弹仪式动画
- 仪式动画：扫描线上下滚动 → 揭晓立绘

### 5.3 异想体对话

- 详情页 `BEGIN COMMUNICATION` 进入对话
- CharGLM-4 严格扮演异想体（按 `description` / `manageNote` / `featureTags` 构造人格）
- 异想体偶尔主动反问；离线时降级到 `MockAttachmentService`
- 不再有"工作结算 / PE Box / 突破事件"

---

## 6. UI/UX 规范（L-Corp）

| 用途 | 色值 |
| ---- | ---- |
| 主背景 Background | `#0F1620` 近黑 |
| 主色 / 强调 Primary | `#2D7DF6` 经典蓝 |
| 次级表面 Surface | `#1B2330` 深灰 |
| 警告 / 活跃 Alert | `#E53935` 警报红 |
| 主文字 onBackground | `#F4F6FA` 近白 |

视觉语言：
- 全局 12px 圆角面板（小标签 / 计数格 8px / 3px）
- `LCorpGridBackground` 半透明蓝色网格底
- `LCorpButton` 圆角静态按钮（点击 ripple 反馈）
- `CautionOverlay` 警报红 / 近黑斜纹机密遮盖板

> ⚠️ **核心禁令**：界面禁止出现任何代表共鸣度进度的百分比、数字或进度条组件。

---

## 7. 数据模型摘要

```dart
class Abnormality {
  String id, name, grade;
  List<String> featureTags;          // 共鸣度匹配语义
  int requiredDays;                  // 累计天数阈值
  int requiredResonance;             // ⚠️ Hidden from UI
  int currentResonance;              // ⚠️ Hidden from UI
  bool isUnlocked, isInitial;
  DateTime? unlockDate;
  String description, manageNote;
}

class DiaryEntry {
  String content;
  List<String> attachments, cognitiveFilters;
  Map<String, int> resonanceDeltas;  // ⚠️ Hidden from UI
  DateTime createdAt;
  // 不包含 abnormalityId
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
- `bot_name` / `bot_info`：异想体档案（描述 + 管理备注 + featureTags）
- `user_name` / `user_info`：玩家身份固定为"主管"

约束：保持人格 / 短句克制 / 允许括号描写动作 / 不暴露共鸣度数值 / 不替主管说话。

---

## 9. v1.2 当前结构

- 首页改为 `MainShellPage`，通过底部 Tab 切换 `LOGS / GALLERY / COMMS / SYSTEM`，并用 `IndexedStack` 保留各 Tab 状态。
- 解锁仪式动画由主壳全局监听 `pendingUnlocksProvider`，不再只依赖档案库页。
- 档案库支持已解锁异想体搜索和等级筛选。
- 对话页支持调取相关观测预览，内部按隐藏匹配结果排序，但不显示任何共鸣度数值。
- 系统页提供 GLM Key 状态、数据导出到剪贴板、本地数据重置和调试开关说明。

## 10. 路线图

| 阶段 | 状态 |
| ---- | ---- |
| 1 · 项目初始化与 UI 基建 | ✅ |
| 2 · 核心数据模型 | ✅ |
| 3 · 本地数据库层 | ✅ |
| 4 · 状态管理与共鸣度引擎 | ✅ |
| 5 · 日记系统 UI | ✅ |
| 6 · 异想体档案库与对话 UI | ✅ |
| 7 · ~~突破 / 出逃镇压 / EGO 商店~~ | 🗑 v1.1 已废弃 |
| 8 · 收尾与调试 | ✅ |
| 9 · 精简化重构（v1.1） | ✅ |

详细任务清单见 [TODO.md](TODO.md)，规则与设计原则见 [AGENT.md](AGENT.md)。

---

## 11. 安全提示

- **永远不要把真实 API Key 提交到 git**。`secrets.dart` 已被 `.gitignore` 屏蔽
- 切勿在 PR / Issue / 截图 / 日志中粘贴 Key 明文
- 一旦 Key 泄露：去 [bigmodel.cn](https://bigmodel.cn) 立即撤销并重置

---

> *"Face the fear, build the future."*
