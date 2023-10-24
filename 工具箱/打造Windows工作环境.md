---
title: '打造Windows工作环境.md'
date: 2023-10-20 12:44:36
tags: [Windows,效率提升]
published: true
hideInList: false
feature: 
isTop: false

---

# 终端工具

终端使用 Windows Terminal，包括以下几个：

1. Bash（Git）

2. PowerShell

3. WSL

## 软件



## 恢复网络配置

```powershell
netsh winsock reset

netsh int ip reset

ipconfig /release

ipconfig /renew

ipconfig /flushdns
```

重启电脑
