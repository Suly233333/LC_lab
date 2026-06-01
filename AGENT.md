# Repository Guidelines - Project Moon Life Record (L-Corp Definitive Edition)

## 1. 项目概述

本项目是一个基于 Flutter 开发的沉浸式生活记录与模拟管理 App。界面采用脑叶公司（Lobotomy Corporation）工业风格，核心逻辑分为**日记系统**与**工作系统**。本项目的核心哲学是"观测与秘密"，所有的管理数据均服务于深度沉浸感。

---

## 2. 核心系统逻辑

### 2.1 日记系统（Diary System）- 获取与解锁

日记是主管对现实进行"观测"并转化为共鸣度的唯一途径。**日记仅用于解锁异想体**，与解锁后的工作系统无关。

- **多维观测日志**：支持 Markdown 文本、照片证据（多图）、音频采样。
- **认知滤网（Tags）**：支持预设标签与用户自定义标签，自定义标签会永久计入匹配引擎。
- **环境参数（Metadata）**：自动记录天气、地理位置、步数、当前播放音乐，作为"站点环境数据"影响共鸣度计算。
- **神秘感原则（The Secret of Resonance）**：
  - 共鸣度数值（`currentResonance` / `resonanceDeltas` 等）是后端计算的核心数值，**严禁在前端 UI 以任何形式（数字、百分比、进度条等）展示给用户**。
  - 用户只能通过异想体档案的"遮盖状态变化"或"可提取提醒"来感知进度，无法预知确切的解锁分值。
- **共鸣度算法（Resonance Algorithm）**：
  - 每条日记内容（文本 + 标签 + 环境参数）提交给大模型，由大模型判断与所有**未解锁**异想体 `featureTags` 的语义匹配度，返回每个异想体的共鸣度增量（写入 `DiaryEntry.resonanceDeltas` 并累加到 `Abnormality.currentResonance`）。
  - 大模型 Prompt 需约束输出格式为结构化 JSON，仅包含异想体 ID 与分数增量，禁止返回解释性文本。
  - 单条日记可同时为多个异想体加分；日记本身不绑定任何异想体。
  - `currentResonance` 累加至 `requiredResonance`，**且**累计记录天数达到 `requiredDays` 时，该异想体进入可提取状态（两个条件需同时满足）。
- **解锁规则**：
  - **门控**：累计记录天数上限封顶为 **30 天**。
  - **每日提取**：每天随机抽取 **3 个**候选异想体，用户可选择 **1 个**解锁。按自然日（0:00）重置。
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

#### 工作成功 / 失败判定

- **成功率** = `workTypeWeights[workType]` × `aptitude[workType]`
  - `workTypeWeights` 为异想体对该工作的权重（0.0~2.0），`aptitude` 为员工对该工作的适性等级（整数）。
  - 最终成功率 = `clamp(weight × aptitude / 10, 0.05, 0.95)`，即 5%~95% 之间浮动。
- **大失败**：成功率低于 20% 时，若判定失败则视为"大失败"，逆卡巴拉计数器 -1。
- **PE Box 产出**：成功时产出 `floor(weight × aptitude × 2)`，失败时产出 0。
- **能量值（energyLevel）**：工作成功时 +10，失败时 -15，范围 0~100。能量值归零时异想体进入消极状态，所有工作权重 ×0.5。消极状态下每次工作（无论成败）至少恢复 +5 能量，能量恢复至 30 以上时解除消极状态。
- **PE Box 储备下限**：PE Box 储备不可低于 0，所有扣除操作均 clamp 至 0。
- **员工 HP 下限**：员工 HP 不可低于 0。HP 归零时员工进入"受伤"状态，无法执行任何工作，需等待自然恢复（每小时恢复 10 HP）或使用道具恢复。

### 2.3 逆卡巴拉计数器（Qliphoth Counter）

- 初始值：ZAYIN:3 / TETH:4 / HE:5 / WAW:6 / ALEPH:7
- 工作大失败 / 超过 **8 小时**未与**该异想体**互动 → 计数器 -1
- 归零 → 触发 `breachType` 对应惩罚，计数器重置
- 注：计数器最大值不与等级严格绑定，后续特殊异想体需单独设定。

#### 突破类型（Breach Types）

| 突破类型 | 效果 |
| -------- | ---- |
| `none` | 无突破事件，计数器归零仅重置 |
| `penaltyBox` | 立即扣除 `penaltyAmount`% 的 PE Box 储备，计数器重置 |
| `escape` | 异想体出逃，进入出逃状态 |

#### 出逃与镇压（Escape & Suppression）

- **出逃状态**：异想体脱离收容，在设施内游荡，每分钟扣除 `escapeDrain` 点 PE Box。
- **镇压选择**：出逃后主管可选择是否派遣员工镇压。
  - 选择不镇压：异想体持续游荡扣 PE Box，**30 分钟**后自动返回收容（计数器重置）。
  - 选择镇压：进入镇压判定。
- **镇压成功率** = `clamp(Σ(equippedEgo.bonusStats[suppression] × 0.1) + 0.2, 0.1, 0.9)`
  - 基础成功率 20%，每件装备的 `suppression` 加成提供 10% 提升上限。
  - 镇压成功：异想体立即返回收容，计数器重置，获得 `floor(qliphothMax × 2)` PE Box 奖励。
  - 镇压失败：员工 HP -20，异想体继续游荡，可再次尝试镇压。
- 注：当前预设异想体 `breachType` 均为 `none` 或 `penaltyBox`，不会触发出逃。

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
  List<String> attachments;                // 图片/音频 URL
  List<String> cognitiveFilters;           // 自定义 + 预设标签
  Map<String, dynamic> environmentalData; // 天气/坐标/步数/音乐
  Map<String, int> resonanceDeltas;        // ⚠️ Hidden from UI，本条日记对各异想体的共鸣度增量 {abnormalityId: delta}
  DateTime createdAt;
}
```

### 3.2 工作记录（WorkLog）

```dart
class WorkLog {
  String id;
  String abnormalityId;          // 关联的已解锁异想体
  String agentId;                // 执行工作的员工
  String workType;               // instinct/insight/attachment/repression
  bool success;                  // 工作判定结果
  bool isCriticalFail;           // 是否为大失败
  int peBoxGained;               // 本次工作产出的 PE Box
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
  Map<String, double> workTypeWeights;
  int requiredDays;              // 最大值 30
  int requiredResonance;         // 解锁所需共鸣度阈值
  int currentResonance;          // ⚠️ Hidden from UI，当前累计共鸣度
  bool isUnlocked;
  bool isInitial;                // true = 自动解锁，不进入提取池
  DateTime? unlockDate;
  int energyLevel;               // 0-100，新解锁时初始值 50
  int qliphothCounter;
  int qliphothMax;
  BreachType breachType;
  int? penaltyAmount;
  int? escapeDrain;              // 出逃时每分钟扣除的 PE Box
  String description;            // 解锁前遮盖
  String manageNote;             // 解锁前遮盖
  Map<String, String> workReactions; // key: {workType}_{result}
}

enum BreachType { escape, penaltyBox, none }
```

### 3.4 员工（Agent）

```dart
class Agent {
  String id;
  String name;
  String? avatarPath;
  int hp;
  int maxHp;                     // HP 上限，受伤恢复 clamp 上限
  Map<String, int> aptitude;     // instinct/insight/attachment/repression
  List<String> equippedEgoIds;
  bool isUser;                   // v1.0 仅用户本人
}
```

### 3.5 EGO 装备（EgoGear）

```dart
class EgoGear {
  String id;
  String name;
  int cost;                      // PE Box 消耗
  Map<String, int> bonusStats;
}
```

### 3.6 每日状态（DailyState）

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

> ⚠️ **前端界面禁止出现任何代表共鸣度进度的百分比、数字或进度条组件。**

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
  "escapeDrain": null,
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
  "requiredResonance": 0,
  "description": "一个巨大的漂浮骷髅，被荆棘冠冕缠绕，背负着沉重的十字架。它静静地倾听着每一个来到它面前的人的低语。",
  "manageNote": "即便长时间不与其沟通，该异想体也不会产生任何攻击性行为。是所有新进员工学习管理流程的最佳对象。",
  "workReactions": {
    "instinct_success": "它对物质需求毫无反应，只是静静地漂浮。",
    "instinct_fail": "它对物质需求毫无反应，依旧静静地漂浮，仿佛什么都没发生。",
    "insight_success": "员工在整理档案时，仿佛听到了一阵微弱的祈祷声。",
    "insight_fail": "员工试图整理档案，但骷髅只是沉默，没有任何回应。",
    "attachment_success": "员工向它倾诉了内心的罪恶感，它闭上了眼。",
    "attachment_fail": "员工试图靠近倾诉，但它似乎没有在听。",
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
  "escapeDrain": null,
  "qliphothCounter": 4,
  "qliphothMax": 4,
  "featureTags": ["孤独", "怀旧", "编织", "故事", "倾听", "琐碎", "耐心"],
  "workTypeWeights": {
    "instinct": 0.4,
    "insight": 0.4,
    "attachment": 0.9,
    "repression": 0.1
  },
  "requiredDays": 3,
  "requiredResonance": 45,
  "description": "一个外表苍白、双眼漆黑的老妇人，始终坐在摇椅上不断编织。她渴望有人能坐下来听她讲那些陈旧的故事。",
  "manageNote": "长时间忽视她会使逆卡巴拉计数器减少。计数器归零时，'孤独线团'将爆发并扣除 20% 的 PE Box 储备。",
  "workReactions": {
    "instinct_success": "摇椅有规律地发出'嘎吱、嘎吱'的声音，她似乎对物质供给感到一丝安慰。",
    "instinct_fail": "摇椅的嘎吱声戛然而止，她对物质供给毫无兴趣。",
    "insight_success": "员工试图理解她编织的花纹，隐约看出了某种古老的图案。",
    "insight_fail": "员工试图理解她编织的花纹，但那些线永无止境且没有逻辑。",
    "attachment_success": "她慈祥地拉起员工的手，开始讲述一个关于'很久以前'的故事。",
    "attachment_fail": "她似乎没有注意到员工的靠近，继续低头编织。",
    "repression_success": "员工的强制命令让她陷入令人不安的冰冷沉默，但她暂时服从了。",
    "repression_fail": "员工的强制命令让她陷入令人不安的冰冷沉默，线团开始不安地颤动。"
  }
}
```

---

