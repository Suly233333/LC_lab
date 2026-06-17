# Project Moon Life Record 实验报告

## 摘要

本实验围绕一个基于 Flutter 的 Android 生活记录与异想体对话应用展开。项目采用 Lobotomy Corporation 风格的黄黑工业 UI，将日记记录、语义匹配解锁和角色对话整合为一个轻量化移动端原型。本阶段工作的重点是完成 v1.2 体验重构：将原本纵向跳转结构改造为底部 Tab 主壳，新增对话列表和系统设置页，优化档案库筛选、日志分组、相关观测调取和素材目录管理，并在不访问外部 wiki 的前提下，仅保留“一罪与百善”和“老妇人”两条异想体预设。

实验结果表明，重构后的应用结构更符合移动端高频使用习惯，关键业务状态能够跨 Tab 保留，解锁仪式动画可以在全局触发。同时，系统继续遵守“共鸣度不可见”的设计原则：隐藏分值只参与排序、解锁和导出，不在用户界面直接展示。

## 1. 实验背景

项目目标是构建一个沉浸式生活记录应用。用户通过观测日志记录日常内容，系统将文本和认知滤网标签交给语义匹配服务，匹配结果用于累积异想体解锁条件。异想体解锁后，用户可以进入对话页面，与基于档案设定生成的角色进行自由沟通。

上一版本已经完成基础数据模型、本地数据库、日记写入、异想体解锁和对话功能，但页面组织仍以“日志页跳转档案库，再跳转详情和对话”的线性结构为主。该结构不利于长期使用，也使对话入口和设置入口不够清晰。因此，本实验在保留核心业务逻辑的前提下，进行 UI 架构和局部交互重构。

## 2. 实验目标

本阶段目标包括五类：

1. 按任务要求处理异想体 preset，仅保留“一罪与百善”和“老妇人”。
2. 将应用改造为底部 Tab 架构，包含 LOGS、GALLERY、COMMS、SYSTEM 四个入口。
3. 改进原作风格 UI，使页面继续保持黄黑色块、等宽字体和硬边框风格。
4. 融合日志、解锁、对话之间的功能体验，包括全局解锁动画、相关观测调取、档案筛选和日志分组。
5. 补充素材目录与项目文档，并形成实验报告。

由于当前环境无法访问 wiki，官方档案全面校对任务被跳过，仅围绕现有两条异想体开展数据和功能工作。

## 3. 实验环境

项目技术栈如下：

| 模块 | 技术 |
| --- | --- |
| 客户端框架 | Flutter / Dart |
| 状态管理 | flutter_riverpod |
| 本地存储 | sqflite |
| 多媒体 | image_picker |
| 大模型接口 | GLM / CharGLM 兼容服务 |
| 目标平台 | Android |

本次实验所在工作区为 `D:\LC_lab\LC_lab`。由于系统 PATH 中未检测到 `flutter` 和 `dart` 命令，自动格式化、`flutter analyze` 和真机运行验证未能在本环境执行。

## 4. 系统设计

### 4.1 数据设计

核心数据模型保持两类：

- `DiaryEntry`：保存日记正文、附件、认知滤网、创建时间和隐藏匹配结果。
- `Abnormality`：保存异想体 ID、名称、等级、语义标签、解锁阈值、当前隐藏共鸣度、解锁状态、描述和管理备注。

本阶段将 `assets/presets/abnormalities.json` 收缩为两条记录：

- `O-03-03`：一罪与百善，初始解锁。
- `O-01-12`：老妇人，TETH 等级，后续通过日志匹配解锁。

### 4.2 页面架构

新增 `MainShellPage` 作为应用首页，使用 `BottomNavigationBar` 和 `IndexedStack` 组织四个页面：

| Tab | 页面 | 功能 |
| --- | --- | --- |
| LOGS | `ObservationLogsPage` | 观测日志列表与新建入口 |
| GALLERY | `AbnormalityGalleryPage` | 异想体档案库 |
| COMMS | `CommunicationListPage` | 已解锁异想体对话列表 |
| SYSTEM | `SettingsPage` | Key 状态、导出、重置、关于 |

`IndexedStack` 的作用是保留各 Tab 的滚动位置、输入状态和筛选状态，避免用户切换时丢失上下文。

### 4.3 全局解锁仪式

旧实现中，解锁仪式动画由档案库页监听 `pendingUnlocksProvider`。本阶段将监听逻辑移动到 `MainShellPage`，使用户无论停留在哪个 Tab，写入日志并触发解锁后都能看到仪式动画。

### 4.4 神秘感约束

项目要求任何 UI 不得展示 `currentResonance`、`requiredResonance`、`resonanceDeltas` 的数值。本阶段新增的“相关观测”功能内部使用 `resonanceDeltas` 对日志排序，但界面只显示日期、文本预览和标签，不显示分数或进度。

## 5. 实现过程

### 5.1 Preset 精简

`abnormalities.json` 被重写为两条异想体记录，删除其他 preset 条目。`isInitial: true` 仅保留在“一罪与百善”上，满足初始解锁要求。

### 5.2 主壳与 Tab

新增 `lib/pages/main_shell_page.dart`，将 `main.dart` 的 `home` 从 `ObservationLogsPage` 改为 `MainShellPage`。底部栏选中颜色为 `#FFD700`，未选中颜色为 `#B8A14A`，顶部标题随 Tab 联动。

### 5.3 对话列表与设置页

新增 `CommunicationListPage`，按已解锁异想体生成会话列表，点击进入 `AttachmentChatPage`。

新增 `SettingsPage`，提供：

- GLM API Key 配置状态；
- 聊天模型和匹配模型显示；
- 数据导出到剪贴板；
- 本地数据确认重置；
- 调试开关占位说明；
- 项目版本与模块说明。

### 5.4 档案库筛选

`AbnormalityGalleryPage` 新增搜索框和等级筛选条。筛选范围限定为已解锁条目，避免用户通过搜索命中推断未解锁异想体。

### 5.5 日志和对话联动

`AttachmentChatPage` 新增“相关观测”入口。用户可在对话页右上角打开相关日志面板，查看与当前异想体最相关的最近观测预览。排序基于隐藏匹配结果和创建时间，但不展示任何隐藏数值。

`ObservationLogsPage` 新增日期分组，将日志分为 TODAY、YESTERDAY、THIS WEEK、EARLIER，提升浏览效率。

### 5.6 素材和文档目录

新增：

- `docs/references/.gitkeep`
- `docs/wiki/.gitkeep`

并更新 `.gitignore`，默认忽略 `docs/wiki/` 中的缓存内容，同时保留目录结构。

## 6. 实验结果

本阶段完成了任务 2-5 的主要工程内容：

| 任务 | 完成情况 |
| --- | --- |
| UI 底部 Tab 重构 | 已完成 |
| 原作风格 UI 细化 | 已完成基础色彩、硬边框、底栏和聊天气泡调整 |
| 功能融合优化 | 已完成全局解锁动画、相关观测、档案筛选、日志分组 |
| 素材目录 | 已完成 `docs/references` 和 `docs/wiki` 占位及忽略规则 |
| 项目文档 | 已更新 README、TODO、AGENT，并新增本报告 |

此外，为了让现有中文命名图片素材正常显示，异想体图片路径推导改为使用异想体名称匹配资源文件。

## 7. 测试与验证

已完成的本地检查：

- 使用 PowerShell 显式 UTF-8 解析 `abnormalities.json`，确认只包含两条记录。
- 检查 `assets/presets` 下仅存在 `abnormalities.json`。
- 人工检查新增页面、provider 调用、数据重置和导出逻辑。

未完成的自动检查：

- `flutter analyze` 未执行：当前 shell 无法识别 `flutter` 命令。
- `flutter run` 未执行：当前 shell 无法识别 `flutter` 命令，且未连接 Android 设备或模拟器。

后续在具备 Flutter SDK 的环境中，应优先执行：

```bash
flutter pub get
flutter analyze
flutter run
```

## 8. 结论

本实验完成了项目从线性页面跳转到四 Tab 移动端主结构的转型，补齐了对话入口、系统设置、档案筛选、日志分组和跨页面解锁仪式等关键体验。重构后的项目结构更适合继续扩展，也更符合移动端长期记录类应用的使用方式。

在设计约束方面，本阶段继续维持隐藏共鸣度原则。新增功能虽然内部读取隐藏字段进行排序和状态判断，但没有在 UI 中显示具体数值、百分比或进度条。

主要风险在于当前环境无法执行 Flutter 静态分析和真机验证，因此仍需在完整 Flutter 开发环境中进行一次编译级检查。

## 附录 A：主要改动文件

| 文件 | 说明 |
| --- | --- |
| `lib/main.dart` | 首页改为 `MainShellPage` |
| `lib/pages/main_shell_page.dart` | 新增底部 Tab 主壳与全局解锁仪式监听 |
| `lib/pages/communication_list_page.dart` | 新增已解锁异想体对话列表 |
| `lib/pages/settings_page.dart` | 新增系统页、导出、重置与状态显示 |
| `lib/pages/observation_logs_page.dart` | 移除顶部 GALLERY 入口，新增日志分组 |
| `lib/pages/abnormality_gallery_page.dart` | 新增搜索与等级筛选 |
| `lib/pages/attachment_chat_page.dart` | 新增相关观测面板 |
| `lib/core/abnormality_repository.dart` | 新增清空全部异想体数据方法 |
| `lib/core/diary_repository.dart` | 新增清空全部日志数据方法 |
| `lib/models/abnormality.dart` | 图片资源路径改为按名称匹配 |
| `assets/presets/abnormalities.json` | 仅保留两条异想体 |
| `.gitignore` | 新增 wiki 缓存忽略规则 |
| `README.md` / `TODO.md` / `AGENT.md` | 同步 v1.2 结构说明 |

## 附录 B：当前 Preset 摘要

| ID | 名称 | 等级 | 初始解锁 |
| --- | --- | --- | --- |
| `O-03-03` | 一罪与百善 | ZAYIN | 是 |
| `O-01-12` | 老妇人 | TETH | 否 |

## 附录 C：后续建议

1. 在可用 Flutter 环境中执行 `flutter analyze` 和真机运行验证。
2. 若后续能访问 wiki，再补全官方档案字段校对。
3. 为数据导出增加文件保存选项，目前版本先采用剪贴板导出。
4. 为设置页重置操作增加更细粒度选项，例如仅清空日志或仅重建异想体档案。
