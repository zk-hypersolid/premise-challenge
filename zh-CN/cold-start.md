# 冷启动：先出一版不受锚定的方案，再对撞

需要独立视角时用：你可能已经被读过的文档锚定，或者要整体重新设计。读过的内容没法假装没读，所以独立的那一版必须来自一个从没见过现有决策的上下文。

1. 用本技能目录下的 `scripts/make-clean-room.sh` 建一份干净副本（例如 `~/.claude/skills/premise-challenge/scripts/make-clean-room.sh <repo> <仓库外的输出目录> <ref>`）。它导出指定的 ref，删掉 agent 指令文件（CLAUDE.md、AGENTS.md、GEMINI.md，以及 Copilot、Cursor、Windsurf、Cline 的规则文件）、`.claude/`、`.codex/`、`.cursor/`、`.windsurf/` 目录，任意层级的 `docs`、ADR、RFC 和决策记录目录，以及仓库根目录下的 `doc` 和 `design` 目录，再检查清单里的名字是否都删干净了。如果你的仓库把决策放在别处，把这些相对路径作为额外参数传进去，并自己再看一遍目录。
2. 按探索型任务写 brief，存到仓库外的一个文件里：只放目标、成功标准、外部约束和已核实的事实，并写明输出路径；不放现有决策、规格原文和现有设计；也不要用"挑战""替代方案"这类词，被要求反对的 agent 会为了反对而反对。
3. 把 brief 和干净副本交给本技能 `agents/` 目录里的 `cold-designer` subagent。它必须先装到 `~/.claude/agents/`（见 README），它被设置为不加载 CLAUDE.md 文件。如果没装，告诉用户，不要改用通用 subagent，通用 subagent 通常会继承你的指令文件。
4. 对撞：列出冷启动方案和现有设计的分歧。每条写对应的决策、当初的理由、这个理由是否还成立（附证据）。要推翻的，按 SKILL.md 的推翻提案格式交给决策负责人。
