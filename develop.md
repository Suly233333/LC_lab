# DEVELOP.md — 下一阶段开发需求文档（v1.2）

> 本文件为下一位接手开发的 AI / 工程师准备。请先通读 `AGENT.md`、`README.md`、`TODO.md` 了解项目现状，再按本文档执行。
> 当前已完成版本：v1.1 精简版（日记记录 / 共鸣度累计 / 异想体对话 + 黄黑原作风格 UI）。

---

## 0. 参考资料

- 脑叶公司中文 Wiki：<https://lobotomycorp.fandom.com/zh/wiki/%E8%84%91%E5%8F%B6%E5%85%AC%E5%8F%B8_Wiki>
- **游戏内截图素材目录（新增）**：`docs/references/`
  - 由用户人工放置脑叶公司游戏截图，用于 UI 风格、字体、交互对照
  - 命名建议：`<场景>-<编号>.png`，例如：`main-menu-01.png` / `agent-list-02.png` / `abnormality-info-01.png`
- 项目内已有 wiki 链接锚点：`AGENT.md` 第 0 节

---

## 1. 主要任务

### 1.1 任务一：按 wiki 重写异想体清单（高优先级）

当前 `assets/presets/abnormalities.json` 中的 32 条异想体是凭原作公开常识构造的，**ID 编号、名称、描述与官方 wiki 存在出入**。需要：

1. **逐条对照 wiki**修正：
   - `id`：必须严格匹配 wiki 上的官方编号格式（如 `O-01-45` / `T-01-12` / `F-04-23` / `D-01-XX` 等）
   - `name`：使用 wiki 中文页的官方译名
   - `grade`：风险等级 `ZAYIN` / `TETH` / `HE` / `WAW` / `ALEPH`
   - `description`：基于 wiki 的"档案文本 / 外观描述"提炼 2-3 句
   - `manageNote`：基于 wiki 的"管理方式 / 收容备注"提炼 1-2 句
   - `featureTags`：从 wiki 描述中抽取 4-8 个语义标签（共鸣度匹配引擎依赖此字段）
   - `requiredDays` / `requiredResonance`：按等级递增设置合理阈值（参考下表）
2. **覆盖范围**：除工具异想体（Tool）外，加入游戏所有非工具异想体（v1.0 ~ DLC 各代名作均收录）
3. **`isInitial: true`** 仅留「一罪与百善」（O-03-03）一条

**阈值建议表**（仅作参考，可按异想体规模酌情调整）：

| 等级 | requiredDays | requiredResonance |
| ---- | ------------ | ----------------- |
| ZAYIN | 1 ~ 2 | 20 ~ 35 |
| TETH | 3 ~ 5 | 45 ~ 75 |
| HE | 6 ~ 8 | 80 ~ 115 |
| WAW | 9 ~ 11 | 130 ~ 170 |
| ALEPH | 12 ~ 16 | 200 ~ 300 |

### 1.2 任务二：UI 重构成微信式底栏架构（高优先级）

当前结构是"日志列表 → 顶栏跳档案库 → 详情页 → 对话页"的纵向跳转。需改为**底部 Tab 切换**的扁平结构（参考微信主界面）：

```
┌─────────────────────────────────┐
│  [AppBar: 当前 Tab 标题]         │
├─────────────────────────────────┤
│                                 │
│       Tab 内容区域              │
│                                 │
├─────────────────────────────────┤
│ [日记]  [档案]  [对话]  [我的] │
└─────────────────────────────────┘
```

**Tab 设计**：

| 索引 | 图标 | 文字 | 内容 |
| ---- | ---- | ---- | ---- |
| 0 | menu_book | 观测 / LOGS | 现 `ObservationLogsPage`：日记列表 + 新建按钮 |
| 1 | folder_special | 档案 / GALLERY | 现 `AbnormalityGalleryPage`：异想体档案库 |
| 2 | forum | 对话 / COMMS | **新页面**：已解锁异想体列表（仿微信会话列表）→ 点击进入对话 |
| 3 | settings | 设置 / SYSTEM | **新页面**：GLM 密钥状态、数据导出/重置、关于、共鸣度调试开关（仅开发者） |

**实现要点**：
- 新增 `lib/pages/main_shell_page.dart`（顶层壳，含 `BottomNavigationBar`）
- `main.dart` 的 `home` 替换为 `MainShellPage`
- 用 `IndexedStack` 保留 Tab 状态
- 底栏选中色 = 警示黄 `#FFD700`，未选中 = 暗黄 `hint #B8A14A`
- 顶栏标题随 Tab 联动
- 移除 `ObservationLogsPage` 顶栏中的"GALLERY"入口（已由底栏承担）

### 1.3 任务三：原作风格 UI 细化（中优先级）

参考 `docs/references/` 中的截图，按下列方向打磨：

- **字体**：尽量贴近原作的等宽/像素风（已用 `monospace` 占位，建议根据截图选用一款 OFL/Apache 许可的等宽中文/英文字体打包到 `assets/fonts/`）
- **AppBar**：参考原作"DEPARTMENT BANNER"——黄底黑字大色块标题
- **列表卡片**：原作风格是"硬边框 + 等宽信息行 + 状态色块"，去除当前 Material 阴影
- **图标**：尽量用方形/像素 SVG 或图标字体替换 Material Icons
- **过渡动画**：保持克制；解锁仪式动画的扫描线节奏可放慢、加机械"哒哒"声效（可选）
- **对话气泡**：原作风格是黄色细边框 + 内部硬切角，可参考截图重做 `_Bubble`

### 1.4 任务四：功能融合优化（中优先级）

**4.1 日记 → 对话联动**
- 在对话页右上角加入"调取相关观测"按钮：调出与该异想体共鸣最高的最近 N 条日记缩略，让对话有上下文感
- 注意：**仍不可显示共鸣度数值**，仅按 deltas 排序展示日记预览

**4.2 解锁仪式动画体验**
- 当前在 `AbnormalityGalleryPage` 的 `initState` + `ref.listen` 触发；若用户停留在日记页解锁，动画需跨页弹出
- 建议：用 `OverlayEntry` 在 `MainShellPage` 层全局监听 `pendingUnlocksProvider`，无论当前 Tab 都能弹出

**4.3 异想体搜索 / 筛选**
- 档案库页加入按等级筛选条（ALL / ZAYIN / TETH / HE / WAW / ALEPH 黄色色块）
- 顶部加入按名称搜索框（仅搜已解锁项；未解锁项即使匹配也不显示）

**4.4 日记体验**
- 列表项加入按日期分组（"今日 / 昨日 / 本周 / 更早"）
- 编辑页支持简单 Markdown 实时预览（可选，用 `flutter_markdown` 包）

### 1.5 任务五：素材目录（低优先级）

- 新增目录：`docs/references/`（已建）— 用户会陆续放入游戏截图
- 新增目录建议：`docs/wiki/` — 存放 wiki 抓取的原文片段（markdown），便于离线对照
- 在仓库根更新 `.gitignore`：保留这些目录但忽略其中的临时缓存（如 `.DS_Store`）

---

## 2. 不要做的事

1. **不要重新引入**已删除的工作系统 / 突破 / 镇压 / EGO 装备 / Agent 员工 / PE Box / Qliphoth 计数器
2. **不要在任何 UI** 显示 `currentResonance` / `requiredResonance` / `resonanceDeltas` 的数值或进度条
3. **不要修改** `lib/core/secrets.dart`（已 gitignore，含真实 API Key）
4. **不要在 abnormalities.json 中添加 `workReactions` / `workTypeWeights` / `breachType` 等已废弃字段**

---

## 3. 验证清单

完成上述任务后，请按以下顺序自检：

```bash
flutter analyze        # 必须 No issues found
flutter run            # 真机/模拟器跑通
```

人工验证：
- [ ] 底栏 4 个 Tab 切换流畅，状态保留
- [ ] 写日记 → 命中异想体 featureTags → 满足阈值时不论在哪个 Tab 都能看到仪式动画
- [ ] 档案库筛选 + 搜索可用
- [ ] 异想体清单与 wiki 比对至少 90% 一致
- [ ] 对话页能成功调用 GLM；离线/Key 失效时降级到 Mock 不崩
- [ ] 各页面主题色全为黄黑色块，无残留蓝色
- [ ] `docs/references/` 目录存在，可正常添加截图

---

## 4. 文件改动清单（预估）

**新增**
- `lib/pages/main_shell_page.dart`
- `lib/pages/communication_list_page.dart`（已解锁异想体会话列表）
- `lib/pages/settings_page.dart`
- `docs/references/.gitkeep`
- 可能：`assets/fonts/<等宽字体>.ttf`

**修改**
- `lib/main.dart`：home 改为 `MainShellPage`
- `lib/pages/observation_logs_page.dart`：去掉顶栏 GALLERY 入口
- `lib/pages/abnormality_gallery_page.dart`：加搜索 + 筛选
- `lib/pages/attachment_chat_page.dart`：加"相关观测"侧栏
- `assets/presets/abnormalities.json`：按 wiki 全面校对
- `pubspec.yaml`：可能新增 `flutter_markdown`、字体声明
- `AGENT.md` / `TODO.md` / `README.md`：同步新结构

---

## 5. 提交规范

- 按子任务粒度提交；单个 commit 不要混合多个独立改动
- commit message 格式：`feat|fix|refactor|chore: <简述>`
- 完成全部任务后，把本文件 `develop.md` 标记为已归档（在头部加 `> Status: archived`），**不要删除**，作为历史需求记录
