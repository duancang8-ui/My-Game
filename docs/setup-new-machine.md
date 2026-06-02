# 新电脑搭建指南

> 你换电脑、丢了硬盘、或者想多机同步开发时看这一份。
>
> 目标：从零到「能跑测试 + 能 F5 启动 + 能和 AI 继续开发」< 15 分钟。

---

## 0. 你需要带过去的 3 样东西

```text
✅ Git 仓库
   https://github.com/duancang8-ui/My-Game.git
   （24+ tag + 全部代码 / 文档 / 测试，git clone 一键到位）

⚠️ 原作 txt（gitignore 排除，git 不带）
   ~/Desktop/MyGame/docs/source/shiri_zhongyan.txt
   通过 AirDrop / iCloud Drive / U盘 / 网盘私链传过去

🟢 （可选）存档
   macOS: ~/Library/Application Support/Godot/app_userdata/MyGame/
   不带没影响 —— 重新玩体验更完整
```

---

## 1. 装 Godot（5 分钟）

```text
版本：Godot 4.6.3 stable（必须！项目锁定这个版本）
下载：https://godotengine.org/download/macos
       选 "Standard build"（不要 Mono / .NET 版）
解压后把 Godot.app 拖进 /Applications/ 或 ~/Downloads/
```

可选：建一个 shell 别名方便命令行用
```bash
echo 'alias godot="/Applications/Godot.app/Contents/MacOS/Godot"' >> ~/.zshrc
source ~/.zshrc
```

---

## 2. 克隆项目（30 秒）

```bash
cd ~/Desktop
git clone https://github.com/duancang8-ui/My-Game.git MyGame
cd MyGame

# 验证：应该 70+ commit，18+ tag
git log --oneline | wc -l
git tag | wc -l
```

---

## 3. 放回 git 没带的东西（1 分钟）

```bash
# 把你单独传过来的原作 txt 放回
mkdir -p docs/source
mv ~/Downloads/shiri_zhongyan.txt docs/source/
# 验证：约 9MB
ls -lh docs/source/shiri_zhongyan.txt

# 可选：恢复存档
mkdir -p "$HOME/Library/Application Support/Godot/app_userdata"
mv ~/Downloads/MyGame-godot-userdata "$HOME/Library/Application Support/Godot/app_userdata/MyGame"
```

---

## 4. 首次 Godot 打开（30 秒到 5 分钟）

```text
打开 Godot.app → "Import" → 选 ~/Desktop/MyGame/project.godot → Import & Edit

⏰ 首次会自动重建 .godot/ 缓存：
   - SSD 电脑：10-30 秒
   - HDD 电脑：1-5 分钟
   - 中途看起来卡住是正常的，等

可能出现的 warning（无需理会）：
   - "GDScript::reload: ... declared but never explicitly used"
   - "Could not read .uid file" → 重启 Godot 即可
```

---

## 5. 验证一切正常（3 分钟）

```text
A. GUT 跑测试
   底部 GUT 面板 → Run All
   预期：150+ case 全过

B. F5 启动游戏
   应该看到主菜单 "十 日 终 焉" + 4 个按钮
   点"新游戏" → 进入面试房间 → 看到第一个教学提示 Toast

C. 主要快捷键试一遍
   WASD / E / N（笔记本）/ F9 存档 / F10 读档
```

---

## 6. 和 AI 继续开发（最关键）

```text
打开 Cursor/Claude/任何 AI 助手 → 让它读这 3 份文档：

  1. AGENTS.md                          ← 项目入门手册（10 min 读完）
  2. docs/status-overview.md            ← 当前状态仪表盘
  3. docs/handoff-2026-06-02.md         ← 最近一次 hand-off

读完 ta 就能立刻接上你的开发。
无需依赖 Cursor 的 transcript 历史。
```

如果你用 Cursor，**第一句对话发**：
```
请先读 AGENTS.md 和 docs/status-overview.md。
然后告诉我你现在了解到的项目状态。
```

ta 会用 30 秒报一遍他理解的"项目身份 / 4 关 / 道具 / 下一步推荐"。
你检查一遍 → 对得上就可以开干。

---

## 7. 你新电脑上的第一次 push（如果改了代码）

```bash
cd ~/Desktop/MyGame
# 改代码 → commit → push
git add -A
git commit -m "feat(xxx): yyy"
git push

# tag 新里程碑：
git tag v0.13-something -m "描述"
git push origin v0.13-something
```

---

## 8. 故障排查

### "Godot 打不开项目 / 报 uid 找不到"

```text
关 Godot → 删掉 ~/Desktop/MyGame/.godot/（不要删 .git/！）→ 重开 Godot
让 ta 完整重建一次缓存
```

### "测试报 'Script not found' / Compilation failed"

```text
通常是首次打开时 import 没完成。
关 Godot → 重开一次 → 等"导入资源"进度条结束
```

### "git pull 报 'merge conflicts'"

```text
你在两台电脑同时改了同一行 → 用 Cursor 让 AI 帮你 resolve
或者最简单：git pull --rebase origin main
```

### "AI 不知道我们之前的讨论"

```text
正常！transcript 不跟项目走。
让 AI 读 AGENTS.md + status-overview.md + handoff-2026-06-02.md。
读完它就"全懂了"。
```

---

## 9. 日常多机同步

```bash
# 每天开工前：
cd ~/Desktop/MyGame && git pull --rebase

# 每天收工前（确保所有改动都到 GitHub）：
git add -A && git commit -m "wip: 今天做的事" && git push
```

GitHub 仓库永远是"真相之源"。
本地工作树是"临时草稿"。

---

## 备忘：你需要的账号 / 密钥

```
- GitHub 账号  duancang8-ui
- GitHub PAT（Personal Access Token）
    位置：GitHub Settings → Developer settings → PATs (classic)
    Scope：只勾 [✓ repo]
    第一次 push 时输入到密码框，macOS Keychain 会记住
- （可选）SSH key
    生成：ssh-keygen -t ed25519
    上传公钥：~/.ssh/id_ed25519.pub 内容贴到 GitHub Settings → SSH and GPG keys
    然后 remote 改 SSH：
      git remote set-url origin git@github.com:duancang8-ui/My-Game.git
```

---

*这一份是给"未来的你"看的。读完就动手。*
