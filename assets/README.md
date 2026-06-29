# 资源目录（`assets/`）

本目录存放 **Vibrancy 可选资源**，体积较大，**不打包进 VSIX**（见根目录 `.vscodeignore`）。  
安装后由 `scripts/setup-vibrancy.ps1` 读取并嵌入到 `%APPDATA%\Cursor\User\fleet-snowfluff\`。

## `aemeath/` — 角色动图

| 文件 | 用途 |
|------|------|
| `Aemeath_FLY_inline.gif` | **必需（氛围）** — 编辑器 GIF 光标（setup 嵌入 `fleet-editor-atmosphere.js`） |
| `Aemeath_FLY.gif` | Title bar mascot 候选（优先于 GLASS 系列） |
| `Aemeath_GLASS.gif` | 断点 / mascot 源图；可经 `optimize-titlebar-gif.py` 缩小 |
| `Aemeath_GLASS_inline.gif` | 内联体积较小的 GLASS 变体 |
| `Aemeath_GLASS_titlebar.gif` | **推荐** — setup 自动生成或手动放置，用于 title bar / 断点 |
| `Aemeath_JUMP.gif` | 欢迎页 Home 水印 |
| `Aemeath_Hu.gif` | 备用素材，当前未引用 |

## `dropings/` — 打字飘落图标

放置 `png` / `gif` / `webp`，setup 会**全部嵌入** `fleet-editor-atmosphere.js` 并随机选用。

当前示例：`icon0.png`、`icon2.png`、`icon3.png`（文件名任意，按字母序读取）。

## 更新资源后

```powershell
.\scripts\setup-vibrancy.ps1
```

然后 **Vibrancy: Reload** → **完全重启 Cursor**。
