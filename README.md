# my-skills

跨 Agent 的 skill 集合。同一份 SKILL.md 在 Cursor、Codex CLI、Claude Code 以及任何遵循 [Agent Skills](https://github.com/anthropics/skills) 约定的 Agent 中都能被识别。

## Skills

### 工程审查与重构

| Skill | 用途 |
|---|---|
| [`backend-code-review`](backend-code-review/) | Django + DRF + Python 代码审查（安全、ORM、类型、性能） |
| [`rn-code-review`](rn-code-review/) | React Native + Expo + TypeScript 代码审查（PR 级 + 单文件深度） |
| [`figma-to-rn`](figma-to-rn/) | 将 Figma 设计稿转换为 React Native + Gluestack-UI 组件 |
| [`refactor-entropy-cleanup`](refactor-entropy-cleanup/) | 整理多轮 AI 编辑后累积的目录熵 |
| [`architecture-design-review`](architecture-design-review/) | 多仓架构审查，带严格上下文预算控制 |
| [`security-review`](security-review/) | 威胁模型驱动的全栈安全审查（后端 / 前端 / 移动端 / 基础设施） |

### Waza · 工程习惯（来自 [tw93/Waza](https://github.com/tw93/Waza)）

把"动手前先想"、"交付前自检"、"出错先定位根因"这类工程习惯包装成可调用的 skill。每个 skill 一个明确触发点、一件事做透，不互相串联——切换由用户手动决定。

| Skill | 触发场景 | 做什么 |
|---|---|---|
| [`think`](think/) | 动手做新功能 / 架构决策 / 价值判断之前 | 挑战需求、压测设计、把粗想法落成可执行方案 |
| [`design`](design/) | 做 UI / 组件 / 页面 / 视觉界面 | 产出有美学主张的前端实现，不走通用默认风 |
| [`check`](check/) | 实现完成、合并前 | review diff、自动修小问题、必要时分派 security 与 architecture 审查；也用于 issue / PR triage |
| [`hunt`](hunt/) | 报错 / 崩溃 / 测试失败 / 行为异常 | 系统化排查，先定位根因再动手修 |
| [`read`](read/) | 任何 URL 或 PDF | 取回干净 Markdown，针对 GitHub / 微信 / 飞书 / X 等做平台路由 |
| [`learn`](learn/) | 深度研究一个陌生领域 | 六阶段研究：收集 → 消化 → 提纲 → 填充 → 精修 → 自审 |
| [`write`](write/) | 写稿 / 改稿 / 润色 | 去 AI 味，把行文调成自然的中英文表达 |
| [`health`](health/) | Claude 不听话 / hook 失灵 / MCP 异常 | 审计 CLAUDE.md、rules、skills、hooks、MCP，按严重度报告问题（仅 Claude Code） |

**常见手动串联**

- `/think` 出方案 → 实施 → `/check` 把关 → 合并
- `/read` 取回多篇 URL → `/learn` 综合成文 → `/write` 去 AI 味
- `/hunt` 定位根因 → 修复 → `/check` 确认无副作用

### Kami · 文档排版（来自 [tw93/kami](https://github.com/tw93/kami)）

把简历、一页纸、白皮书、信件、作品集、幻灯片、研报、更新日志统一到一套"暖米色 + 墨蓝"的衬线排版语言上。中文 TsangerJinKai02、英文 Charter、日文 YuMincho（best-effort）。

| Skill | 触发短语 |
|---|---|
| [`kami`](kami/) | "做 PDF / 排版 / 一页纸 / 白皮书 / 简历 / 作品集 / PPT"，"build me a resume / make a one-pager / design a slide deck" |

> 字体没有打包进仓库（中文字 36MB），首次构建中文文档时 `kami/SKILL.md` 描述的脚本会从 jsDelivr CDN 自动拉取到 `assets/fonts/`。WeasyPrint、Python 等构建依赖请按 [tw93/kami](https://github.com/tw93/kami) 的说明自行安装。

## 安装

将每个 skill 软链到所有检测到的 Agent skills 目录。仓库更新即刻生效，无需复制同步。

```bash
git clone https://github.com/<user>/my-skills.git ~/Documents/code/my-skills
cd ~/Documents/code/my-skills
./install.sh
```

支持的目标目录：

| Agent | 路径 |
|---|---|
| Cursor | `~/.cursor/skills/` |
| Codex CLI | `~/.codex/skills/` |
| Claude Code | `~/.claude/skills/` |
| 通用 | `~/.agents/skills/` |

只对父目录（`~/.cursor`、`~/.codex` 等）已存在的 Agent 进行操作，未安装的 Agent 会静默跳过。

## 命令

```bash
./install.sh              # 幂等安装（默认）
./install.sh dry-run      # 预览变更，不写入
./install.sh uninstall    # 仅删除本脚本创建的软链
```

`install` 拒绝覆盖目标路径上已存在的真实文件或目录——只会处理指向本仓库的软链，避免误删。

## 更新

```bash
git -C ~/Documents/code/my-skills pull
```

软链直接指向源文件，`git pull` 就是完整的更新流程。只有新增 skill 目录时才需要重跑 `install.sh`。

## 使用

安装后宿主 Agent 会自动发现 skill。提到 skill 名称或使用 `description` frontmatter 中的触发短语即可调用：

| Agent | 调用方式 |
|---|---|
| Cursor | `/skill-name` 斜杠命令，或由 description 匹配自动触发 |
| Codex CLI | 当 description 匹配当前 prompt 时自动加载 |
| Claude Code | `Skill` 工具调用；description 匹配时自动建议 |

## 新增 skill

```
my-new-skill/
└── SKILL.md            # 必需：YAML frontmatter（name、description）+ 正文
└── references/         # 可选：渐进披露的细节文件
    └── *.md
```

放好后重跑 `./install.sh` 即可。格式参考任意现有 skill，例如 [`security-review/SKILL.md`](security-review/SKILL.md)。

## License

MIT.
