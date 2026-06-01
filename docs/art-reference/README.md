# 美术参考库

> 本目录用于收集**视觉风格对标作品**，作为未来正式美术资源制作（自做 / 外包 / AI 生图）的方向指引。
>
> 当前项目用占位贴图（PIL 程序化生成），等系统骨架做到 5-8 个关卡后进入"美术 sprint" 时，会基于这里的参考统一替换。

---

## 项目美学定位（来自 spec §6）

> **"赛博中式都市怪诞"**（道城风 / Daocheng Aesthetics）

**公式**：现代都市废墟 [底] + 中式神秘符号 [点缀] + 规则怪谈视觉范式 [内核] + 克苏鲁式超现实 [氛围]

---

## 一级对标作品（最关键的视觉灵感来源）

### 1. 《极乐迪斯科》Disco Elysium
- **借鉴维度**：2.5D 等距视角排版、文字密度、UI 框架、人物对话表现、油画质感
- **特别注意**：他们的对话框是**最高级别参考**——暗色调 + 半透明 + 微妙的环境响应
- 截图建议保存到：`docs/art-reference/disco-elysium/`
- 关键画面：思维内阁、技能检定、人物正脸特写
- Steam / B 站搜 "disco elysium screenshots"

### 2. 《纸嫁衣 1-4》系列
- **借鉴维度**：中式恐怖氛围、红色高光、符纸/灯笼/纸人元素
- **不直接借鉴**：他们偏古风民俗，我们要现代都市感
- **借鉴**：UI 文字排版、关键道具特写、惊悚瞬间的红化处理
- 截图保存到：`docs/art-reference/paper-bride/`

### 3. 《港诡实录》Paranormal HK
- **借鉴维度**：**现代都市恐怖**最直接的参考！霓虹+水泥+中式神秘的混合
- 关键画面：第一/第三人称视角下的现代香港街景 + 灵异元素
- 截图保存到：`docs/art-reference/paranormal-hk/`

### 4. 《阴阳锅》（独立 RPG）
- **借鉴维度**：现代家居场景 + 中式神秘事件
- 截图保存到：`docs/art-reference/yinyangguo/`

---

## 二级对标作品（局部参考）

### 5. 《暗黑地牢》Darkest Dungeon
- **借鉴维度**：手绘风格的精致 9-slice UI 框架、技能图标、状态栏
- **不借鉴**：他们偏哥特西式

### 6. 《Pentiment》
- **借鉴维度**：中世纪手抄本风格的文字+插图布局、章节卷首
- 我们可以借鉴：每个章节开始时一段"卷首旁白"的视觉处理

### 7. 《十三机兵防卫圈》
- **借鉴维度**：碎片化叙事 + 拼图式时间线 UI
- **不借鉴**：他们的青春科幻画风

### 8. 《Outer Wilds》
- **借鉴维度**：探索 + 知识积累的 UI 表现（"飞船日志"）
- 我们的"规则面板 / 笔记本"可以借鉴

---

## 视觉元素具体清单

### 必须有的视觉符号（spec §6 已定义）
- ✅ 十二生肖石雕（带血污）
- ✅ 生肖面具（人羊已用占位）
- ✅ 红灯笼（灰烬中、残破）
- ✅ 残破符纸
- ✅ 道（眼球状）/ 玉（牙齿）/ 涡（耳蜗）/ 勾（鼻）/ 索（眉毛）—— 五城筹码
- ✅ 血红天空 + 巨大眼球太阳
- ✅ 悬浮的"门"（空间列车）
- ✅ 戴动物面具的"生肖"（不是动物身体，是人戴面具）

### 调色板（spec §6.2，完整版见 art-guidelines.md）
- 底色：暗灰 `#1a1a1a` / 墨黑 `#0a0a0a` / 铁锈红 `#6b2828`
- 高亮：血红 `#b71c1c` / 霓虹残光（青/紫/暖黄）
- 强调：暗金（雕像）/ 冷青（回响光效）
- 警告：鲜黄 `#ffd93d` / 朱红（重要 NPC）

---

## 如何使用本目录

1. **看到对标作品的好画面 → 截图 / 保存图片 → 放进 `docs/art-reference/<作品名>/`**
2. **每张图旁边可以加一个 `.md` 文件描述"借鉴什么"**
3. **未来美术 sprint 启动时**：把这些图给美术伙伴 / 用作 AI 生图的 reference image

---

## AI 生图 prompts 参考

如果选择用 Midjourney / Stable Diffusion 生美术资源，下面是初步 prompt 方向：

### NPC 头像 prompt 模板
```
isometric 2.5D character portrait, modern Chinese man/woman in dark hoodie/business attire,
dark eyes hidden in shadow, dim oil painting style, dark red and rust palette,
Disco Elysium art style mixed with Chinese horror, half-face lit by red neon,
no smile, somber expression, painterly brushstrokes, --ar 1:1
```

### 道城场景 prompt 模板
```
isometric view of ruined modern Chinese city street, broken neon signs in Chinese characters,
concrete crumbling walls, blood-red sky, giant eyeball as sun in distance,
abandoned air conditioners, rusted lanterns hanging crooked, fog,
Disco Elysium meets Bloodborne meets cyberpunk Chinatown,
dark muted palette with selective rust-red highlights, painterly, --ar 16:9
```

### 生肖面具特写 prompt 模板
```
close-up of a man wearing a porcelain white goat mask, single horn,
black void where eyes should be, blood streaks on cheek of mask,
modern dark suit, dim cinematic lighting from below,
oil painting style, Disco Elysium x Chinese folk horror, --ar 1:1
```

---

## 风格"禁区"

为了保持统一，**避免**以下风格元素：

- ❌ 古风（汉服、宫廷、武侠刀剑）—— 我们是现代都市
- ❌ 萌系 / 二次元 美少女 —— 风格不符
- ❌ 写实 3A 渲染（PBR） —— 工作量爆炸
- ❌ 像素艺术（除非用于特定场景，需统一决定）
- ❌ 卡通明亮色调 —— 与"规则怪谈"题材冲突
- ❌ 纯西式中世纪 / 哥特 —— 文化不符

---

## 更新历史
- 2026-06-01：初版，对标作品列表 + AI prompt 模板
- TBD：用户自行添加截图后 update 各子目录的 README
