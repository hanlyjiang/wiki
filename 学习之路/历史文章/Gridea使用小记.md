---
title: 'Gridea使用小记'
date: 2021-04-05 11:58:07
tags: [工具]
published: true
hideInList: false
feature: 
isTop: false
---
仅记录使用Gridea过程中解决的问题及解决方式
<!-- more -->



## 下载安装并使用
访问这里（https://gridea.dev/）下载安装并使用，不赘述。

## 远程同步github配置
关于建立仓库，获取token，配置pages赘述，仅记录额外的配置。


在Gridea的工作目录的根目录中新建一个 `.gitignore` 文件，输入如下内容：
```txt
.DS_Store
*/.DS_Store
# 自己的本地草稿
typora
```
> 远程同步时，会将此文件放入到output目录下，然后将output目录推送到github上，为了避免将其中的某些文件推入到远程仓库，故可以通过此方式定义gitignore
