<p align="center">
  <img src="assets/aemeath/Aemeath_GLASS.gif" alt="Fleet Snowfluff — 飞行雪绒" width="280">
</p>

# Fleet Snowfluff

《鸣潮》**飞行雪绒** — 面向 [Cursor](https://cursor.com) 的暗色编程主题（亦可在 [VS Code](https://code.visualstudio.com) 使用）。

---

## 概要

Fleet Snowfluff 将角色「飞行雪绒」的视觉语言带入编辑器：深色底、樱靛渐变点缀，以及可选的毛玻璃与动效氛围。克隆仓库、运行一条安装脚本，即可获得配色主题与完整叠加效果；仓库默认携带全部 `assets/` 资源。

---

## 特色

- **暗色 UI** — Activity Bar、侧栏、页签、Panel 等 chrome 分层不透明，编辑区与终端保留适度通透感
- **多语言着色** — 统一色板覆盖主流语言；Python 单独双层规则（TextMate + Pylance 语义）
- **Vibrancy 叠加** — 毛玻璃、GIF 光标、打字飘落、行号渐变、Title bar mascot、欢迎页水印等
- **本地联接安装** — `setup.ps1` 将仓库挂为扩展并部署叠加层，改主题 JSON 后 Reload Window 即生效

---

## 设计理念

1. **可读优先** — 动效与装饰服务于编码体验，不遮挡文本、不干扰诊断与选区
2. **色系统一** — 编辑器、语义高亮、Terminal ANSI 共用同一套角色色（关键字蓝、函数粉、字符串橙等）
3. **Python 克制** — 保留转义与 import 括号的 TextMate 着色，语义层不覆盖 `string:python`
4. **樱靛意象** — 渐变用于行号、缩进线、页签下划线、Activity 图标等「边缘」元素，而非大面积铺色
5. **Fork 友好** — 资源与叠加层均在仓库内，改 `assets/` 或 `vibrancy/` 后重跑 setup 即可迭代

---

## 项目结构

```
fleet-snowfluff/
├── package.json
├── themes/          # 配色主题与 Python grammar
├── vibrancy/        # Vibrancy 叠加层源文件（CSS / JS / 模板）
├── assets/          # GIF 光标、mascot、水印、飘落图标（默认随仓库分发）
└── scripts/
    ├── setup.ps1           # 一键安装入口
    └── setup-vibrancy.ps1  # 安装实现
```

---

## 快速开始

```
git clone <你的 fork 或本仓库 URL>
cd fleet-snowfluff
```

| # | 操作 |
|---|------|
| 1 | 在 Cursor 扩展市场安装 **[Vibrancy Continued](https://marketplace.visualstudio.com/items?itemName=illixion.vscode-vibrancy-continued)** |
| 2 | 仓库根目录执行 `.\scripts\setup.ps1` |
| 3 | 命令面板 → **Vibrancy: Enable**（仅首次） |
| 4 | 命令面板 → **Vibrancy: Reload** |
| 5 | **完全退出** Cursor（含系统托盘图标） |
| 6 | 重新打开 Cursor |

### 推荐：关闭 GPU 合成启动（Vibrancy 更稳定）

Fleet Snowfluff 搭配 Vibrancy 时，在 **开启 Chromium GPU 合成** 下，Extensions 视图偶发侧栏发灰、整窗像蒙一层雾（Explorer 等视图通常正常）。根因是 GPU 合成层与毛玻璃叠层的交互，**不是主题配色错误**。

**推荐做法**：用 `--disable-gpu-compositing` 启动 Cursor（已验证可消除上述现象）。

**Windows 快捷方式示例**

1. 右键桌面 → **新建** → **快捷方式**
2. 目标填写（按你的安装路径调整）：

   ```
   "C:\Users\<用户名>\AppData\Local\Programs\cursor\Cursor.exe" --disable-gpu-compositing
   ```

3. 之后始终用该快捷方式打开 Cursor

可能略影响部分滚动/动画流畅度；终端可单独设 `terminal.integrated.gpuAcceleration: "off"`，与整窗关闭 GPU 合成是不同层级。更多说明见 [MAINTENANCE.md — GPU 合成与 Vibrancy](MAINTENANCE.md#gpu-合成与-vibrancy)。

### 日常更新

| 场景 | 操作 |
|------|------|
| `git pull`、改了 `vibrancy/` 或 `assets/` | `.\scripts\setup.ps1` → **Vibrancy: Reload** → 冷启动 |
| 只改了 `themes/*.json` | **Developer: Reload Window** |

### IDE 或扩展升级后

Cursor / VS Code **主程序升级**，或 **Vibrancy Continued 扩展升级**后，建议：

1. 重新执行 `.\scripts\setup.ps1`（重新合并 `settings.json`、必要时重新 patch Vibrancy 运行时）
2. **Vibrancy: Reload**
3. **完全退出并冷启动** Cursor

若升级后出现毛玻璃失效、GIF 光标消失、叠加 JS 不执行等现象，按上述三步处理通常即可恢复。

---

## 技术细节

配色规则、资源清单、叠加层模块、安装脚本参数、故障排除与二次开发说明，见 **[MAINTENANCE.md](MAINTENANCE.md)**。

---

## 许可

MIT — 见 [LICENSE](LICENSE)。
