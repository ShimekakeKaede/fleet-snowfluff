# 主题与 Vibrancy 源文件（`themes/`）

## 扩展内置（随 VSIX / F5 发布）

| 文件 | 说明 |
|------|------|
| `fleet-snowfluff-dark.color-theme.json` | 主主题：`colors`、`tokenColors`、`semanticTokenColors` |
| `fleet-python-import.tmLanguage.json` | Python `from … import (` 语法注入 |

## Vibrancy 源文件（需 `setup-vibrancy.ps1` 部署）

| 文件 | 部署目标 | 说明 |
|------|----------|------|
| `vibrancy-opaque-chrome.css` | 同名 CSS | Chrome 不透明层、Activity bar、行号样式、选区渐变、缩进线、诊断故障线等 |
| `fleet-activity-global-menu.js` | 同名 JS | Account / Settings 菜单打开态追踪 |
| `fleet-editor-line-numbers.js` | 同名 JS | 行号樱→靛高亮（选区 / 多光标） |
| `fleet-editor-atmosphere.template.js` | **`fleet-editor-atmosphere.js`（生成）** | 模板；setup 嵌入 GIF / 飘落 icon 后写入用户目录 |
| `fleet-titlebar-mascot.template.css` | **`fleet-titlebar-mascot.css`（生成）** | Title bar / 断点 mascot |
| `fleet-home-watermark.template.css` | **`fleet-home-watermark.css`（生成）** | 欢迎页水印 |

**不要**手改用户目录下的 `fleet-editor-atmosphere.js`（含 base64）；改 `assets/` 或 template 后重新运行 setup。

## 修改指引

| 目标 | 编辑 |
|------|------|
| Python 语法色 / 语义色 | `fleet-snowfluff-dark.color-theme.json` |
| UI /workbench 色 | 同上 `colors` |
| 毛玻璃 chrome、行号、选区、缩进线 | `vibrancy-opaque-chrome.css` |
| GIF 光标 / 打字飘落逻辑 | `fleet-editor-atmosphere.template.js` |
| 行号高亮逻辑 | `fleet-editor-line-numbers.js` |

改 CSS/JS 或 template 后：`setup-vibrancy.ps1` → **Vibrancy: Reload** → 冷启动。  
改 color-theme 或 grammar 后：**Reload Window** 或重装 VSIX。
