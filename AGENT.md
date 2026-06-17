# Repository Guidelines - Project Moon Life Record (L-Corp Definitive Edition)

## 0.参考
https://lobotomycorp.fandom.com/zh/wiki/%E8%84%91%E5%8F%B6%E5%85%AC%E5%8F%B8_Wiki

## 1. 项目概述

本项目是一个基于 Flutter 开发的沉浸式生活记录与模拟管理 App，**目标平台为 Android**（v1.0 仅发布安卓端，iOS 后续考虑）。界面采用脑叶公司（Lobotomy Corporation）工业风格，**v1.1 精简版**仅保留三大核心模块：**日记记录 / 共鸣度累计 / 异想体对话**。本项目的核心哲学是"观测与秘密"，所有的管理数据均服务于深度沉浸感。

> 平台说明：最低支持版本建议 Android 8.0（API 26）。

---

## 2. 核心系统逻辑

### 2.1 日记系统（Diary System）- 获取与解锁

日记是主管对现实进行"观测"并转化为共鸣度的唯一途径。**日记仅用于解锁异想体**，与解锁后的对话系统无关。

- **多维观测日志**：支持 Markdown 文本、照片证据（多图）、音频采样。
- **认知滤网（Tags）**：支持预设标签与用户自定义标签，自定义标签会永久计入匹配引擎。
- **神秘感原则（The Secret of Resonance）**：
  - 共鸣度数值（`currentResonance` / `resonanceDeltas` 等）是后端计算的核心数值，**严禁在前端 UI 以任何形式（数字、百分比、进度条等）展示给用户**。
  - 用户只能通过异想体档案的"遮盖状态变化"来感知进度，无法预知确切的解锁分值。
- **共鸣度算法（Resonance Algorithm）**：
  - 每条日记内容（文本 + 标签）提交给大模型，由大模型判断与所有**未解锁**异想体 `featureTags` 的语义匹配度，返回每个异想体的共鸣度增量（写入 `DiaryEntry.resonanceDeltas` 并累加到 `Abnormality.currentResonance`）。
  - 大模型 Prompt 需约束输出格式为结构化 JSON，仅包含异想体 ID 与分数增量，禁止返回解释性文本。
  - 单条日记可同时为多个异想体加分；日记本身不绑定任何异想体。
  - `currentResonance` 累加至 `requiredResonance`，**且**累计记录天数达到 `requiredDays` 时，该异想体**立即自动解锁**（仪式动画揭晓），不再有每日提取池 / 配额。
- **解锁规则**：
  - **自动解锁**：满足共鸣度阈值与累计天数阈值后立即解锁，UI 弹出仪式动画。
  - **初始状态**：所有用户自动解锁 `isInitial == true` 的异想体（如「一罪与百善」）。

### 2.2 异想体对话（Communication）- 解锁后的核心交互

对已解锁的异想体执行**自由对话**：

- 接入 CharGLM 角色扮演模型，按异想体档案 (`description` / `manageNote` / `featureTags`) 严格扮演。
- 异想体会按一定概率主动反问，强化沉浸感。
- 对话不再产生 PE Box / 工作日志等副作用，仅服务于体验。

---

## 3. 核心数据模型

### 3.1 日记条目（DiaryEntry）

```dart
class DiaryEntry {
  String id;
  String content;                          // Markdown 文本
  List<String> attachments;                // 图片/音频 URL
  List<String> cognitiveFilters;           // 自定义 + 预设标签
  Map<String, int> resonanceDeltas;        // ⚠️ Hidden from UI，本条日记对各异想体的共鸣度增量 {abnormalityId: delta}
  DateTime createdAt;
}
```

### 3.3 异想体（Abnormality）

```dart
class Abnormality {
  String id;
  String name;
  String grade;                  // ZAYIN/TETH/HE/WAW/ALEPH
  List<String> featureTags;
  int requiredDays;              // 累计记录天数阈值
  int requiredResonance;         // 解锁所需共鸣度阈值 ⚠️ Hidden from UI
  int currentResonance;          // ⚠️ Hidden from UI，当前累计共鸣度
  bool isUnlocked;
  bool isInitial;                // true = 自动解锁
  DateTime? unlockDate;
  String description;            // 解锁前遮盖
  String manageNote;             // 解锁前遮盖
}
```

---

## 4. UI/UX 规范（L-Corp）

### 配色方案

| 用途                            | 色值                  |
| ------------------------------- | --------------------- |
| 主背景（Background）            | 近黑 `#0F1620`        |
| 主色 / 强调（Primary / Accent） | 经典蓝 `#2D7DF6`      |
| 次级表面（Surface）             | 深灰 `#1B2330`        |
| 警告 / 活跃（Alert / Active）   | 警报红 `#E53935`      |
| 主文字（onBackground）          | 近白 `#F4F6FA`        |

### 视觉组件

- **网格背景**：近黑底叠加极细半透明蓝色网格线
- **终端样式**：等宽字体 + 12px 圆角面板（克制不闪烁）
- **机密遮盖板**：未解锁区域覆盖警报红 / 近黑斜纹 "Caution" 警示带

### 交互动效

- **解锁仪式动画**：扫描线上下滚动，揭晓立绘

### 核心禁令

> ⚠️ **前端界面禁止出现任何代表共鸣度进度的百分比、数字或进度条组件。**

---

## 5. 开发规范

- 按 TODO.md 逐步推进，不要跳步
- 每个任务完成后运行 `flutter analyze` + `flutter test`
- 每个功能 git commit 一次，格式：`feat: <描述>`
- 遇到报错自行修复，不要停下来等待

---

## 6. v1.2 UI 结构补充

- 应用入口为 `MainShellPage`，底部 Tab 为 `LOGS / GALLERY / COMMS / SYSTEM`。
- `pendingUnlocksProvider` 的仪式动画应在主壳层监听，保证任意 Tab 都能弹出。
- 档案库搜索与等级筛选只展示已解锁条目；未解锁条目不得因搜索命中而泄露。
- 对话页可读取相关观测预览，但严禁显示 `currentResonance`、`requiredResonance`、`resonanceDeltas` 的数值。
- `docs/references/` 用于用户截图参考，`docs/wiki/` 用于离线 wiki 摘录缓存。

## 7. 初始异想体预设档案（abnormalities.json）

### 6.1 「一罪与百善」(O-03-03)

```json
{
  "id": "O-03-03",
  "name": "一罪与百善",
  "grade": "ZAYIN",
  "isInitial": true,
  "featureTags": ["忏悔", "宽恕", "牺牲", "善意", "信仰", "自我审视"],
  "requiredDays": 0,
  "requiredResonance": 0,
  "description": "一个巨大的漂浮骷髅，被荆棘冠冕缠绕，背负着沉重的十字架。它静静地倾听着每一个来到它面前的人的低语。",
  "manageNote": "即便长时间不与其沟通，该异想体也不会产生任何攻击性行为。是所有新进员工学习管理流程的最佳对象。"
}
```

### 6.2 「老妇人」(T-01-12)

```json
{
  "id": "T-01-12",
  "name": "老妇人",
  "grade": "TETH",
  "isInitial": false,
  "featureTags": ["孤独", "怀旧", "编织", "故事", "倾听", "琐碎", "耐心"],
  "requiredDays": 3,
  "requiredResonance": 45,
  "description": "一个外表苍白、双眼漆黑的老妇人，始终坐在摇椅上不断编织。她渴望有人能坐下来听她讲那些陈旧的故事。",
  "manageNote": "她渴望被倾听。坐下来，听她讲述那些陈旧的故事，便能与她建立连接。"
}
```

---
