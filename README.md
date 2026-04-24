# my-skills

跨 Agent 的 skill 集合。同一份 SKILL.md 在 Cursor、Codex CLI、Claude Code 以及任何遵循 [Agent Skills](https://github.com/anthropics/skills) 约定的 Agent 中都能被识别。

## Skills

| Skill | 用途 |
|---|---|
| [`backend-code-review`](backend-code-review/) | Django + DRF + Python 代码审查（安全、ORM、类型、性能） |
| [`rn-code-review`](rn-code-review/) | React Native + Expo + TypeScript 代码审查（PR 级 + 单文件深度） |
| [`figma-to-rn`](figma-to-rn/) | 将 Figma 设计稿转换为 React Native + Gluestack-UI 组件 |
| [`refactor-entropy-cleanup`](refactor-entropy-cleanup/) | 整理多轮 AI 编辑后累积的目录熵 |
| [`architecture-design-review`](architecture-design-review/) | 多仓架构审查，带严格上下文预算控制 |
| [`security-review`](security-review/) | 威胁模型驱动的全栈安全审查（后端 / 前端 / 移动端 / 基础设施） |

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
