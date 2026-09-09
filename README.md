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
| [`find-simplifications`](find-simplifications/) | 全仓扫描死代码 / 重复 / 过度设计，产出可落地的简化提案 |
| [`useless-code-cleanup`](useless-code-cleanup/) | 移除无意义兜底与废话注释，行为不变 |

### 个人写作与发布

| Skill | 用途 |
|---|---|
| [`my-doc-style`](my-doc-style/) | 按本人写作风格产出中文文档（测试指引 / 操作手册 / README / wiki） |
| [`release-tag`](release-tag/) | 交互式发版：分析 diff 定版本号、生成 changelog、打 tag 推送 |

### Waza · 工程习惯（vendor 子模块：[tw93/Waza](https://github.com/tw93/Waza)）

把"动手前先想"、"交付前自检"、"出错先定位根因"这类工程习惯包装成可调用的 skill。每个 skill 一个明确触发点、一件事做透，不互相串联——切换由用户手动决定。

| Skill | 触发场景 | 做什么 |
|---|---|---|
| [`think`](vendor/Waza/plugins/waza/skills/think/) | 动手做新功能 / 架构决策 / 价值判断之前 | 挑战需求、压测设计、把粗想法落成可执行方案 |
| [`ui`](vendor/Waza/plugins/waza/skills/ui/) | 做 UI / 组件 / 页面 / 视觉界面 / 截图打磨 | 产出有美学主张的前端实现，不走通用默认风（v3.36 起取代 design） |
| [`check`](vendor/Waza/plugins/waza/skills/check/) | 实现完成、合并前 | review diff、自动修小问题、必要时分派 security 与 architecture 审查；也用于 issue / PR triage |
| [`hunt`](vendor/Waza/plugins/waza/skills/hunt/) | 报错 / 崩溃 / 测试失败 / 行为异常 | 系统化排查，先定位根因再动手修 |
| [`read`](vendor/Waza/plugins/waza/skills/read/) | 任何 URL 或 PDF | 取回干净 Markdown，针对 GitHub / 微信 / 飞书 / X 等做平台路由 |
| [`learn`](vendor/Waza/plugins/waza/skills/learn/) | 深度研究一个陌生领域 | 六阶段研究：收集 → 消化 → 提纲 → 填充 → 精修 → 自审 |
| [`write`](vendor/Waza/plugins/waza/skills/write/) | 写稿 / 改稿 / 润色 | 去 AI 味，把行文调成自然的中英文表达 |
| [`health`](vendor/Waza/plugins/waza/skills/health/) | Claude 不听话 / hook 失灵 / MCP 异常 | 审计 CLAUDE.md、rules、skills、hooks、MCP，按严重度报告问题（仅 Claude Code） |

**常见手动串联**

- `/think` 出方案 → 实施 → `/check` 把关 → 合并
- `/read` 取回多篇 URL → `/learn` 综合成文 → `/write` 去 AI 味
- `/hunt` 定位根因 → 修复 → `/check` 确认无副作用

### Kami · 文档排版（vendor 子模块：[tw93/kami](https://github.com/tw93/kami)）

把简历、一页纸、白皮书、信件、作品集、幻灯片、研报、更新日志统一到一套"暖米色 + 墨蓝"的衬线排版语言上。中文 TsangerJinKai02、英文 Charter、日文 YuMincho（best-effort）。

| Skill | 触发短语 |
|---|---|
| [`kami`](vendor/kami/plugins/kami/skills/kami/) | "做 PDF / 排版 / 一页纸 / 白皮书 / 简历 / 作品集 / PPT"，"build me a resume / make a one-pager / design a slide deck" |

> 中文字体（TsangerJinKai02，约 36MB）在 [tw93/kami](https://github.com/tw93/kami) 仓库里跟随子模块直接 checkout；如果用浅克隆或精简 checkout 缺了字体，`SKILL.md` 描述的脚本会从 jsDelivr CDN 自动补齐。WeasyPrint、Python 等构建依赖按上游 README 自行安装。

### 其他第三方（vendor 子模块 + allowlist）

仓库把日常在用的第三方 skill 以子模块形式收进 `vendor/`。**不是**上游仓库里的每个 skill 都会被安装——`install.sh` 只链接 `vendor/.allowlists/<子模块>` 白名单里列出的（没有白名单的子模块则全量发布）。要加/减技能，编辑对应白名单文件后重跑 `./install.sh` 即可。

| vendor 子模块 | 收录 skill（白名单） | 上游 |
|---|---|---|
| [`mattpocock-skills`](vendor/mattpocock-skills/) | 20 个：ask-matt、code-review、codebase-design、diagnosing-bugs、domain-modeling、grill-me/grill-with-docs/grilling、handoff、implement、improve-codebase-architecture、prototype、research、setup-matt-pocock-skills、tdd、teach、to-spec/to-tickets/triage、wayfinder | [mattpocock/skills](https://github.com/mattpocock/skills) |
| [`anthropics-skills`](vendor/anthropics-skills/) | frontend-design | [anthropics/skills](https://github.com/anthropics/skills) |
| [`yutto-dev-yutto`](vendor/yutto-dev-yutto/) | bilibili-video-download | [yutto-dev/yutto](https://github.com/yutto-dev/yutto) |
| [`humanizer-zh`](vendor/humanizer-zh/) | humanizer-zh | [op7418/Humanizer-zh](https://github.com/op7418/Humanizer-zh) |
| [`larksuite-meegle-cli`](vendor/larksuite-meegle-cli/) | meegle | [larksuite/meegle-cli](https://github.com/larksuite/meegle-cli) |
| [`larksuite-cli`](vendor/larksuite-cli/) | lark-* 27 个（白名单内；官方 `skills/` 另有 `lark-meeting`，需要时加进 `vendor/.allowlists/larksuite-cli` 即可启用） | [larksuite/cli](https://github.com/larksuite/cli) |
| [`vercel-labs-skills`](vendor/vercel-labs-skills/) | find-skills | [vercel-labs/skills](https://github.com/vercel-labs/skills) |
| [`brianlovin-claude-config`](vendor/brianlovin-claude-config/) | simplify | [brianlovin/claude-config](https://github.com/brianlovin/claude-config) |
| [`humanlayer-skills`](vendor/humanlayer-skills/) | show-me | [humanlayer/skills](https://github.com/humanlayer/skills) |
| [`cursor-plugins`](vendor/cursor-plugins/) | thermo-nuclear-code-quality-review | [cursor/plugins](https://github.com/cursor/plugins) |
| [`yetone-kill-ai-slop`](vendor/yetone-kill-ai-slop/) | kill-ai-slop | [yetone/kill-ai-slop](https://github.com/yetone/kill-ai-slop) |

另有两个单 skill vendor（无白名单，全量发布）：[`native-feel-skill`](vendor/native-feel-skill/) 与 [`yansu-skill`](vendor/yansu-skill/)。

## 安装

把下面这段 prompt 丢给目标 Agent（Claude Code / Cursor / Codex CLI 等），它会把仓库里所有 skill 都软链到自己的 skills 目录：

```
Install the my-skills collection for me:

1. Clone https://github.com/b1ngsha/skills (with --recurse-submodules)
   to a stable local path like ~/Documents/code/my-skills.
2. Symlink every SKILL.md under `<repo>/*/` and `<repo>/vendor/*/` (any depth)
   into your user-level skills dir (e.g. `~/.claude/skills/` for Claude Code).
   Respect `vendor/.allowlists/<submodule>` whitelists when present.
   Skip any name that already exists as a real file/dir.
3. Confirm the install path and the list of installed skills when done.
```

软链直接指向本仓源文件，`git pull` 后所有 Agent 立即生效。

### Fallback：脚本安装

不想让 Agent 代劳、或者要批量装到全部 Agent 时，用脚本：

```bash
git clone --recurse-submodules https://github.com/b1ngsha/skills.git ~/Documents/code/my-skills
cd ~/Documents/code/my-skills
./install.sh              # 更新仓库 + vendor 子模块，然后（重）链接（幂等）
./install.sh link         # 只重链接，不联网
./install.sh dry-run      # 预览变更
./install.sh uninstall    # 仅删除本脚本创建的软链
# SKIP_UPDATE=1 ./install.sh   # 跳过 git pull / 子模块刷新
```

脚本会扫描以下目录，只对父目录已存在的 Agent 操作：`~/.cursor/skills/`、`~/.codex/skills/`、`~/.claude/skills/`、`~/.agents/skills/`。已存在的真实文件或目录会跳过（例如 `npx skills` CLI 安装的实体目录），绝不覆盖。

漏加 `--recurse-submodules` 时补：

```bash
git submodule update --init --recursive
```

## 更新

一条命令完成全部（本仓代码 + 14 个 vendor 子模块 + 重链）：

```bash
./install.sh
```

等价于：

```bash
git pull --ff-only
git submodule update --recursive --remote   # Waza、kami、mattpocock、anthropics …
./install.sh link
```

- vendor 子模块指针移动后不会自动提交，脚本会提示固化：`git add vendor && git commit -m "bump vendor skills"`。
- 软链直接指向源文件，pull 完立即对所有 Agent 生效；每次运行都会补上新出现的 skill 链接。
- 修改某 vendor 收录范围：编辑 `vendor/.allowlists/<子模块>` 后重跑 `./install.sh link`。

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
