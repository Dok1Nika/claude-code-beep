# claude-code-beep 🔊

让 Claude Code 在**需要你授权 / 任务完成 / 子任务完成**时播放提示音——这样你后台挂着 Claude 跑任务、自己去忙别的时，不用一直盯屏幕，声音一响就知道该回来了。

**已实测环境**：Windows 10 + Claude Code VS Code 扩展（CLI 2.1.227，扩展 2.1.232）。

## 效果

| 场景 | 触发事件 | 声音 |
|---|---|---|
| Claude 需要你授权/许可 | `PermissionRequest` | Windows Exclamation |
| 主任务完成（一次响应结束） | `Stop` | tada（嗒哒） |
| 后台子任务完成 | `Notification` / `SubagentStop` | Windows Notify × 3 |

## 一键安装

```powershell
# 从仓库目录运行，安装到用户级（全局生效，推荐）
powershell -NoProfile -ExecutionPolicy Bypass -File install.ps1
```

装完**完全退出 VS Code 再重开**（hooks 在会话启动时加载，重载窗口不够），就生效了。

> install.ps1 是幂等的（合并而非覆盖），重复运行安全；它会保留你 `settings.json` 里已有的键（比如 ccswitch / 代理工具管理的 `env` 块）。

### 其他安装目标

```powershell
# 安装到项目级（随 git 共享给协作者）
powershell -NoProfile -ExecutionPolicy Bypass -File install.ps1 -Target .claude\settings.json
# 自定义脚本安装目录
powershell -NoProfile -ExecutionPolicy Bypass -File install.ps1 -ScriptDir D:\my-tools
```

## 手动安装（不想跑脚本）

1. 把 `cc-beep.ps1` 放到任意目录（如 `%USERPROFILE%\.cc-beep\`）。
2. 在 `~/.claude/settings.json`（全局）或 `.claude/settings.json`（项目）里加：

```json
{
  "hooks": {
    "PermissionRequest": [
      { "matcher": "*", "hooks": [
        { "type": "command", "command": "powershell -NoProfile -NonInteractive -File \"C:\\Users\\you\\.cc-beep\\cc-beep.ps1\" \"Windows Exclamation.wav\"", "timeout": 10 }
      ]}
    ],
    "Stop": [
      { "matcher": "Stop", "hooks": [
        { "type": "command", "command": "powershell -NoProfile -NonInteractive -File \"C:\\Users\\you\\.cc-beep\\cc-beep.ps1\" tada.wav", "timeout": 10 }
      ]}
    ],
    "Notification": [
      { "matcher": "SubagentStop", "hooks": [
        { "type": "command", "command": "powershell -NoProfile -NonInteractive -File \"C:\\Users\\you\\.cc-beep\\cc-beep.ps1\" \"Windows Notify.wav\" 3", "timeout": 10 }
      ]}
    ]
  }
}
```

## 定制

- **换声音**：改 hook 命令里的 wav 文件名，可用 `C:\Windows\Media\` 下任意系统音，或自己拷 wav 进去（传全名即可）。第二个参数是连响次数。
- **加场景**：Claude Code 还支持 `PostToolUse`、`SessionStart`、`SubagentStop`（独立事件）、`TaskCompleted` 等几十个事件，照葫芦画瓢加一组即可。
- **环境变量**：`CC_BEEP_MEDIA`（声音目录）、`CC_BEEP_LOG`（日志路径），不设则用默认值。
- **诊断**：每次播放都会写一行到 `%USERPROFILE%\.cc-beep\cc-beep.log`。听不到声音时先看它——有记录=hook 触发了且已播放（是音量/在不在场问题）；没记录=hook 没触发（配置没加载）。

## 踩过的坑（比脚本更值钱的经验）

1. **`Notification` hook 的 `PermissionDecision` matcher 在 VS Code 扩展里不触发**。权限请求走扩展自己的 UI，不经过 CLI 的 Notification 管道。必须用独立的 **`PermissionRequest` 事件**（实测有效）。这是本仓库最核心的结论。
2. **`[console]::beep` 在很多机器上听不到**——它走主板蜂鸣器，现代台式/笔记本大多没这设备（哪怕 Beep 服务在运行）。用 `System.Media.SoundPlayer` 播 WAV 走默认音频设备，可靠。
3. **Windows 上 hooks 通过 shell 执行，路径带空格的文件名必须加引号**，否则被拆成两个参数。命令统一 `powershell -NoProfile -NonInteractive -File ...`，在 Git Bash / cmd / PowerShell 外层都能跑。
4. **hooks 跨层级是合并的**：全局 `~/.claude/settings.json` 和项目 `.claude/settings.json` 都配了同一个事件会**重复响**。要么全局要么项目，别都配。
5. **改 settings.json 要重启会话才生效；改 cc-beep.ps1 立即生效**（脚本每次触发时实时读取）。
6. **连响间隔**：`cc-beep.ps1` 里 100ms，3 连响听起来紧凑；想拖开一点改 `Start-Sleep -Milliseconds`。

## 目录结构

```
claude-code-beep/
├── cc-beep.ps1      # 播放脚本（参数化：wav 名 + 连响次数，环境变量可覆盖路径）
├── install.ps1      # 一键安装：复制脚本 + 合并 hooks 进 settings.json（幂等）
└── README.md        # 本文档
```

## Roadmap（已规划，未实现）

- **可视化配置**：对不同事件独立开关提示音、自由上传/选择音效。计划做一个轻量本地配置界面，把事件→声音映射改到可视化编辑。

## 兼容性

- 目标平台：**Windows**（脚本用 PowerShell + Windows Media，其他平台需改写）。
- CLI 与 VS Code 扩展均可用；授权音事件 `PermissionRequest` 在两者都触发。
- 未经测试：Windows 11（原理相同，应该可用）。

## License

MIT
