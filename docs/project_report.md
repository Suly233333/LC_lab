# Project Moon Life Record 项目报告

## 摘要

Project Moon Life Record 是一款基于 Flutter 开发、面向 Android 平台的沉浸式生活记录与异想体对话应用。项目以《脑叶公司》（Lobotomy Corporation）的工业风格为视觉参考，将“日记记录”“隐藏共鸣度累计”“异想体自动解锁”“解锁后自由对话”组合为一个轻量化移动端系统。用户通过记录现实生活中的观测日志，触发系统对文本与标签的语义匹配；当隐藏条件满足时，异想体被自动解锁，并通过仪式动画完成揭晓。

本报告依据 `AGENT.md`、`TODO.md`、`README.md` 与 `develop.md` 编写，覆盖项目背景、目标、需求分析、系统架构、关键实现、测试验证、风险与后续计划。当前项目已经完成 v1.1 精简版核心功能，并在 v1.2 阶段完成底部 Tab 主壳、全局解锁仪式、对话列表、系统设置、档案筛选、日志分组和相关观测调取等体验重构。由于当前环境无法访问 wiki，异想体清单全面校对任务暂未展开；当前 presets 中仅保留“一罪与百善”和“老妇人”两条异想体数据。

## 1. 项目背景

传统日记应用通常以文本记录、日历归档和标签检索为核心，强调效率与可追溯性。本项目尝试在生活记录功能上叠加“观测、秘密、解锁、对话”的沉浸式机制，使用户的日常记录不只是静态内容，而会逐步转化为虚构收容设施中的档案变化。

项目设定参考《脑叶公司》的视觉和叙事氛围，但在功能上不复刻复杂的工作系统、出逃镇压、EGO 装备或员工管理。按照 `AGENT.md` 与 `TODO.md` 的约束，v1.1 之后项目被精简为三个核心模块：

1. 观测日志：用户记录日常文本、附件和认知滤网标签。
2. 隐藏解锁：系统根据日志内容与异想体语义标签的匹配结果，累积隐藏共鸣度并自动解锁异想体。
3. 异想体对话：用户与已解锁异想体进行自由对话，强化陪伴感和世界观沉浸。

项目的核心设计原则是“观测与秘密”。共鸣度等关键数值只服务于内部判断，不以数字、百分比或进度条形式出现在界面上。

## 2. 项目目标

项目总体目标是实现一个可运行的 Android 端生活记录应用原型，同时具备明确的主题风格和可扩展的数据结构。

功能目标包括：

- 支持 Markdown 文本、图片附件和认知滤网标签的日记记录。
- 使用本地数据库持久化日记与异想体档案。
- 通过 GLM 或本地启发式逻辑计算日志与异想体的语义匹配结果。
- 在隐藏阈值满足时自动解锁异想体，并播放仪式动画。
- 支持与已解锁异想体进行自由对话，真实接口失败时可降级到 Mock 回复。
- 提供底部 Tab 结构，使日志、档案、对话和系统设置成为并列入口。

非功能目标包括：

- 保持黄黑警示色块、等宽字体、硬边框和机密遮盖板构成的 L-Corp 风格。
- 禁止任何 UI 暴露隐藏共鸣度数值。
- 删除并避免重新引入已废弃的工作系统、突破、镇压、EGO、Agent、PE Box 等复杂管理模块。
- 保持代码结构清晰，按模型、仓库、服务、状态、页面、组件分层。

## 3. 需求分析

### 3.1 用户需求

目标用户需要一个兼具记录与互动体验的移动端应用。用户可以像普通日记应用一样记录内容，也可以在长期使用中逐步解锁异想体档案并进入对话。与传统成长数值展示不同，本项目通过遮盖板、解锁动画和档案变化提供反馈，避免把体验简化为数值刷取。

### 3.2 业务需求

项目业务流程可以概括为：

1. 用户创建观测日志。
2. 日志保存到本地数据库。
3. 系统将日志内容和标签送入共鸣度匹配服务。
4. 匹配结果写入日记隐藏字段，并累加到异想体隐藏字段。
5. 解锁服务检查累计天数和隐藏阈值。
6. 满足条件后标记异想体解锁并加入待揭晓队列。
7. UI 全局监听队列并播放解锁仪式。
8. 用户进入档案详情或对话列表，与已解锁异想体交流。

### 3.3 v1.2 开发需求

`develop.md` 提出下一阶段任务，其中本阶段实际完成的重点包括：

- 将页面结构改为底部 Tab。
- 新增对话列表页和系统设置页。
- 将解锁仪式动画提升到主壳层全局监听。
- 为档案库增加搜索和等级筛选。
- 在对话页增加相关观测调取。
- 为日志列表增加日期分组。
- 增加 `docs/references/` 与 `docs/wiki/` 目录。

因 wiki 地址当前不可访问，异想体清单全面校对不在本阶段完成范围内。

## 4. 系统总体设计

### 4.1 技术架构

项目采用 Flutter + Riverpod + sqflite 的本地优先架构：

| 层级      | 主要职责                                   | 代表文件                         |
| --------- | ------------------------------------------ | -------------------------------- |
| UI 页面层 | 页面展示、交互入口、导航                   | `lib/pages/`                   |
| 组件层    | 网格背景、按钮、遮盖板、仪式动画、图片加载 | `lib/widgets/`                 |
| 状态层    | 全局异想体列表、日记列表、待解锁队列       | `lib/state/app_providers.dart` |
| 服务层    | 共鸣度计算、自动解锁、异想体对话           | `lib/services/`                |
| 仓库层    | 数据库 CRUD、preset 引导                   | `lib/core/`                    |
| 模型层    | 纯数据结构与序列化                         | `lib/models/`                  |
| 资源层    | preset、异想体图像、参考资料               | `assets/`、`docs/`           |

### 4.2 页面结构

当前应用入口为 `MainShellPage`，通过底部导航组织四个主 Tab：

| Tab     | 页面                       | 功能                           |
| ------- | -------------------------- | ------------------------------ |
| LOGS    | `ObservationLogsPage`    | 查看日志、新建观测、按日期分组 |
| GALLERY | `AbnormalityGalleryPage` | 查看已解锁档案、搜索、等级筛选 |
| COMMS   | `CommunicationListPage`  | 查看已解锁异想体会话列表       |
| SYSTEM  | `SettingsPage`           | Key 状态、导出、重置、关于     |

主壳使用 `IndexedStack` 保留 Tab 状态，避免用户在切换页面时丢失筛选、滚动或输入上下文。

### 4.3 数据模型

项目核心模型为 `DiaryEntry` 和 `Abnormality`。

`DiaryEntry` 保存日记正文、附件、认知滤网、创建时间和隐藏匹配结果。它不绑定某一个异想体，因为一条日志可以同时影响多个未解锁异想体。

`Abnormality` 保存异想体档案、语义标签、解锁阈值、隐藏累计值、是否初始解锁、是否已解锁和解锁时间。`currentResonance`、`requiredResonance`、`resonanceDeltas` 均为内部字段，不允许在 UI 中直接展示。

### 4.4 数据持久化

本地数据库使用 sqflite，主要包含两张表：

- `diary_entries`：保存日记、附件、标签和隐藏匹配结果。
- `abnormalities`：保存异想体档案、解锁状态和隐藏累计数据。

首次启动时，如果异想体表为空，系统通过 `PresetLoader.bootstrapAbnormalities()` 从 `assets/presets/abnormalities.json` 初始化数据，并自动解锁 `isInitial == true` 的异想体。

## 5. 关键模块实现

### 5.1 日记系统

日记系统由 `ObservationLogsPage`、`NewEntryPage`、`DiaryRepository` 和 `diaryListProvider` 共同完成。用户在新建页填写文本、选择预设标签或添加自定义标签，并可附加图片。保存后，日记先进入本地数据库，再触发共鸣度计算服务。

v1.2 中，日志列表增加了 TODAY、YESTERDAY、THIS WEEK、EARLIER 分组，使长期使用时的记录浏览更清晰。

### 5.2 共鸣度匹配与自动解锁

`ResonanceService` 负责将日志内容和认知滤网提交给 GLM 匹配服务，要求模型返回结构化 JSON。若真实接口不可用，则使用本地启发式匹配作为降级方案。匹配结果写入 `DiaryEntry.resonanceDeltas`，并累加到对应异想体的 `currentResonance`。

`UnlockService.evaluateAutoUnlock()` 根据隐藏累计值和独立记录天数判断是否解锁异想体。解锁成功后，异想体被加入 `pendingUnlocksProvider`，由 UI 层播放仪式动画。

### 5.3 异想体档案库

档案库页展示已解锁异想体卡片。未解锁项在旧设计中使用 Caution 遮盖板；当前 v1.2 的搜索和筛选逻辑仅展示已解锁项，避免用户通过筛选推断未解锁条目。

档案详情页展示异想体立绘、等级、名称、ID、描述和管理备注，并提供进入对话的按钮。

### 5.4 异想体对话

`AttachmentChatPage` 接入 `AttachmentService`。真实实现通过 GLM / CharGLM 构造角色扮演上下文，Mock 实现用于离线或接口失败场景。对话服务遵守以下约束：

- 不承认自身为 AI。
- 严格按照异想体档案和标签扮演。
- 回复保持简短、克制。
- 不透露共鸣度、阈值或隐藏计算过程。
- 不替用户发言。

v1.2 新增“相关观测”入口，对话页可调出与当前异想体相关的最近日志预览。排序依据隐藏匹配结果，但界面不显示任何分数。

### 5.5 系统设置

`SettingsPage` 提供 GLM Key 状态、模型名称、数据导出、本地重置和关于信息。导出功能将日记和异想体数据序列化为 JSON 并复制到剪贴板；重置功能会清空本地日记和异想体表，再重新加载 presets。

### 5.6 视觉风格

项目视觉风格以黄黑警示色为主，包括：

- 黑色背景。
- 警示黄主色。
- 暗黄提示色。
- 红色警告色。
- 等宽字体。
- 硬边框卡片。
- 网格背景。
- Caution 遮盖板。
- 扫描线式解锁仪式。

`develop.md` 建议后续继续参考 `docs/references/` 中的游戏截图，对字体、AppBar、图标和对话气泡进行进一步打磨。

## 6. 当前完成情况

根据 `TODO.md`，项目已经完成：

- Flutter Android 项目初始化。
- 核心模型与本地数据库。
- Riverpod 状态管理。
- 日记记录 UI。
- 异想体档案库与对话 UI。
- 自动解锁仪式动画。
- v1.1 精简化重构，删除复杂管理系统。
- v1.2 底部导航和体验重构。

根据 `develop.md`，任务二至任务五已完成主要实现；任务一由于 wiki 不可访问，当前只完成 presets 精简与两条异想体数据保留。

当前 presets 状态：

| ID          | 名称       | 等级  | 初始解锁 |
| ----------- | ---------- | ----- | -------- |
| `O-03-03` | 一罪与百善 | ZAYIN | 是       |
| `O-01-12` | 老妇人     | TETH  | 否       |

## 7. 测试与验证

项目文档要求每个阶段执行：

```bash
flutter analyze
flutter test
flutter run
```

本次环境中，`flutter` 与 `dart` 命令未在 PATH 中可用，因此无法完成自动静态分析、格式化和真机运行。已完成的检查包括：

- 使用 UTF-8 解析 `assets/presets/abnormalities.json`，确认条目数为 2。
- 执行 `git diff --check`，未发现空白错误。
- 检查新增文档与目录占位文件存在。
- 检查页面中未直接显示隐藏共鸣度数值。

后续在完整 Flutter 环境中，应重点验证：

- 四个底部 Tab 切换是否流畅且状态保留。
- 新建日志后是否能触发共鸣度计算和自动解锁。
- 解锁动画是否可在任意 Tab 全局弹出。
- 档案库搜索和等级筛选是否只显示已解锁项。
- 对话页真实 GLM 调用与 Mock 降级是否稳定。
- 数据导出和本地重置是否符合预期。

## 8. 风险与改进方向

### 8.1 当前风险

1. wiki 数据未校对：由于无法访问 wiki，异想体官方编号、译名和描述未能全面核验。
3. 素材命名不统一：README 中仍建议按 ID 命名素材，但当前实现已为现有中文命名素材做适配，后续需统一规范。
4. 设置页导出方式较轻量：当前导出到剪贴板，尚未实现文件保存。
5. Markdown 预览未实现：`develop.md` 中将其列为可选项，本阶段未引入 `flutter_markdown`。

### 8.2 可能的后续改进

- wiki 可访问后，补全并校对所有非工具异想体 preset。
- 统一素材命名规范，决定按 ID 或按名称加载，并同步 README。
- 为系统页增加文件导出、分项重置和导入恢复能力。
- 引入可授权字体，进一步贴近原作 UI。
- 根据 `docs/references/` 的截图继续优化 AppBar、图标和聊天气泡。

## 9. 结论

Project Moon Life Record 已经形成一个结构完整、主题明确的 Flutter Android 应用原型。项目以日记记录为入口，以隐藏共鸣度和自动解锁为中间机制，以异想体对话为核心反馈，区别于普通日记工具，也避免了复杂模拟管理系统带来的实现负担。

v1.2 阶段的底部 Tab 重构显著改善了信息架构，使日志、档案、对话和系统设置成为平级功能。全局解锁仪式、相关观测调取、档案筛选和日志分组进一步增强了使用连续性。项目后续的关键工作不在于重新扩大系统复杂度，而在于完成数据校对、运行验证和视觉细化。

---

# 附录 A：参考文档对应关系

| 文档           | 在本报告中的作用                                        |
| -------------- | ------------------------------------------------------- |
| `AGENT.md`   | 项目定位、核心系统逻辑、数据模型、UI/UX 规范、开发禁令  |
| `TODO.md`    | 阶段完成情况、功能实现清单、v1.1 精简化与 v1.2 重构状态 |
| `README.md`  | 技术栈、目录结构、运行方式、系统说明、大模型接入说明    |
| `develop.md` | v1.2 需求来源、任务二至任务五的实现依据、后续校对要求   |

# 附录 B：主要文件结构

```text
lib/
├── core/
│   ├── abnormality_repository.dart
│   ├── database_helper.dart
│   ├── diary_repository.dart
│   ├── glm_client.dart
│   ├── preset_loader.dart
│   ├── secrets.example.dart
│   └── theme.dart
├── models/
│   ├── abnormality.dart
│   └── diary_entry.dart
├── pages/
│   ├── abnormality_detail_page.dart
│   ├── abnormality_gallery_page.dart
│   ├── attachment_chat_page.dart
│   ├── communication_list_page.dart
│   ├── main_shell_page.dart
│   ├── new_entry_page.dart
│   ├── observation_logs_page.dart
│   └── settings_page.dart
├── services/
│   ├── attachment_service.dart
│   ├── resonance_service.dart
│   └── unlock_service.dart
├── state/
│   └── app_providers.dart
└── widgets/
    ├── abnormality_image.dart
    ├── caution_overlay.dart
    ├── extraction_ceremony_widget.dart
    ├── lcorp_button.dart
    └── lcorp_grid_background.dart
```

# 附录 C：核心数据流

```text
用户输入日志
  ↓
NewEntryPage 创建 DiaryEntry
  ↓
DiaryRepository 写入 diary_entries
  ↓
ResonanceService 计算隐藏匹配结果
  ↓
DiaryEntry.resonanceDeltas 回填
  ↓
Abnormality.currentResonance 累加
  ↓
UnlockService 判断 requiredDays 与 requiredResonance
  ↓
pendingUnlocksProvider 入队
  ↓
MainShellPage 播放 ExtractionCeremonyWidget
  ↓
用户进入 Gallery / Comms 与异想体交互
```

# 附录 D：v1.2 需求完成追踪

| develop.md 任务             | 当前状态     | 说明                                                           |
| --------------------------- | ------------ | -------------------------------------------------------------- |
| 任务一：wiki 重写异想体清单 | 部分完成     | wiki 不可访问，当前仅保留两条异想体                            |
| 任务二：底部 Tab 架构       | 已完成       | `MainShellPage` + `BottomNavigationBar` + `IndexedStack` |
| 任务三：原作风格 UI 细化    | 部分完成     | 黄黑色、硬边框、对话气泡和主壳已调整，字体和图标仍可继续优化   |
| 任务四：功能融合优化        | 已完成主要项 | 相关观测、全局仪式、档案筛选、日志分组均已实现                 |
| 任务五：素材目录            | 已完成       | `docs/references/`、`docs/wiki/`、`.gitignore` 已处理    |

# 附录 E：验证清单

- [ ] `flutter pub get`
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] `flutter run`
- [ ] 四个 Tab 切换流畅且状态保留
- [ ] 新建日志后可触发隐藏匹配
- [ ] 满足条件时任意 Tab 均可看到解锁仪式
- [ ] 档案库搜索和筛选只显示已解锁项
- [ ] 对话页相关观测不显示任何共鸣度数值
- [ ] GLM Key 不提交到 git
- [ ] `docs/references/` 可继续放置截图
- [ ] wiki 可访问后补充官方数据校对
