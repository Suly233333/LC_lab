# Repository Guidelines - Project Moon Life Record (L-Corp Definitive Edition)

## 1. 项目概述

本项目是一个基于 Flutter 开发的沉浸式生活记录与模拟管理 App。界面采用脑叶公司（Lobotomy Corporation）工业风格，核心逻辑分为**日记系统**与**工作系统**。本项目的核心哲学是"观测与秘密"，所有的管理数据均服务于深度沉浸感。

---

## 2. 核心系统逻辑

### 2.1 日记系统（Diary System）- 获取与解锁

日记是主管对现实进行"观测"并转化为能量的唯一途径。

- **多维观测日志**：支持 Markdown 文本、照片证据（多图）、音频采样。
- **认知滤网（Tags）**：支持预设标签与用户自定义标签，自定义标签会永久计入匹配引擎。
- **环境参数（Metadata）**：自动记录天气、地理位置、步数、当前播放音乐，作为"站点环境数据"影响匹配概率。
- **神秘感原则（The Secret of Matching）**：
  - `matchingScore` 是后端计算的核心数值，**严禁在前端 UI 以任何形式（数字、百分比、进度条等）展示给用户**。
  - 用户只能通过异想体档案的"遮盖状态变化"或"可提取提醒"来感知进度，无法预知确切的解锁分值。
- **解锁规则**：
  - **门控**：累计记录天数上限封顶为 **30 天**。
  - **每日提取**：每天随机抽取 **3 个**候选异想体，用户可选择 **1 个**解锁。
  - **解锁配额**：每日最多解锁 **1 个**异想体。
  - **初始状态**：所有用户自动解锁「一罪与百善」，不进入提取池。

### 2.2 工作系统（Work System）- 管理与产出

对已解锁的异想体执行四种管理工作，产出 **PE Box**（用于兑换 EGO 装备）：

| 工作               | 内容                                            |
| ------------------ | ----------------------------------------------- |
| 本能（Instinct）   | 处理异想体本能需求，选择满足或忽视              |
| 洞察（Insight）    | 解锁档案碎片 + 答题，答对越多 PE Box 越高       |
| 沟通（Attachment） | 与异想体自由对话（AI 大模型），异想体会适时提问 |
| 压迫（Repression） | 对异想体下达强制指令，成功率与等级相关          |

> 注：不同异想体对四种工作有不同的额外效果，v1.0 暂定为无额外效果。

### 2.3 逆卡巴拉计数器（Qliphoth Counter）

- 初始值：ZAYIN:3 / TETH:4 / HE:5 / WAW:6 / ALEPH:7
- 工作大失败 / 长时间不互动 → 计数器 -1
- 归零 → 触发 `breachType` 对应惩罚，计数器重置
- 注：计数器最大值不与等级严格绑定，后续特殊异想体需单独设定。

### 2.4 资源循环

```
工作 → PE Box → EGO 商店 → 员工装备 EGO → 处置突破事件
```

---

## 3. 核心数据模型

### 3.1 日记条目（DiaryEntry）

```dart
class DiaryEntry {
  String id;
  String content;                          // Markdown 文本
  String workType;                         // instinct/insight/attachment/repression
  List<String> attachments;                // 图片/音频 URL
  List<String> cognitiveFilters;           // 自定义 + 预设标签
  Map<String, dynamic> environmentalData; // 天气/坐标/步数/音乐
  int matchingScore;                       // ⚠️ Hidden from UI
  DateTime createdAt;
}
```

### 3.2 异想体（Abnormality）

```dart
class Abnormality {
  String id;
  String name;
  String grade;                  // ZAYIN/TETH/HE/WAW/ALEPH
  List<String> featureTags;
  Map<String, double> workTypeWeights;
  int requiredDays;              // 最大值 30
  int requiredScore;
  int currentScore;              // ⚠️ Hidden from UI
  bool isUnlocked;
  bool isInitial;                // true = 自动解锁，不进入提取池
  DateTime? unlockDate;
  int energyLevel;               // 0-100
  int qliphothCounter;
  int qliphothMax;
  BreachType breachType;
  int? penaltyAmount;
  String description;            // 解锁前遮盖
  String manageNote;             // 解锁前遮盖
}

enum BreachType { escape, penaltyBox, energySpike, none }
```

### 3.3 员工（Agent）

```dart
class Agent {
  String id;
  String name;
  String? avatarPath;
  int hp;
  Map<String, int> aptitude;     // instinct/insight/attachment/repression
  List<String> equippedEgoIds;
  bool isUser;                   // v1.0 仅用户本人
}
```

### 3.4 EGO 装备（EgoGear）

```dart
class EgoGear {
  String id;
  String name;
  int cost;                      // PE Box 消耗
  Map<String, int> bonusStats;
}
```

### 3.5 每日状态（DailyState）

```dart
class DailyState {
  DateTime date;
  List<String> extractionCandidates; // 当日 3 个候选
  int unlockedCount;                 // 上限 1
}
```

---

## 4. UI/UX 规范（L-Corp Yellow & Black）

### 配色方案

| 用途                            | 色值               |
| ------------------------------- | ------------------ |
| 主背景（Background）            | 深碳黑 `#121212` |
| 主色 / 强调（Primary / Accent） | 警戒黄 `#FFD700` |
| 次级表面（Surface）             | 暗炭灰 `#262626` |
| 警告 / 活跃（Alert / Active）   | 琥珀橙 `#FF8F00` |

### 视觉组件

- **网格背景**：深色底叠加极细暗黄网格线
- **终端样式**：等宽字体 + 按钮扫描线动效
- **机密遮盖板**：未解锁区域覆盖黄色斜纹"Caution"警示带
- **能量条 / 计数格**：分段式黄光 LED 风格

### 交互动效

- **提取仪式**：黄色光栅扫描线上下滚动，揭晓立绘
- **突破警报**：全屏黑黄交替闪烁 + "ERROR"像素化抖动

### 核心禁令

> ⚠️ **前端界面禁止出现任何代表匹配进度的百分比、数字或进度条组件。**

---

## 5. 开发规范

- 按 TODO.md 逐步推进，不要跳步
- 每个任务完成后运行 `flutter analyze` + `flutter test`
- 每个功能 git commit 一次，格式：`feat: <描述>`
- 遇到报错自行修复，不要停下来等待

---

## 6. 初始异想体预设档案（abnormalities.json）

### 6.1 「一罪与百善」(O-03-03)

```json
{
  "id": "O-03-03",
  "name": "一罪与百善",
  "grade": "ZAYIN",
  "isInitial": true,
  "breachType": "none",
  "penaltyAmount": 0,
  "qliphothCounter": 3,
  "qliphothMax": 3,
  "featureTags": ["忏悔", "宽恕", "牺牲", "善意", "信仰", "自我审视"],
  "workTypeWeights": {
    "instinct": 0.5,
    "insight": 1.0,
    "attachment": 1.5,
    "repression": 0.3
  },
  "requiredDays": 0,
  "requiredScore": 0,
  "description": "一个巨大的漂浮骷髅，被荆棘冠冕缠绕，背负着沉重的十字架。它静静地倾听着每一个来到它面前的人的低语。",
  "manageNote": "即便长时间不与其沟通，该异想体也不会产生任何攻击性行为。是所有新进员工学习管理流程的最佳对象。",
  "workReactions": {
    "instinct_success": "它对物质需求毫无反应，只是静静地漂浮。",
    "insight_success": "员工在整理档案时，仿佛听到了一阵微弱的祈祷声。",
    "attachment_success": "员工向它倾诉了内心的罪恶感，它闭上了眼。",
    "repression_success": "强行的压制命令似乎让冠冕上的荆棘收紧了一些。",
    "repression_fail": "它没有反应。荆棘只是沉默地垂落。"
  }
}
```

### 6.2 「老妇人」(T-01-12)

```json
{
  "id": "T-01-12",
  "name": "老妇人",
  "grade": "TETH",
  "isInitial": false,
  "breachType": "penaltyBox",
  "penaltyAmount": 20,
  "qliphothCounter": 3,
  "qliphothMax": 4,
  "featureTags": ["孤独", "怀旧", "编织", "故事", "倾听", "琐碎", "耐心"],
  "workTypeWeights": {
    "instinct": 0.4,
    "insight": 0.4,
    "attachment": 0.9,
    "repression": 0.1
  },
  "requiredDays": 3,
  "requiredScore": 45,
  "description": "一个外表苍白、双眼漆黑的老妇人，始终坐在摇椅上不断编织。她渴望有人能坐下来听她讲那些陈旧的故事。",
  "manageNote": "长时间忽视她会使逆卡巴拉计数器减少。计数器归零时，'孤独线团'将爆发并扣除 20% 的 PE Box 储备。",
  "workReactions": {
    "instinct": "摇椅有规律地发出'嘎吱、嘎吱'的声音。 (成功率: 一般)",
    "insight": "员工试图理解她编织的花纹，但那些线永无止境且没有逻辑。 (成功率: 一般)",
    "attachment": "她慈祥地拉起员工的手，开始讲述一个关于'很久以前'的故事。 (成功率: 极高)",
    "repression": "员工的强制命令让她陷入令人不安的冰冷沉默。 (成功率: 极低)"
  }
}
```

---

