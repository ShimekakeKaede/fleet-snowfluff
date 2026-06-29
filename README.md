# Fleet Snowfluff

《鸣潮》**飞行雪绒**配色主题，适用于 [Cursor](https://cursor.com) 与 [Visual Studio Code](https://code.visualstudio.com)。

- **主题本体**：Python 定制语法/语义着色 + 暗色 UI（`Fleet Snowfluff Dark`）
- **可选叠加**：Vibrancy 毛玻璃、GIF 光标、打字飘落、行号渐变、Title bar mascot 等

编辑区与 Terminal、Agent 等 content 区默认约 **70% 不透明**（`#000000B3`）；侧栏 / 标题栏等 chrome 为 `#111111`。

**代码着色目标语言：** Python（其他语言保持白板 `#E8E8E8`，便于后续扩展）。

---

## 目录

1. [快速开始](#1-快速开始)
2. [特性概览](#2-特性概览)
3. [项目结构](#3-项目结构)
4. [Python 代码着色](#4-python-代码着色)
5. [Vibrancy 叠加（可选）](#5-vibrancy-叠加可选)
6. [资源与部署产物](#6-资源与部署产物)
7. [自定义与故障排除](#7-自定义与故障排除)
8. [许可](#8-许可)

---

## 1. 快速开始

### 仅主题

1. 用 Cursor / VS Code 打开本仓库，**F5** 启动扩展开发宿主；或 `vsce package` 后 **Install from VSIX**
2. **Preferences: Color Theme** → **Fleet Snowfluff Dark**
3. Python 文件需 **Pylance** + 语义高亮（主题默认已开启）

### 主题 + Vibrancy 完整体验

1. 安装 [Vibrancy Continued](https://marketplace.visualstudio.com/items?itemName=illixion.vscode-vibrancy-continued)
2. 将 GIF / 飘落 icon 放入 [`assets/`](assets/README.md)（见资源说明）
3. 仓库根目录执行：`.\scripts\setup-vibrancy.ps1`
4. **Vibrancy: Enable**（首次）→ **完全重启** Cursor

推荐 `settings.json`：`workbench.activityBar.orientation: vertical`

---

## 2. 特性概览

| 功能 | 说明 |
|------|------|
| 主题配色 | 粉绒、靛青与星炬金辉；缩进线樱→靛渐变 |
| Python 语法着色 | TextMate + Pylance 语义双层 |
| Vibrancy 叠加 | 可选毛玻璃；chrome 保持不透明 `#111111` |
| Activity Bar | 激活 view 图标樱→靛渐变 + 发光 |
| 编辑器行号 | 光标行 / 选区 / 多光标樱→靛渐变 |
| 编辑器氛围 | 选区渐变、GIF 光标、打字飘落、诊断故障线 |
| Panel 页签 | Terminal / Problems 流动下边框 |
| Title bar / 断点 | 可选 mascot GIF |
| Home 水印 | 可选欢迎页 `Aemeath_JUMP.gif` |

---

## 3. 项目结构

```
fleet-snowfluff/
├── package.json
├── README.md
├── assets/                          # 可选资源（不纳入 VSIX）→ assets/README.md
│   ├── aemeath/                     # 角色 GIF
│   └── dropings/                    # 打字飘落 png/gif
├── themes/                          # 主题与 Vibrancy 源文件 → themes/README.md
│   ├── fleet-snowfluff-dark.color-theme.json
│   ├── fleet-python-import.tmLanguage.json
│   ├── vibrancy-opaque-chrome.css
│   ├── fleet-activity-global-menu.js
│   ├── fleet-editor-line-numbers.js
│   ├── fleet-editor-atmosphere.template.js
│   ├── fleet-titlebar-mascot.template.css
│   └── fleet-home-watermark.template.css
└── scripts/
    ├── setup-vibrancy.ps1           # 一键部署 Vibrancy 资源
    ├── optimize-titlebar-gif.py     # 动图整数倍缩小
    └── patches/                     # Vibrancy runtime CSP patch
```

---

## 4. Python 代码着色

Fleet Snowfluff 的**编辑器代码色**目前仅针对 **Python** 定制。

### 两层机制

| 层级 | 配置位置 | 作用 |
|------|----------|------|
| **TextMate** | `tokenColors` | 语法规则：`def`、字符串、注释、转义、括号等 |
| **语义** | `semanticTokenColors`（`:python`） | Pylance：变量、参数、函数引用、类名等 |

语义 token **优先覆盖** TextMate。字符串字面量**刻意不走** `string:python` 语义色，以便 `\n` 等转义保留 TextMate 着色。

### 前置条件

1. [Pylance](https://marketplace.visualstudio.com/items?itemName=ms-python.vscode-pylance)
2. `editor.semanticHighlighting.enabled`: `true`（主题与扩展默认已开）

### Python 角色色

| 角色 | 色值 |
|------|------|
| 关键字 | `#4A9EFF` |
| 函数 / 方法 | `#FF8FAB` |
| 单行 / 前缀字符串 | `#FF7A45` |
| 字符串转义 | `#C85874` |
| 多行 docstring | `#E8E8E8` |
| 字面量修饰符（`0x` / `j` / `b` `r` `f`） | `#92DED9` |
| 常量 / 数字 | `#F6C343` |
| 类型 / 类 | `#B090F0` |
| 变量 / 参数 | `#B0C4E0` |
| 注释 | `#6B7A8C` |
| 括号 / 分组 | `#D8DCE0` |
| 运算符 / 其他标点 | `#FFFFFF80` |

括号 import 列表：`fleet-python-import.tmLanguage.json` 语法注入；改 grammar 后 F5 / 重装 VSIX。

### 验证语义高亮

**Developer: Inspect Editor Tokens and Scopes** → 点击局部变量 → 应见 `semantic token type: variable`，前景 `#B0C4E0`。

---

## 5. Vibrancy 叠加（可选）

### 安装

```powershell
.\scripts\setup-vibrancy.ps1
```

脚本会：复制 CSS/JS 到 `%APPDATA%\Cursor\User\fleet-snowfluff\`；patch Vibrancy runtime；嵌入 assets 生成 `fleet-editor-atmosphere.js`；合并 `vscode_vibrancy.imports`。

### settings.json 示例

```json
{
  "workbench.colorTheme": "Fleet Snowfluff Dark",
  "workbench.activityBar.orientation": "vertical",
  "vscode_vibrancy.opacity": 0.7,
  "vscode_vibrancy.backgroundOverride": "#000000",
  "vscode_vibrancy.enableAutoRefresh": false,
  "vscode_vibrancy.disableFramelessWindow": true,
  "vscode_vibrancy.imports": [
    "C:/Users/<用户名>/AppData/Roaming/Cursor/User/fleet-snowfluff/vibrancy-opaque-chrome.css",
    "C:/Users/<用户名>/AppData/Roaming/Cursor/User/fleet-snowfluff/fleet-activity-global-menu.js",
    "C:/Users/<用户名>/AppData/Roaming/Cursor/User/fleet-snowfluff/fleet-editor-line-numbers.js",
    "C:/Users/<用户名>/AppData/Roaming/Cursor/User/fleet-snowfluff/fleet-editor-atmosphere.js"
  ],
  "terminal.integrated.gpuAcceleration": "off",
  "window.titleBarStyle": "custom",
  "workbench.colorCustomizations": {
    "[Fleet Snowfluff Dark]": {
      "terminal.background": "#000000B3",
      "panel.background": "#000000B3"
    }
  }
}
```

可选追加：`fleet-titlebar-mascot.css`、`fleet-home-watermark.css`（setup 生成后按脚本输出添加）。

**imports 不支持相对路径** — 必须使用部署目录下的绝对路径。

更新流程：**改源文件** → `setup-vibrancy.ps1` → **Vibrancy: Reload** → **完全冷启动**。

### 功能说明

| 模块 | 源文件 | 说明 |
|------|--------|------|
| Chrome / 滚动条 / 缩进线 | `vibrancy-opaque-chrome.css` | 不透明 chrome、樱靛缩进线、选区渐变、诊断故障线样式 |
| 行号高亮 | `fleet-editor-line-numbers.js` | 选区 / 多光标对应行号渐变 |
| 编辑器氛围 | `fleet-editor-atmosphere.js`（生成） | GIF 光标（caret 右侧 + 呼吸）、打字飘落（含 IME） |
| 菜单图标 | `fleet-activity-global-menu.js` | Account / Settings 打开态 |
| Mascot / 水印 | `*.template.css` → 生成 CSS | data URI 嵌入 GIF |

**Patch 原因：** Cursor CSP 禁止 Vibrancy 默认的 `<script>` 注入；Fleet patch 改为内联执行 JS。

### 验证 JS

```javascript
document.documentElement.dataset.fleetActMenu   // "ready"
document.documentElement.classList.contains('fleet-atmosphere-cursor')  // true
fleetLnDiag()                                   // 行号诊断
```

---

## 6. 资源与部署产物

| 仓库路径 | 部署 / 生成 |
|----------|-------------|
| [`assets/aemeath/`](assets/README.md) | 嵌入 `fleet-editor-atmosphere.js`、mascot / 水印 CSS |
| [`assets/dropings/`](assets/README.md) | 嵌入 `fleet-editor-atmosphere.js` |
| [`themes/*`](themes/README.md) | 复制或 template → `%APPDATA%\...\fleet-snowfluff\` |

**Title bar mascot：** 放入 `assets/aemeath/`，大 GIF 可先 `python scripts/optimize-titlebar-gif.py` 生成 `Aemeath_GLASS_titlebar.gif`。

---

## 7. 自定义与故障排除

### 改配色

| 目标 | 文件 |
|------|------|
| UI / 编辑器背景 | `fleet-snowfluff-dark.color-theme.json` → `colors` |
| Python 语法色 | 同上 → `tokenColors` |
| Python 语义色 | 同上 → `semanticTokenColors` |
| Vibrancy 视觉 | `vibrancy-opaque-chrome.css` |

透明度示例：`"editor.background": "#00000099"`（`B3`≈70%，`99`≈60%）。

### 常见问题

| 现象 | 处理 |
|------|------|
| Vibrancy 无效果 | **Vibrancy: Enable** → 完全重启 |
| CSS/JS 未更新 | 重新 `setup-vibrancy.ps1` → **Vibrancy: Reload** → 冷启动 |
| JS 未执行（`fleetActMenu` undefined） | 检查 patch；Vibrancy 升级后重跑 setup |
| 行号无渐变 | imports 含 `fleet-editor-line-numbers.js`；`fleetLnDiag()` |
| GIF 光标不出现 / 不跟随 | imports 含 `fleet-editor-atmosphere.js`；确认 `assets/aemeath/Aemeath_FLY_inline.gif` 存在并重跑 setup |
| 打字无飘落 | `assets/dropings/` 内有 png；重跑 setup |
| Python 变量白板 | 安装 Pylance；语义高亮开启；Inspect Token |
| 括号 import 无着色 | F5 / 重装 VSIX（grammar 注入） |
| patch 失败 | Vibrancy 版本变更；见 `scripts/patches/` |

---

## 8. 许可

MIT — 见 [LICENSE](LICENSE)。
