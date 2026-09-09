---
name: release-tag
description: Interactive release workflow. Asks the user which branch to release, analyzes the diff since the last tag to derive a semantic version bump (major/minor/patch), generates a changelog and updates CHANGELOG.md, then creates an annotated tag and pushes to the remote after user confirmation. Use when the user mentions releasing a version, cutting a release, tagging, bumping the version, or generating a changelog.
---

# Release Tag

Interactive release flow: pick branch → analyze diff → derive version → generate changelog → user confirmation → tag and push.

**Language rule: all interaction with the user (questions, confirmation prompts, changelog content, and final reports) must be in Chinese.**

## Preflight Checks

Verify the following before starting. If any check fails, stop and inform the user:

1. Clean working tree: `git status --porcelain` produces no output (uncommitted changes other than CHANGELOG.md would pollute the release commit).
2. Fetch latest remote state: `git fetch --all --tags --prune`.

## Workflow

### Step 1: Choose the release branch

List candidate branches:

```bash
git branch -r --sort=-committerdate --format='%(refname:short)' | head -10
```

Use AskQuestion (in Chinese) to let the user pick the branch to release, with main/master as the recommended first option. After selection, check out and sync with the remote:

```bash
git checkout <branch> && git pull --ff-only
```

### Step 2: Determine the previous version

Always resolve the latest version from the **remote** repository, not from local tags (local tags may be stale or contain unpushed tags):

```bash
git ls-remote --tags origin 'v*' | grep -v '\^{}' | awk -F/ '{print $NF}' | sort -V | tail -1
```

- Tag found (e.g. `v1.4.2`) → diff range is `<last-tag>..HEAD`. The preflight `git fetch --all --tags --prune` guarantees the tag exists locally for diffing.
- No tags on the remote → this is the first release; suggest `v0.1.0` by default (or `v1.0.0`, confirm with the user), and use the full history as the diff range.
- The latest remote tag already points at HEAD (`git rev-parse <last-tag>^{commit}` equals `git rev-parse HEAD`) → nothing new to release; stop and inform the user.

### Step 3: Analyze the diff and derive the version

Collect change information:

```bash
git log <last-tag>..HEAD --oneline
git diff <last-tag>..HEAD --stat
```

When needed, inspect key files with `git diff <last-tag>..HEAD -- <path>`.

**Judge the version level from the actual content and impact of the diff** (do not rely on commit message conventions):

| Level | Criteria |
|-------|----------|
| major (x.0.0) | Breaking changes: public API signature/behavior changes, removal of user-facing features or routes, incompatible data structure migrations, incompatibility caused by major dependency upgrades |
| minor (x.y.0) | New capability: new pages/features/endpoints/config options that are backward compatible for existing consumers |
| patch (x.y.z) | Fixes and maintenance: bug fixes, minor style tweaks, copy changes, refactors, minor dependency bumps, build/CI changes |

Take the highest level among all changes. If torn between major and minor, explain the reasoning to the user (in Chinese) and let them decide.

### Step 4: Generate the changelog

Based on the diff analysis (not a verbatim copy of commit messages), summarize user-facing entries grouped by type. The changelog content is written in Chinese. Prepend it to `CHANGELOG.md` at the repository root (preserve existing history; if the file does not exist, create it with the title `# Changelog`):

```markdown
## v1.5.0 - 2026-07-08

### 新增
- 面向使用者描述的功能点

### 修复
- 修复的问题

### 变更
- 行为或结构上的调整（破坏性变更需标注 **BREAKING**）
```

Omit empty groups. Entries should describe the effect of the change, not implementation details.

### Step 5: User confirmation

Show the user (in Chinese): target branch, previous version → new version, and the full changelog content. Use AskQuestion with these options:

1. 确认发布 (Recommended)
2. 调整版本号
3. 修改 changelog
4. 取消

For options 2/3, apply the user's feedback and ask for confirmation again. For option 4, revert the CHANGELOG.md changes and stop.

### Step 6: Commit, tag, and push

After confirmation, run in order:

```bash
git add CHANGELOG.md
git commit -m "chore(release): v<version>"
git tag -a v<version> -m "Release v<version>"
git push origin <branch> --follow-tags
```

After a successful push, report to the user (in Chinese): the new tag name, the commit it points to, and the remote branch pushed to. If any step fails, stop immediately, report the error, and never retry with force push.

## Notes

- Never use `--force` and never amend commits that have been pushed.
- If the repository has a `package.json` whose `version` field is conventionally kept in sync with tags (check past release commits), update that field as well before committing in Step 6.
