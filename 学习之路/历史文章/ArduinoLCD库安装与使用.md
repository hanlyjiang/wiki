---
title: 'Arduino LCD库安装与使用'
date: 2021-11-30 09:43:24
tags: [Arduino]
published: true
hideInList: false
feature: https://gitee.com/hanlyjiang/image-repo/raw/master/image/202111300942772.png
isTop: false
---


从github下载 LiquidCrystal 的库，安装到Arduino IDE，并点亮1602 LCD。

<!-- more -->



准备使用Arduino UNO点亮一个LCD1602，发现ArduinoIDE（我用的2.0Beta版本）中默认没有安装 LiquidCrystal 的库，所以需要手动进行安装。

## 安装

第一种安装方式是从Arduino IDE的 Library Manager中搜索🔍并安装。另外就是手动安装，这里我们采取手动安装的方式。

1. 访问其github仓库（https://github.com/arduino-libraries/LiquidCrystal），下载为zip包，下载完毕后就是 `LiquidCrystal-master.zip`

2. 按如下路径找到添加 ZIP 库的菜单

   <img src="https://gitee.com/hanlyjiang/image-repo/raw/master/image/202111300938313.png" alt="image-20211130093814250" style="zoom:50%;" />

3. 选择我们的  `LiquidCrystal-master.zip` 文件，安装完毕后重启一下 Arduino IDE。

4. 重新打开IDE，即可看到示例中多了LiquidCrystal 的示例

   <img src="https://gitee.com/hanlyjiang/image-repo/raw/master/image/202111300940469.png" alt="image-20211130093952928" style="zoom:50%;" />

## 运行示例

开一个 Blink 的示例，按如下方式接线。

![image-20211130094241742](https://gitee.com/hanlyjiang/image-repo/raw/master/image/202111300942772.png)

运行之后效果：

*待补图。* 可参考： http://www.taichi-maker.com/homepage/reference-index/arduino-library-index/liquidcrystal-library/