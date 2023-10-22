---
title: 'IDEA使用技巧之导航'
date: 2021-04-21 14:12:14
tags: [工具]
published: true
hideInList: false
feature: 
isTop: false
---



介绍IDEA及AndroidStudio中的导航技巧，包括文件导航，代码元素（类，方法）导航，文本导航等，还有书签等的使用方法；提高编写代码及阅读代码的效率；

<!-- more -->

## 插入符导航

* 后退：==⌘[==
* 前进：==⌘]==
* 最后编辑点： ==⇧⌘⌫==
* 定位到当前的结束括号： ==Ctrl+M== 或者 ==↑== , ==↓==
* 查看光标所在位置所属的元素：==⌃⇧Q== （注意看下图的左上角显示了当前的类）
  * <img src="https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20210410141823.png" alt="image-20210410141822945" style="zoom:50%;" />
* 移动到当前开始括号对应的闭合括号： ==Ctrl + M==
* 在代码块之间导航： ==⌥⇧⌘[== ==⌥⇧⌘]==

## 移动插入符

* 移动到下一个或者上一个单词： ==⌥→==，==⌥←==

* 移动到下个段落：（下个方法） 
  1. 使用 ==Shift+Command+A== 调出Action搜索弹框；
  2. 搜索 **Move Caret Forward a Paragraph** 或 **Move Caret Backward a Paragraph** 

## 查找最近的位置

* 使用 ==⇧⌘E== 可以打开**最近位置**的弹窗，使用上下健进行导航

  <img src="https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20210410143034.png" alt="image-20210410143034118" style="zoom:50%;" />

* 在打开此弹窗时，再次使用 ==⇧⌘E== 可以选中 **Show Changed Only**

* 可直接输入以搜索代码片段

  <img src="https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20210410143308.png" alt="image-20210410143308918" style="zoom:50%;" />

* 删除记录： 按 ==Delete== 或者 ==⌫==



## 使用书签导航

* 创建匿名书签：将光标放置到需要的代码行上，然后按 ： ==F3==

* 创建带助记符的书签： 将光标放置到需要的代码行上，然后按 ： ==⌥F3==，之后可通过输入字母或者数字来设置对应的助记符号；

  <img src="https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20210410143644.png" alt="image-20210410143644729" style="zoom:50%;" />

* 显示上个或下个书签： 在主菜单中选择 **Navigate | Bookmarks | Next Bookmark** 或 **Navigate | Bookmarks | Previous Bookmark**

* 打开书签对话框： ==⌘F3== 

  * 此对话框也可用于管理书签，如删除，排序，附加简要描述

* 在已有的**字母助记符书签**之间导航（通过字母）： 按 ==⌘F3==， 然后输入一个字母；

* 在已有的**数字助记符书签**之间导航（通过字母）： 按 ==^==， 然后输入一个数字；

* 创建的每个书签都会在*Favorites*==⌘2==（**View | Tool Windows | Favourites**）窗口中反映出来，所以也可以使用此窗口来导航。

  <img src="https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20210420114331.png" alt="Favorites window" style="zoom:67%;" />

## 在变更之间导航

如果编辑受版本控制的文件，则IntelliJ IDEA提供了几种来回移动更新的方法。可以使用导航命令，键盘快捷键和更改标记。 

* 使用 ==⌃⌥⇧↓==/ ==⌃⌥⇧↑==
* 在主菜单中选择： **Navigate | Next / Previous Change**
* 点击一个==变更标记（change marker）==，然后点击  ![the Previous Change button](https://resources.jetbrains.com/help/img/idea/2021.1/icons.actions.previousOccurence.svg) 或 ![the Next Change button](https://resources.jetbrains.com/help/img/idea/2021.1/icons.actions.nextOccurence.svg)

* 导航到最后一个编辑的地方： ==⇧⌘⌫== 或从主菜单选择 **Navigate | Last Edit Location**



## 查看最近修改

使用 **Recent Changes** 弹窗来查看最近变更的文件列表，也可撤销相关修改。

1. 在主菜单中选择 **View | Recent Changes** ==⌥⇧C==

<img src="https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20210420114347.png" alt="the Recent Changes popup" style="zoom:67%;" />

2. 在弹出框中选择一个文件，然后按下 ==⏎== 打开一个单独的对话框用于检查变更；





## 导航到声明和类型

* 将光标放置在要查询的符号上，按： ==⌘B== (查询用法)
* 查询类型定义： ==⇧⌘B==



## 导航到实现（实用）

可以使用编辑器中的装订线图标或按相应的快捷方式来跟踪类的实现和重写方法。 

* 点击 ![the Implemented method icon](https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20210421141808.svg)/ ![the Implementing method icon](https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20210421141815.svg), ![the Overridden method icon](https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20210421141820.svg)/ ![the Overriding method icon](https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20210421141824.svg) 编辑器装订线中的图标可以选择父类或子类。 

  <img src="https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20210420114328.png" alt="Gutter icons" style="zoom:67%;" />

* 导航到父方法： ==⌘U==
* 导航到实现：==⌥⌘B==



## 显示兄弟姐妹（siblings ==sɪblɪŋz==）

可在单独的弹出框中查看实现方法的邻居类

1. 在编辑器中，将光标放置在方法名称上；
2. 在主菜单中，选择 **View | Show Siblings** 
3. IDEA会打开一个弹框，可以在其中浏览实现，导航到源码，编辑源码，或者在Find工具窗口在打开列表；

> 也可以在Action查询窗口中搜索进入😯



## 使用Select In 弹框

在Project工具窗口在自动定位一个类。

1. 如果在编辑器中被打开了，按 ==⌥F1== 以打开 Select In 弹窗；

   <img src="https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20210420114318.png" alt="Select in popup" style="zoom:50%;" />

2. 在弹出框中，选择 **Project View**，然后按 ==⏎== 即可在Project 工具窗口中定位类。

![image-20210421084613961](https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20210421084614.png)

3. 还有其他功能：可以在弹出窗口之后，按对应的数字键进行导航
   * 查看收藏
   * 查看文件结构
   * 导航条
   * 在文件管理器中查看文件
   * 项目结构

## 在Project工具窗口中定位文件

可以使用“**Open Files with Single Click**”（以前称为“自动滚动到源代码”）和“始终选择打开的文件”（以前称为“**Always Select Opened Files** ”）操作来在“**Project**”工具窗口中找到文件。 

1. 在“**Project**”工具窗口中，右键单击“**Project**”工具栏，然后从上下文菜单中选择“**Always Select Opened Files**”。 之后IDEA将跟踪当前在活动编辑器选项卡中打开的文件，并自动在“**Project**”工具窗口中找到它。 

   <img src="https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20210420114357.png" alt="Context menu" style="zoom:50%;" />

2. 您也可以选择“**Open Files with Single Click**”选项。 在这种情况下，当您在“项目”视图中单击文件时，IntelliJ IDEA将自动在编辑器中将其打开。



## 在错误和警告之间导航

* 跳转到下一个问题：==F2== （**Navigate | Next  Highlighted Error**）
* 跳转到上一个问题：==⇧F2== （**Navigate | Previous Highlighted Error**）

* 配置IntelliJ IDEA在代码问题之间导航的方式：它可以在所有代码问题之间跳转，也可以跳过次要问题，并且仅在检测到的错误之间导航。 右键单击滚动条区域中的代码分析标记，然后从上下文菜单中选择一种可用的导航模式： 
  * 要使IntelliJ IDEA跳过警告，信息和其他次要问题，请选择 **Go to high priority problems only**（仅转到高优先级问题）。 
  * 要使IntelliJ IDEA在所有检测到的代码问题之间跳转，请选择**Go to next problem**（转到下一个问题）。 



## 使用Structure View 弹窗定位代码元素

可使用Structure View 弹窗来定位当前文件中的元素；

1. 打开StructureView弹窗： ==⌘F12== （也可以通过==⌥F1== + ==3==来打开）
2. 在弹窗中定位到你需要的条目，然后按 ==⏎== 来返回到编辑器的相应位置；
3. 在弹窗中可以排序文件中的元素，筛选以查看匿名类和继承类成员；





## 通过方法浏览

* 按： ==⌃↓== or ==⌃↑== （和mac快捷键冲突了）
* 要在视觉上分离代码中的方法，请在“设置/首选项”对话框⌘中，转到“编辑器” |“设置”。 一般| 外观，然后选择**Show method separators**（显示方法分隔符）选项。

* 打开**Structure** 工具窗口：==⌘7==





## 使用镜头模式

镜头模式使您无需实际滚动即可预览代码。 当您将鼠标悬停在滚动条上时，默认情况下该模式在编辑器中可用。 将鼠标悬停在警告或错误消息上时，此功能特别有用。 

<img src="https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20210420114404.png" alt="Lens mode" style="zoom:67%;" />

* 要禁用镜头模式，请右键单击位于编辑器右侧的代码分析标记，然后在上下文菜单中清除“在滚动条悬停时显示代码镜头”复选框。
* 或者，在**Settings/Preferences**对话框==⌘==中，转到**Editor | General | Appearance** 并清除 **Show code lens on the scrollbar hover** 复选框。



## 使用面包屑导航

您可以使用面包屑浏览源代码，这些面包屑显示当前打开的文件中的类，变量，函数，方法和标记的名称。 默认情况下，启用面包屑并将其显示在编辑器的底部。

* 要更改面包屑的位置，请右键单击一个面包屑，在上下文菜单中选择**Breadcrumbs**和位置首选项。
* 要编辑面包屑设置，请在**Settings/Preferences**对话框==⌘==中，转到**Editor | General | Breadcrumbs**。

<img src="https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20210421085951.png" alt="image-20210421085951907" style="zoom:67%;" />



## 通过导航条导航到文件

使用导航栏作为方便的工具来查找整个项目。

1. 使用 ==⌘↑==来激活导航条；
2. 使用方向键或者鼠标来定位到想要的文件；
3. 双击选择的文件或者按回车键来在编辑器中打开该文件；
4. 也可以输入以筛选/搜索文件；
5. 点击导航栏中的Java类或者接口可以查看其方法列表，点击其中一个方法可在编辑器中快速跳转到对应的方法；

![image-20210421090027447](https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20210421090027.png)

## 查找文件路径

1. 在编辑器中，按==⌥⌘F12== 或者在上下文菜单中选择 **Open in | Finder**

2. 在 **Reveal in Finder** 弹窗中，选择要打开的文件或者目录，然后按 ==⏎==；

   <img src="https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20210420114408.png" alt="File path finder" style="zoom: 50%;" />

> 也可以通过 ==⌘F1== ，然后按==7==来在Finder中打开正在编辑的文件

## 查找最近的文件

在**Recent Files**弹窗中查找最近或者最近编辑的文件；

1. 打开 **Recent Files**弹窗： ==⌘E==

   <img src="https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20210420114413.png" alt="Recent files" style="zoom:50%;" />

2. 再次按 ==⌘E==来激活 **Show changed only**单选框；

3. 可以输入文字以搜索；

<img src="https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20210421090237.png" alt="image-20210421090237661" style="zoom:76%;" />

> 左边可以导航到各个工具窗口😯

## 文本匹配导航（自行补充）（实用）

光标停留在一个文本上时，可以快速在所有出现该文本的代码行之间导航：

* 向上查找 ==⌃⌥↑==
* 向下查找 ==⌃⌥↓==





> 参考： [jetbrains-Source code navigation](https://www.jetbrains.com/help/idea/2021.1/navigating-through-the-source-code.html#find_cursor_edit)