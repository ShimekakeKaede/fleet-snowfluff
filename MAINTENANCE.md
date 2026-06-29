# Fleet Snowfluff — 维护与开发

面向二次开发者与本仓库维护者。用户向说明见 [README.md](README.md)。

---

## 目录

1. [安装脚本](#1-安装脚本)
2. [主题（`themes/`）](#2-主题themes)
3. [Vibrancy 叠加层（`vibrancy/`）](#3-vibrancy-叠加层vibrancy)
4. [资源（`assets/`）](#4-资源assets)
5. [部署路径与生效方式](#5-部署路径与生效方式)
6. [故障排除](#6-故障排除)

---

## 1. 安装脚本

入口：`scripts/setup.ps1`（调用 `setup-vibrancy.ps1`）。

### 自动完成的步骤

| 步骤 | 说明 |
|------|------|
| 安装主题扩展 | 将仓库 **目录联接（junction）** 到 `%USERPROFILE%\.cursor\extensions\fleet-snowfluff.fleet-snowfluff-<version>` |
| 部署叠加层 | 复制 / 生成文件到 `%APPDATA%\Cursor\User\fleet-snowfluff\` |
| 合并 `settings.json` | `workbench.colorTheme`、`vscode_vibrancy.*`、`imports`、透明度等 |
| Patch Vibrancy | 使 `imports` 中的 JS 在 Cursor CSP 下可内联执行 |

### 参数

```powershell
.\scripts\setup.ps1 -CopyExtension   # 复制文件而非联接（仓库可移动或删除）
.\scripts\setup.ps1 -VsCodeToo         # 同时安装到 VS Code
```

### 修改后如何生效

| 改了什么 | 操作 |
|----------|------|
| `themes/*.json` | Reload Window（junction 指向仓库，即时读取） |
| `vibrancy/`、`assets/`、`scripts/` | `setup.ps1` → Vibrancy Reload → 冷启动 |
| Cursor / Vibrancy Continued 升级 | 重跑 `setup.ps1` → Reload → 冷启动 |

**不要**手改 `%APPDATA%\Cursor\User\fleet-snowfluff\` 下含 base64 的生成文件；始终改仓库源文件后重跑 setup。

---

## 2. 主题（`themes/`）

| 文件 | 说明 |
|------|------|
| `fleet-snowfluff-dark.color-theme.json` | 主主题：`colors`、全局 `tokenColors`、`semanticTokenColors`、Terminal ANSI |
| `fleet-python-import.tmLanguage.json` | Python `from … import (` 括号内 import 列表语法注入 |

### 色板（全语言）

| 角色 | 色值 |
|------|------|
| 关键字 | `#4A9EFF` |
| 函数 / 方法 | `#FF8FAB` |
| 字符串 | `#FF7A45` |
| 转义 | `#C85874` |
| 类型 / 类 | `#B090F0` |
| 变量 / 参数 | `#B0C4E0` |
| 注释 | `#6B7A8C` |
| 数字 / 常量 | `#F6C343` |

### Python 着色策略

- **TextMate**（`.python` 作用域）+ **Pylance 语义**（`:python`）双层
- **刻意不设** `string:python` 语义色，保留转义字符的 TextMate 着色
- 需安装 [Pylance](https://marketplace.visualstudio.com/items?itemName=ms-python.vscode-pylance)

### 其他语言

HTML、CSS/SCSS、JS/TS、JSON/YAML/TOML、Markdown、Shell、Go、Rust、Java、C# 等 — 见 `fleet-snowfluff-dark.color-theme.json` 中全局 `tokenColors` 与按语言的 `semanticTokenColors`。

### Terminal

`terminal.*` / `terminalCursor.*` ANSI 色与编辑器色板对齐；仅对带 **ANSI 转义**的输出着色。

---

## 3. Vibrancy 叠加层（`vibrancy/`）

依赖 [Vibrancy Continued](https://marketplace.visualstudio.com/items?itemName=illixion.vscode-vibrancy-continued)。由 setup 部署到用户目录并通过 `vscode_vibrancy.imports` 注入。

### 目录与部署映射

```
vibrancy/
├── css/opaque-chrome.css              → vibrancy-opaque-chrome.css
├── js/
│   ├── activity-global-menu.js        → fleet-activity-global-menu.js
│   ├── editor-line-numbers.js         → fleet-editor-line-numbers.js
│   └── editor-atmosphere.template.js  → fleet-editor-atmosphere.js（生成，嵌入 assets）
└── templates/
    ├── titlebar-mascot.css            → fleet-titlebar-mascot.css（生成）
    └── home-watermark.css             → fleet-home-watermark.css（生成）
```

### 模块说明

| 源文件 | 功能 |
|--------|------|
| `css/opaque-chrome.css` | 不透明 chrome、滚动条、樱靛缩进线、选区渐变、Panel 页签、诊断故障线、光标 / 飘落样式 |
| `js/activity-global-menu.js` | Activity Bar Account / Settings 菜单打开态标记 |
| `js/editor-line-numbers.js` | 光标行 / 选区 / 多光标行号渐变 |
| `js/editor-atmosphere.template.js` | GIF 光标（Monaco + 原生 input）、打字飘落粒子 |
| `templates/titlebar-mascot.css` | Title bar / 断点 glyph mascot |
| `templates/home-watermark.css` | 欢迎页水印（替换默认 codicon） |

### 编辑器氛围（`editor-atmosphere.template.js`）

- **Monaco 光标** — 在 `.cursors-layer` 旁挂 `.fleet-cursor-sprite`；按编辑器维护 sprite 池，Monaco 重建 DOM 时沿用上一帧布局，避免打字时闪烁消失
- **原生输入**（Search 等） — `#fleet-native-cursor-host` + canvas 测 caret
- **飘落物** — `assets/dropings/` 内图片按文件名排序嵌入；显示尺寸按原图最长边归一化（约 12–22px）

### Vibrancy Patch

`scripts/patches/` 下的片段会替换 Vibrancy Continued 运行时中的 `injectHTML`，使 JS import 在 `executeJavaScript` 内联执行。扩展升级后若叠加 JS 失效，重跑 `setup.ps1`。

---

## 4. 资源（`assets/`）

仓库默认携带完整资源；setup 读取并嵌入（或生成）到用户目录。

### `aemeath/` — 角色动图

| 文件 | 用途 |
|------|------|
| `Aemeath_FORWARD.gif` | 编辑器 GIF 光标 → `fleet-editor-atmosphere.js` |
| `Aemeath_GLASS_inline.gif` | Title bar mascot / 断点图标 → `fleet-titlebar-mascot.css` |
| `Aemeath_JUMP.gif` | 欢迎页 Home 水印 → `fleet-home-watermark.css` |

删除任一文件后重跑 setup，对应效果不再加载。

### `dropings/` — 打字飘落图标

放置 `png` / `gif` / `webp`；setup **全部嵌入**并按字母序随机选用。

默认：`icon0.png`、`icon1.png`、`icon2.png`、`icon3.png`。

**增删资源：**

```powershell
# 增删文件后
.\scripts\setup.ps1
# → Vibrancy: Reload → 冷启动
```

### 缩小 mascot GIF

从更大源图重新生成 `Aemeath_GLASS_inline.gif`：

```powershell
python scripts/optimize-titlebar-gif.py --input <源图.gif> --output assets/aemeath/Aemeath_GLASS_inline.gif
```

需要 Pillow：`pip install pillow`。脚本使用整数倍 nearest-neighbor 缩放，适合像素风 GIF。

---

## 5. 部署路径与生效方式

| 类型 | 仓库路径 | 部署 / 加载位置 |
|------|----------|-----------------|
| 主题扩展 | 仓库根（junction） | `%USERPROFILE%\.cursor\extensions\fleet-snowfluff.*` |
| 叠加层 | `vibrancy/` + 生成物 | `%APPDATA%\Cursor\User\fleet-snowfluff\` |
| 用户配置 | — | `%APPDATA%\Cursor\User\settings.json`（setup 合并写入） |

`.vscodeignore` 排除 `vibrancy/`、`assets/`、`scripts/`，扩展市场包仅含 `themes/`；本项目的完整体验依赖 **clone + setup** 流程。

---

## 6. 故障排除

| 现象 | 处理 |
|------|------|
| 主题列表没有 Fleet Snowfluff | 重跑 `setup.ps1`，完全重启 Cursor |
| Vibrancy 无效果 | **Vibrancy: Enable** → Reload → 冷启动 |
| 无 GIF 光标 | 确认 `assets/aemeath/Aemeath_FORWARD.gif` 存在后重跑 setup |
| 飘落物 / mascot / 水印缺失 | 确认对应 `assets/` 文件存在后重跑 setup |
| 改了 `vibrancy/` 或 `assets/` 未生效 | setup → Vibrancy Reload → 冷启动（非仅 Reload Window） |
| 叠加 JS 不执行 | Vibrancy Continued 升级后重跑 setup（重新 patch） |
| IDE 升级后异常 | 重跑 `setup.ps1` → Reload → 冷启动 |

### 控制台验证

在 Developer Tools Console 中：

```javascript
document.documentElement.dataset.fleetActMenu
document.documentElement.classList.contains('fleet-atmosphere-cursor')
typeof fleetLnDiag === 'function' && fleetLnDiag()
```
