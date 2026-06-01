# 美术规范文档

> 项目的视觉规范，定义**所有美术资源**应遵循的技术标准与风格统一约束。
>
> 适用对象：未来的美术伙伴 / 外包供应商 / AI 生图工作流 / 自做美术的人。
>
> 项目美学定位：**"赛博中式都市怪诞"**（道城风）。详见 [art-reference/README.md](art-reference/README.md)。

---

## 1. 完整调色板

### 主色板（spec §6.2 锚定）

| 用途 | 色相 | HEX | 备注 |
|---|---|---|---|
| 底色 主要 | 暗灰 | `#1a1a1a` | 大部分 UI 底 |
| 底色 极深 | 墨黑 | `#0a0a0a` | 阴影、强烈对比 |
| 底色 暖 | 铁锈红 | `#6b2828` | 描边、点缀 |
| 高亮 主要 | 血红 | `#b71c1c` | 重要强调、警告、说话人名 |
| 高亮 暖光 | 霓虹暖黄 | `#ffd93d` | 提示、可交互高亮 |
| 强调 神秘 | 冷青 | `#5fcdcd` | 回响光效 |
| 强调 雕像 | 暗金 | `#a08020` | 生肖石雕 |
| 文字 主要 | 米白 | `#f0ede5` | 对话文字默认色 |
| 文字 次要 | 暗灰 | `#888888` | 旁白/叙述 |
| 成功 | 暗绿 | `#5fcd5f` | "胜利" / "已存档" |

### 不可用色板（避免冲突）

- ❌ 纯白 `#ffffff`（太刺眼，违和）
- ❌ 鲜艳饱和（任何 saturation > 90% 的纯色）
- ❌ 粉红 / 浅蓝（与氛围冲突）

---

## 2. 分辨率与尺寸规范

### Sprite（人物 / NPC / 物件）

| 类型 | 尺寸（像素） | 备注 |
|---|---|---|
| 玩家 | 32 × 48 | 站立 |
| NPC 普通 | 32 × 48 | 同玩家 |
| NPC 大型（如人羊主理人） | 40 × 60 | scale 1.25× |
| 建筑物 小 | 48 × 80 | 占位小屋 |
| 建筑物 中 | 96 × 128 | 二层建筑 |
| 道具 / 拾取物 | 16 × 16 | 标准像素艺术 |
| 桌椅 / 家具 | 64 × 64 ~ 128 × 96 | 等距 |

### 等距瓦片

- 标准 **2:1 等距**（64 × 32）
- 标准菱形顶点：(32, 0), (64, 16), (32, 32), (0, 16)
- 透明背景 PNG with alpha

### UI

| 类型 | 尺寸 | 备注 |
|---|---|---|
| 9-slice 面板 | 96 × 96 | 任意拉伸 |
| 按钮 normal/hover/pressed | 64 × 32 | 3 个状态 |
| 头像 | 96 × 96 | 对话时 |
| 图标 | 32 × 32 / 16 × 16 | UI 元素 |
| Logo | 256 × 256 | 主菜单 |

### 屏幕分辨率
- 基准：**1920 × 1080**（spec §7）
- Stretch mode: `viewport`, Aspect: `expand`, Scale: `fractional`

### Texture import 设置（Godot 4 默认覆盖）

所有像素艺术 / 风格化贴图：
- **Filter**: `Nearest`（已在 project.godot 全局设）
- **Mipmaps**: `Off`
- **Compress mode**: `Lossless`

---

## 3. 9-slice 规范

所有可缩放的 UI 面板必须做成 **9-slice texture**：

```
┌─corner─┬───edge───┬─corner─┐
│   16   │   any    │   16   │
├────────┼──────────┼────────┤
│  edge  │  center  │  edge  │
│  (16)  │   (any)  │  (16)  │
├────────┼──────────┼────────┤
│   16   │   any    │   16   │
└─corner─┴───edge───┴─corner─┘
```

- **基础尺寸**：96 × 96
- **margin**：四边各 16 像素
- **center**：可平铺或拉伸
- **corner**：固定，包含中式角花装饰

当前占位资源（位于 `src/assets/ui/`）：
- ✅ `dialogue_panel_9slice.png` - 暗色+暗红描边+中式角花
- ✅ `button_normal.png` / `_hover.png` / `_pressed.png` - 64×32 三态按钮
- ✅ `speaker_tag.png` - 96×36 印章风格

---

## 4. 文件与命名规范

### 目录结构

```
src/assets/
├── characters/         # NPC / 玩家 sprite + 头像
│   ├── player.png             # 玩家正式
│   ├── player_walk_01.png     # 帧动画用
│   └── npc/
│       ├── chen_junnan.png
│       └── chen_junnan_portrait_96.png   # 对话头像
├── tiles/              # 地图瓦片
│   ├── iso_tiles.tres         # 正式 TileSet
│   └── iso_tiles_atlas.png
├── ui/                 # 界面元素
│   ├── dialogue_panel.png
│   ├── button_*.png
│   └── icons/
└── effects/            # 粒子、特效
```

### 命名约定

| 类型 | 命名模式 | 例子 |
|---|---|---|
| 占位资源 | `<name>_placeholder.<ext>` | `player_placeholder.png` |
| 正式资源 | `<name>.<ext>` | `player.png` |
| 角色帧 | `<name>_<action>_<NN>.png` | `chen_junnan_walk_01.png` |
| UI 三态 | `<name>_<state>.png` | `button_hover.png` |
| 9-slice | `<name>_9slice.png` | `dialogue_panel_9slice.png` |
| 头像 | `<name>_portrait_<size>.png` | `chen_junnan_portrait_96.png` |

**约定**：
- 所有名字 **snake_case**
- **小写**，不用空格、不用中文
- 数字补零（`01` 不是 `1`），方便排序

---

## 5. 占位 → 正式 替换流程

**约定**：所有"占位"资源文件名后缀 `_placeholder`。

替换流程（**未来美术 sprint 时使用**）：

1. **新美术存到旧路径但去掉 `_placeholder`**：
   - `iso_tiles_placeholder.png` → `iso_tiles.png`
2. **更新引用**：
   - `.tres` 资源里的 `path = "...iso_tiles.png"`
   - `.tscn` 场景里的 `ExtResource` path
3. **跑 Godot reimport**
4. **跑测试** 确保 38+ 个 unit tests 仍通过
5. **不删占位**：保留在 git history（万一新美术有问题）
6. **commit 信息**：`art: replace <name>_placeholder with final art`

**已标记的占位资源清单**（截至 P4 完成）：

```
src/assets/characters/
  ├── player_placeholder.png         # 32×48 小黄人
  ├── building_placeholder.png       # 48×80 小屋
  ├── table_placeholder.png          # 128×96 圆桌
  └── submit_marker.png              # 24×24 黄球（无 _placeholder 后缀但也是占位）

src/assets/tiles/
  ├── iso_tiles_placeholder.png      # 256×32, 4 色等距菱形
  └── iso_tileset_placeholder.tres   # TileSet

src/assets/ui/
  ├── dialogue_panel_9slice.png      # 96×96
  ├── speaker_tag.png                # 96×36
  └── button_{normal,hover,pressed}.png  # 64×32
```

---

## 6. 风格统一约束

### 必须遵守

- ✅ 整体偏暗（绝大多数像素 luminance < 50%）
- ✅ 暗红是唯一的"温暖"色（除特定 NPC 的特征色）
- ✅ 文字加 1px 黑色描边（spec §5.7 已用 outline_size = 1）
- ✅ 像素艺术风格 → 用 Nearest filter（不模糊）
- ✅ 透明 PNG（不要白底）

### 风格禁区

- ❌ 古装、宫廷、武侠（spec 已明确：现代都市）
- ❌ 二次元萌系
- ❌ 3D 写实 PBR
- ❌ 高饱和度（除关键警告用的血红/鲜黄）
- ❌ 卡通明亮色调

---

## 7. 三种获取美术的成本对比

| 方式 | 单资源成本 | 周期 | 质量 | 适合什么 |
|---|---|---|---|---|
| **AI 生图**（Midjourney / SD）| ~ $0.5 / 张 | 即时 | ★★★ | 大量背景、占位升级 |
| **AI 生图 + 人工后修** | $5-30 / 张 | 1-3 天 | ★★★★ | 关键 NPC、UI 框架 |
| **像素美术外包** | ¥500-2000 / 角色 | 1-2 周 | ★★★★ | 帧动画、关键角色 |
| **中式立绘外包** | ¥1000-5000 / 张 | 2-4 周 | ★★★★★ | 关键 CG、Logo |
| **自学 Aseprite** | 时间 ~ 100 小时 | 持续 | ★★ → ★★★★ | 长期项目最划算 |

**建议路径**（spec 是同人项目，预算紧）：
1. 系统骨架期（现在 - 8 个关卡完成）：**全部占位**，0 成本
2. 美术 sprint：**AI 生图为主**（成本极低）+ 人工后修关键资源
3. 如果项目反响好（同人圈传播）：再考虑外包关键 CG

---

## 8. AI 生图工作流（推荐）

如果选 AI 生图方案：

### 工具
- **Midjourney** v6.1+：质量最好，月费 $10-30
- **Stable Diffusion**（本地或 ComfyUI）：免费，可控性强
- **DALL-E 3**：通过 ChatGPT Plus，约 $20/月
- **FLUX.1-dev**：开源，可商业（注意 license）

### 流程
1. **从 art-reference/ 选 reference image** 作为风格锚定
2. **用 [art-reference/README.md §AI 生图 prompts 参考] 中的模板**
3. **生成 4-8 张**，选最对的 1 张
4. **下载** → 保存到 `src/assets/<category>/<name>.png`
5. **去除背景**（用 `rembg` 或在线工具）
6. **裁切到规范尺寸**（见 §2）
7. **Godot reimport** → 测试

### 关键 prompt 词汇（强化"赛博中式都市怪诞"风）
- `disco elysium art style`
- `chinese urban horror`
- `ruined neon hutong`
- `cyberpunk chinatown`
- `dim oil painting`
- `blood-red highlights only`
- `dark muted palette`
- `painterly brushstrokes`
- `no text, no logo`

### 避免词
- `cute`, `kawaii`, `anime`, `bright`, `cheerful`, `colorful`
- `ancient china`, `dynasty`, `kungfu`, `martial arts`

---

## 9. 当前项目美术状态（截至 P4）

| 类别 | 占位 | 正式 | 备注 |
|---|---|---|---|
| 玩家 sprite | ✅ | ❌ | 32×48 黄色小人 |
| NPC sprite | ✅（玩家贴图+modulate）| ❌ | 5 个 NPC 共用 + 染色 |
| 主理人（人羊）| ✅（同 NPC + 灰白色）| ❌ | scale 1.25 + 占位 |
| 建筑物 | ✅ | ❌ | 48×80 小屋 |
| 桌子 | ✅ | ❌ | 128×96 圆桌 |
| 提交标记 | ✅ | ❌ | 24×24 黄球 |
| 等距瓦片 | ✅ | ❌ | 256×32, 4 色 |
| 对话框 9-slice | ✅ | ❌ | 96×96 道城风 |
| 按钮 3 态 | ✅ | ❌ | 64×32 |
| 说话人标签 | ✅ | ❌ | 96×36 印章 |
| 头像（NPC portrait）| ❌ | ❌ | **未做，将来对话沉浸感关键** |
| 主菜单 / Logo | ❌ | ❌ | **未做** |
| 粒子特效 | ❌ | ❌ | **未做** |
| CG / 关键插画 | ❌ | ❌ | **未做** |

**总结**：所有占位都用 Python PIL 程序化生成，**没有任何"真美术"投入**。这是有意的（spec.md §B 战略：系统骨架优先）。

---

## 10. 何时启动"美术 sprint"

判断标准（满足 3 项即可启动）：

- [ ] 5+ 个生肖关卡完成（说谎者 / 雨后春笋 / 黑白棋 / 仓库寻道 / 黑熊狩猎）
- [ ] 道城主场景骨架完成
- [ ] 对话系统经过实战验证（无大改动）
- [ ] 存档/读档稳定（无 bug）
- [ ] 玩家做完一个完整 cycle 的 playtest

**当前进度**：1/5 关卡（说谎者 MVS），其他都还没做。距离美术 sprint 还有 4-8 周（视开发节奏）。

---

## 更新历史

- 2026-06-01：初版（基于 spec §6 + P1-P4 占位资源现状）
