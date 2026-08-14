# claude-code-beep 🔊

Claude Code 事件提示音：在 **需要你授权**、**任务完成**、**后台子任务完成** 时播放提示音，让你后台跑任务时不用一直盯屏幕，声音一响就知道该回来了。
当然这个功能完全可以让Agent自己帮你实现，因为我这个就是Cladue Code自己做的XD。

适用于 **Windows + Claude Code**（CLI 或 VS Code 扩展均可）。

## 效果

| 场景 | 声音 |
|---|---|
| Claude 需要你授权 / 许可 | Windows Exclamation |
| 主任务完成（一次响应结束） | tada（嗒哒） |
| 后台子任务完成 | Windows Notify × 3 |

## 安装

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File install.ps1
```

- 默认安装到**用户级**，全局生效（所有项目都能用）
- 幂等，重复运行安全，不会覆盖你 `settings.json` 里已有的配置
- 装完后**完全退出 VS Code 再重新打开**（hooks 在会话启动时加载，重载窗口不够）

### 其他安装目标

```powershell
# 安装到项目级（随 git 共享给协作者）
powershell -NoProfile -ExecutionPolicy Bypass -File install.ps1 -Target .claude\settings.json

# 自定义脚本安装目录
powershell -NoProfile -ExecutionPolicy Bypass -File install.ps1 -ScriptDir D:\my-tools
```

## 验证

1. 让 Claude 跑一条未授权命令 → 应听到 **Windows Exclamation**（等你授权）
2. 随便发一句话 → 回答结束时应听到 **tada**

## 定制

- **换声音**：编辑 `install.ps1` 里的 wav 文件名后重新运行即可。可使用 `C:\Windows\Media\` 下的任意系统音，或放入你自己的 wav 文件。
- **连响次数**：`cc-beep.ps1` 的第 2 个参数控制（如 `... "Windows Notify.wav" 3` 表示连响 3 次）。
- **环境变量**：`CC_BEEP_MEDIA` 自定义声音目录；`CC_BEEP_LOG` 自定义日志路径。
- **诊断**：每次播放都会记一行日志，默认在 `%USERPROFILE%\.cc-beep\cc-beep.log`。听不到声音时先看它——有记录说明声音已播放（是音量问题），没记录说明没触发（配置没生效）。

## 目录结构

```
claude-code-beep/
├── cc-beep.ps1      # 播放脚本
├── install.ps1      # 一键安装
└── README.md
```

## License

MIT
