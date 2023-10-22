---
title: 'Android事件及手势'
date: 2018-02-20 10:13:24
tags: [Android]
published: true
hideInList: false
feature: 
isTop: false
---
android事件基础及手势，主要关注各种手势的使用及其计算原理 。  

<!-- more -->


## Android事件基础

这里我们主要关注概念

### 事件监听器及事件处理程序

可直接查看 [官方文档](https://developer.android.google.cn/guide/topics/ui/ui-events)，此处仅做简要描述；

#### 事件监听器

View类的包含一个回调方法的接口，通过setXXXListener来定义事件处理程序；

> 事件监听器是 `View` 类中包含一个回调方法的接口。当用户与界面项目之间的互动触发已注册监听器的 View 对象时，Android 框架将调用这些方法。
>
> 事件监听器接口中包含以下回调方法：onClick()，onLongClick()，onFocusChange()，onKey()，onTouch()，onCreateContextMenu()

我们重点关注onTouch：

> onTouch()： 在 `View.OnTouchListener` 中。当用户执行可视为触摸事件的操作时，包括按下、释放或屏幕上的任何移动手势（在项目边界内），系统会调用此方法。
>
> 此方法返回一个布尔值，指示监听器是否处理完此事件。重要的是，此事件可以拥有多个分先后顺序的操作。因此，如果在收到 down 操作事件时返回 false，则表示您并未处理完此事件，而且对其后续操作也不感兴趣。因此，您无需执行事件内的任何其他操作，如手势或最终的 up 操作事件。

#### 事件处理程序

直接引用官方文档描述：

> 如果您从 View 构建自定义组件，则可定义几种回调方法，用作默认事件处理程序。在有关[自定义 View 组件](https://developer.android.google.cn/guide/topics/ui/custom-components)的文档中，您将了解一些用于事件处理的常见回调，包括：
>
> - `onKeyDown(int, KeyEvent)`：在发生新的按键事件时调用。
> - `onKeyUp(int, KeyEvent)`：在发生 key up 事件时调用。
> - `onTrackballEvent(MotionEvent)`：在发生轨迹球动作事件时调用。
> - `onTouchEvent(MotionEvent)`：在发生触屏动作事件时调用。
> - `onFocusChanged(boolean, int, Rect)`：在 View 对象获得或失去焦点时调用。
>
> 还有一些其他方法值得您注意，尽管它们并非 View 类的一部分，但可能会直接影响所能采取的事件处理方式。因此，在管理布局内更复杂的事件时，不妨考虑使用以下其他方法：
>
> - `Activity.dispatchTouchEvent(MotionEvent)`：此方法允许 `Activity` 在所有触摸事件分派给窗口之前截获它们。
> - `ViewGroup.onInterceptTouchEvent(MotionEvent)`：此方法允许 `ViewGroup` 监视分派给子级 View 的事件。
> - `ViewParent.requestDisallowInterceptTouchEvent(boolean)`：对父级 View 调用此方法，可指示不应使用 `onInterceptTouchEvent(MotionEvent)` 截获触摸事件。

这里我们重点关注 `onTouchEvent(MotionEvent)` 即在发生触屏动作事件时调用的回调方法；

### 触摸手势

手势可以让用户通过触摸来与屏幕元素进行交互；

**用户交户角度的手势划分**：

| 手势类型 | 具体手势-不同类型之间有重复 | 解释                                                         |
| -------- | --------------------------- | ------------------------------------------------------------ |
| 导航手势 |                             | 实现导航作用                                                 |
|          | 点击 - Tap                  | 如：点击按钮跳转到另外一个页面                               |
|          | 滚动和拖移 - Scroll&Pan     | 如：滑动图片列表或拖动以浏览地图<br/><br/>Scroll - 快速拖动并抬起手指时发生的一种滚动 <br/> Pan-拖移，慢速移动 |
|          | 拖动/拖拽 - Drag            | 用户在触摸屏上拖动手指时发生的一种滚动<br/>如：按住底部sheet并向屏幕顶部拖动 |
|          | 轻扫 - Swipe                | 单个手指触摸屏幕并快速地朝任意一个方向滑动<br/>如：左右滑动以在不同的Tab页中切换 |
|          | 捏合/缩放 - Pinch           | 双指或多指捏合<br/>如：在一个图片列表中缩放一个item进入大图查看界面 |
| 动作手势 |                             | 执行某种动作                                                 |
|          | 点击 - Tap                  |                                                              |
|          | 长按 - Long press           | 如：长按选中                                                 |
|          | 轻扫 - Swipe                | 如：轻扫item展现删除/收藏按钮                                |
| 变换手势 |                             | 用于改变元素大小，位置，旋转角度，实现变换效果               |
|          | 双击 - Double tap           | 如：双击缩放图片                                             |
|          | 捏合/缩放 - Pinch           | 如：缩放查看图片细节                                         |
|          | 组合手势                    | 如：地图中的放大缩小&旋转                                    |
|          | 选取并拖动 - Pick up&Move   | 长按选择元素 + 拖动元素                                      |

>  [来源](https://material.io/design/interaction/gestures.html)及手势的动画效果可以看这里： [material.io](https://material.io/design/interaction/gestures.html#types-of-gestures)

**Android中用于检测或处理手势的类/方法：**

* [GestureDetector](https://developer.android.google.cn/reference/android/view/GestureDetector)：支持检测按下、滑动、长按等手势；事件回调方法包括 `onDown()`、`onLongPress()`、`onFling()`、[onScroll()](https://developer.android.google.cn/reference/android/view/GestureDetector.OnGestureListener#onScroll(android.view.MotionEvent, android.view.MotionEvent, float, float)) 等。可以将 `GestureDetector` 与 `onTouchEvent()` 方法结合使用；
* [ScaleGestureDetector](https://developer.android.google.cn/reference/android/view/ScaleGestureDetector)：用于检测缩放手势；
* [onTouchEvent()](https://developer.android.google.cn/reference/android/view/View#onTouchEvent(android.view.MotionEvent))： 直接处理onTouchEvent()方法，然后自行根据事件序列来判断手势；
* [VelocityTracker](https://developer.android.google.cn/reference/android/view/VelocityTracker)：用于跟踪触摸事件的速度，如滑动事件中一般需要结合速度来使用；
* [Scroller](https://developer.android.google.cn/reference/android/widget/Scroller) & [OverScroller](https://developer.android.google.cn/reference/android/widget/OverScroller)： 用于收集触摸事件来生成滚动动画所需的数据，OverScroller可以指示滑动后是否到达了内容边缘；

>  **两种不同的滚动: 拖动和滑动**
>
> - **拖动**是指用户在触摸屏上拖动手指时发生的一种滚动。简单的拖动通常是通过替换 `GestureDetector.OnGestureListener` 中的 `onScroll()` 实现的。有关拖动的详细讨论，可参阅[拖动和缩放](https://developer.android.google.cn/training/gestures/scale)。
> - **滑动**是用户快速拖动并抬起手指时发生的一种滚动。在用户抬起手指后，您通常需要继续滚动（移动视口），但要减速，直到视口停止移动为止。滑动可以通过替换 `GestureDetector.OnGestureListener` 中的 `onFling()` 以及使用滚动条对象来实现。
> - 系统会在用户拖动手指以平移内容时调用 `onScroll()`，系统仅在手指还在屏幕上时才会调用 `onScroll()`；当手指从屏幕上抬起时，手势便会结束，或开始执行滑动手势（如果手指在抬起之前正在以一定的速度移动）。



接下来我们详细了解触摸手势中各个item的用法；



## 触摸事件类逐个了解

我们先对涉及的元素类进行单独学习，由于普通的事件监听器比较简单，所以主要关注触摸手势部分，这块先从GestureDetector开始；

### GestureDetector 详解

能够识别的手势，是 `GestureDetector.OnGestureListener`及 ，`GestureDetector.SimpleOnGestureListener` ,其中 包括如下几种：

| 回调方法                                                    | 对应事件触发时机及说明                       |
| ----------------------------------------------------------- | -------------------------------------------- |
| `onDown(downEvent):Boolean`                                 | 点按按下手指时 event为down事件时触发.        |
| `onFling(downEvent,upEvent,velocityX,velocityY):Boolean`    | 滑动(投掷)事件发生时触发                     |
| `onLongPress(downEvent)`                                    | 发生长按事件时触发                           |
| `onScroll(downEvent,moveEvent,distanceX,distanceY):Boolean` | 拖动事件发生时                               |
| `onShowPress(downEvent)`                                    | 按在屏幕上但是没有移动或抬起手指             |
| `onSingleTapUp(upEvent):Boolean`                            | 点按抬起手指时触发                           |
| `GestureDetector.SimpleOnGestureListener`                   |                                              |
| `onContextClick(event)`                                     | 上下文菜单点击事件发生时                     |
| `onDoubleTap(event)`                                        | 双击事件                                     |
| `onDoubleTapEvent(event)`                                   | 双击事件过程中的事件，包括down，move，up事件 |
| `onSingleTapConfirmed(event)`                               | 单次点击发生时                               |

#### **问题：**

以下通过**阅读API文档并编写简单的示例代码**，通过**操作触发对应的手势来观察**以确定以下问题的答案。

1. GestureDetector 各个事件发生的关系，有无交叉？
   * 按下-释放可能的事件序列：
     * onDown - onSingleTapUp： 按下，迅速抬起（干净利落的）
     * onDown - onShowPress - onSingleTapUp：按下，缓慢抬起
     * onDown - onShowPress - onLongPress：按下，稍有延迟的抬起
   * onScroll触发的可能事件序列：
     * longPress 被触发之后，无法再触发onScroll
     * onDown - onScroll
     * onDown - onShowPress - onScroll
   * onFling的触发序列
     * 触发onScroll - 多个 onScroll - onFling
2. GestureDetector.SimpleOnGestureDetector
   * 单次点击事件序列：
     * onDown - onSingleTapUp - onSingleTapConfirmed
     * onDown - onShowPress - onSingleTapUp - onSingleTapConfirmed （按下后稍有停顿）
   * 双击可能的事件序列：
     * onDown - onShowPress - onSingleTapUp - onDoubleTap_down - onDoubleTapEvent_down - **onDown** - onShowPress - onDoubleTapEvent_up
3. 滑动onFling和拖动onScroll的区别时机？
   * onScroll一定先发生，如果抬起时有一定速度，就会触发onFling
4. `onSingleTapUp(upEvent)` 及 `onSingleTapConfirmed(event)`的区别？
   - onSingleTapConfirmed 只会在确认当前tap之后不会有另外一次tap构成double-tap手势的情况下才会被触发，也就是说onSingleTapUp实际上有可能时doubleTap的一次事件，如果确定只能又明确的单次点击事件触发，就需要区分
5. onDoubleTab 和 onDoubleTapEvent 之前的区别？
   - onDoubleTab 只包含down事件，而onDoubleTapEvent则还包含其他事件（move，up）









#### Scroller 详解

scroller 本身并不与View关联，仅用于做辅助的动画计算，使用起来有以下步骤：

1. 初始化
2. 通过`startScroll`或`fling`方法设定计算模型及计算所需要的参数
3. 定期调用 `computeScrollOffset` 进行运算，然后取出运算后的值
4. 使用运算后的值动态的改变View的属性实现滚动效果

##### 计算模型：

| 模型/方法       | 参数      | 含义                                                         |
| --------------- | --------- | ------------------------------------------------------------ |
| **startScroll** | startX    | 起始水平滚动偏移量（以像素为单位），正数会将内容向左滚动。   |
|                 | startY    | 开始的垂直滚动偏移量（以像素为单位）。 正数将使内容向上滚动。 |
|                 | dx        | 滑动的水平距离。 正数会将内容向左滚动。                      |
|                 | dy        | 垂直滑动距离。 正数将使内容向上滚动。                        |
|                 | duration  | 滚动持续时间（以毫秒为单位）                                 |
| **fling**       | startX    | 滚动的起点（X）                                              |
|                 | startY    | 滚动的起点（Y）                                              |
|                 | velocityX | 滚动的初始速度（X方向），以像素/秒为单位。                   |
|                 | velocityY | 滚动的初始速度（Y方向），以像素/秒为单位。                   |
|                 | minX      | 最小X值。 滚动条将不会滚动到该点。                           |
|                 | maxX      | 最大X值。 滚动条将不会滚动到该点。                           |
|                 | minY      | 最小Y值。 滚动条将不会滚动到该点。                           |
|                 | maxY      | 最大Y值。 滚动条将不会滚动到该点。                           |

##### 计算结果值

| 方法/值  | 说明                            |
| -------- | ------------------------------- |
| getCurrX | 新的X偏移量是距原点的绝对距离。 |
| getCurrY | 新的Y偏移量是距原点的绝对距离。 |
|          |                                 |

### `ScaleGestureDetector` 详解

使用提供的 MotionEvent 事件序列来检测缩放手势，当检测到对应的缩放事件时，会通过 OnScaleGestureListener 来通知用户；

使用流程：

* 为 View 创建 ScaleGestureDetector 实例；
* 在 View.onTouchEvent(MotionEvent) 方法中调用 ScaleGestureDetector 实例的 onTouchEvent 方法；

#### 基本用法

* ##### **构造函数**

| 仓库                 | 含义/作用                      |
| -------------------- | ------------------------------ |
| context              | 上下文                         |
| ScaleGestureListener | 缩放监听                       |
| Handler（可选）      | 用于运行延迟侦听事件的处理程序 |

* ##### **方法及属性** 

| 属性/方法             | 含义说明                                                     | 备注                                            |
| --------------------- | ------------------------------------------------------------ | ----------------------------------------------- |
| getCurrent**Span**    | 两个手指之间的通过手势焦点的平均距离                         | （何为平均距离？）                              |
| getCurrent**Span**X   | 形成手势的过程中两个手指之间通过手势焦点的X方向的平均距离    | 两个手指的滑动X距离相加取平均                   |
| getCurrent**Span**Y   | 形成手势的过程中两个手指之间通过手势焦点的Y方向的平均距离    | 两个手指的滑动Y距离相加取平均                   |
| getEventTime          | 返回正在处理的当前事件的事件时间                             |                                                 |
| get**Focus**X         | 当前手势焦点（gesture's focal point）的X坐标                 | 手势焦点=两个手势点的中点；双击触发时则是触摸点 |
| get**Focus**Y         | 当前手势焦点（gesture's focal point）的Y坐标                 | 两个手势点的中点                                |
| getPrevious**Span**   | 之前的 两个手指之间的通过**手势焦点**的平均距离              | 上次回调（scaleBegin/scale）的span参数          |
| getPrevious**Span**X  | 之前的 形成手势的过程中两个手指之间通过手势焦点的X方向的平均距离 |                                                 |
| getPrevious**Span**Y  | 之前的 形成手势的过程中两个手指之间通过手势焦点的Y方向的平均距离 |                                                 |
| getScaleFactor        | 从之前的缩放事件到当前缩放事件的 缩放比例                    | 两次回调之间的缩放比例                          |
| getTimeDelta          | 上一个被接受的缩放事件到当前缩放事件之前的时间差             | 两次回调之间的                                  |
| isInProgress          | 缩放手势是否正在进行中                                       | ScaleBegin 中为false，另外两个为true            |
| isQuickScaleEnabled   | 是否启用了快速缩放-用户通过双击+一个Swipe操作来触发缩放      |                                                 |
| isStylusScaleEnabled  | 返回用户使用触笔并按下按钮的触笔缩放手势是否应该执行缩放。   |                                                 |
| setQuickScaleEnabled  | 当用户执行双击+Swipe动作时是否触发缩放监听                   |                                                 |
| setStylusScaleEnabled | 当用户执行触笔缩放动作时是否触发缩放监听                     |                                                 |
| onTouchEvent          | 接受MotionEvents并在适当的时机分发事件到 OnScaleGestureListener |                                                 |

* **如何使用？**

  1. 构造侦听器对象；
  2. 在 onTouchEvent 回调中调用侦听器对象的 onTouchEvent方法并传入MotionEvent；

  ```kotlin
  var mScaleGestureDetector = ScaleGestureDetector(this,this)
  
  override fun onTouchEvent(event: MotionEvent?): Boolean {
          return mScaleGestureDetector.onTouchEvent(event) || super.onTouchEvent(event)
  }
  ```

#### 深入探究

1. 如何触发手势？
   - 两个手指张开闭合就可以
2. 如何消费手势？
3. 如何利用手势的参数实现缩放的动画/动作？

##### 如何消费手势？ 

| **事件类型**     | **CurrentSpan** | **currentSpanX** | **currentSpanY** | **EventTime** | **FocusX** | **FocusY** | **Previouspan** | **PreviouspanX** | **PreviouspanY** | **ScaleFactor** | **TimeDelta** | **isInProgress** | **isQuickScaleEnabled** | **isStylusScaleEnabled** |
| ---------------- | --------------- | ---------------- | ---------------- | ------------- | ---------- | ---------- | --------------- | ---------------- | ---------------- | --------------- | ------------- | ---------------- | ----------------------- | ------------------------ |
| **onScaleBegin** | 448.18158       | 338.30157        | 293.9707         | 120680064     | 405.82724  | 765.9927   | 448.18158       | 338.30157        | 293.9707         | 1.0             | 0             | FALSE            | TRUE                    | TRUE                     |
| **onScale**      | 448.18158       | 338.30157        | 293.9707         | 120680064     | 405.82724  | 765.9927   | 448.18158       | 338.30157        | 293.9707         | 1.0             | 0             | TRUE             | TRUE                    | true                     |
| **onScale**      | 473.83823       | 355.72217        | 313.0246         | 120680081     | 408.95367  | 770.60486  | 448.18158       | 338.30157        | 293.9707         | 1.0572461       | 17            | TRUE             | TRUE                    | true                     |
| **onScale**      | 492.1729        | 367.65485        | 327.20648        | 120680098     | 410.2758   | 772.77576  | 473.83823       | 355.72217        | 313.0246         | 1.038694        | 17            | TRUE             | TRUE                    | true                     |
| **onScale**      | 509.8993        | 380.36285        | 339.59003        | 120680114     | 411.72714  | 775.3407   | 492.1729        | 367.65485        | 327.20648        | 1.0360166       | 16            | TRUE             | TRUE                    | true                     |
| **onScale**      | 526.8072        | 391.90063        | 352.05072        | 120680131     | 413.6501   | 777.7251   | 509.8993        | 380.36285        | 339.59003        | 1.0331593       | 17            | TRUE             | TRUE                    | true                     |
| **onScale**      | 541.9916        | 402.3568         | 363.13068        | 120680147     | 415.72614  | 780.33923  | 526.8072        | 391.90063        | 352.05072        | 1.0288234       | 16            | TRUE             | TRUE                    | true                     |
| **onScale**      | 552.3365        | 408.6225         | 371.62244        | 120680164     | 418.1556   | 782.6556   | 541.9916        | 402.3568         | 363.13068        | 1.0190868       | 17            | TRUE             | TRUE                    | true                     |
| **onScale**      | 560.9881        | 413.25342        | 379.38013        | 120680181     | 418.5      | 783.56335  | 552.3365        | 408.6225         | 371.62244        | 1.0156636       | 17            | TRUE             | TRUE                    | true                     |
| **onScale**      | 567.2112        | 417.16174        | 384.32355        | 120680197     | 419.58087  | 785.08093  | 560.9881        | 413.25342        | 379.38013        | 1.011093        | 16            | TRUE             | TRUE                    | true                     |
| **onScale**      | 575.6995        | 423.24652        | 390.24646        | 120680214     | 420.5411   | 786.0411   | 567.2112        | 417.16174        | 384.32355        | 1.014965        | 17            | TRUE             | TRUE                    | true                     |
| **onScale**      | 584.7019        | 428.15033        | 398.2005         | 120680230     | 422.02505  | 788.0502   | 575.6995        | 423.24652        | 390.24646        | 1.0156373       | 16            | TRUE             | TRUE                    | true                     |
| **onScale**      | 592.25555       | 432.04736        | 405.09473        | 120680247     | 423.02368  | 789.5237   | 584.7019        | 428.15033        | 398.2005         | 1.0129188       | 17            | TRUE             | TRUE                    | true                     |
| **onScale**      | 601.86597       | 436.95844        | 413.89606        | 120680263     | 424.47922  | 791.9689   | 592.25555       | 432.04736        | 405.09473        | 1.0162268       | 16            | TRUE             | TRUE                    | true                     |
| **onScale**      | 611.9895        | 442.71814        | 422.5302         | 120680280     | 425.453    | 793.453    | 601.86597       | 436.95844        | 413.89606        | 1.0168202       | 17            | TRUE             | TRUE                    | true                     |
| **onScale**      | 621.78754       | 447.69666        | 431.49445        | 120680297     | 426.94946  | 794.94946  | 611.9895        | 442.71814        | 422.5302         | 1.0160102       | 17            | TRUE             | TRUE                    | true                     |
| **onScale**      | 629.77124       | 451.88318        | 438.64954        | 120680313     | 427.9416   | 795.4416   | 621.78754       | 447.69666        | 431.49445        | 1.0128399       | 16            | TRUE             | TRUE                    | true                     |
| **onScale**      | 636.78015       | 454.8739         | 445.6217         | 120680330     | 428.43695  | 795.93695  | 629.77124       | 451.88318        | 438.64954        | 1.0111293       | 17            | TRUE             | TRUE                    | true                     |
| **onScaleEnd**   | 644.16754       | 458.65613        | 452.31226        | 120680346     | 428.5      | 795.5      | 636.78015       | 454.8739         | 445.6217         | 1.0             | 16            | TRUE             | TRUE                    | true                     |

以下是测试过程中的detector的属性变化数据，可以发现如下规律：

1.  **onScaleBegin** 时 inProgress为false

2. currentSpan<sup>^2</sup> = currentSpanX<sup>^2</sup> * currentSpanY<sup>^2</sup> ，即currentSpan为两个手指总共移动的距离，如下图所示：

* 手指1移动的轨迹为蓝色矩形中的对角线，手指2移动的轨迹为红色矩形的对角线

<img src="https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20210224223801.png" alt="image-20210224223801886" style="zoom:50%;" />

* currentSpan 就是两个手指移动的对角线相加，currentSpanX和currentSpanY分别为蓝色矩形和红色矩形按如下方式拼接成一个大的矩形之后的两条边；

<img src="https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20210224223831.png" alt="image-20210224223831274" style="zoom:50%;" />

3. 每次事件的previouSpan的值都等于上次事件的currentSpan的值；
4. FocusX和FocusY即为事件回调触发时两个手指连线的中点坐标，随着手指的不断移动，焦点也是不断的变化的；
5. 大部分timeDelta都在16-17ms左右，所以不应在回调方法中执行耗时事件，对应逻辑应放置到Runnable中去执行；
6. scaleBegin和第一次onScale回调的各项值都一致，除了scaleBegin的isInProgress为`FALSE`；
7. 缩放比例（scaleFactor）为1.0时，没有缩放；

##### 如何利用手势的参数实现缩放的动画/动作？

假设我现在需要在检测到缩放手势时同步的对ImageView执行缩放动作，此时应该怎么做？

* 如何对ImageView的图片进行缩放？
  * 根据缩放比例不断的重新设置View的scaleX及scaleY的值；
* 每次事件触发都进行缩放操作？还是积累一定程度之后进行？
  * 由于每次变化的时间非常短，所以我们应该在每次onScale方法触发时执行变换；

## 如何让View根据手势效果进行变换？

通过之前对手势侦听器，缩放手势侦听器及滚动条类的学习及分析，我们知道了各个类的基本用途：

* GeostureDetector： 辅助侦听判断down，tag，doubletap，scroll，fling等手势并在检测到手势后回调对应的方法，给出事件相关的参数数据；
* ScaleGeostureDetector： 辅助侦听判断缩放手势，并在缩放手势发生时通过回调对应方法来通知我们对应事件的发生，并给出事件相关的参数数据；
* Scroller： 用于辅助计算生成滚动过程中的一系列值的序列；

可以方向，上述类只是告诉你事件发生了，还有告诉你事件的相关参数，如滚动事件的滚动距离，fling事件的滑动速度，等等，但是都没有涉及到如何变换将这些事件反映到界面的变化上，那么我们如何将上述的事件变化反映到界面上呢？

### View基础属性

部分变化效果都是针对View/ViewGroup来说的，要想改变View，就得改变其属性，如：

* 滑动时改变TransitionX，TransitionY
* 缩放时改变View的scaleX/scaleY

我们需要研究View中有哪些属性，属性如何影响View的展示效果，以下通过API文档的setXXX属性列出View的部分属性：

| 属性                                                    | 说明                                                         |
| ------------------------------------------------------- | ------------------------------------------------------------ |
| **alpha**                                               | 透明度                                                       |
| background/backgroundColor                              | 背景                                                         |
| **bottom<br/>left<br/>right<br/>top**<br/>**elevation** | 视图相对于parent的位置<br/>elevation为view的深度             |
| clipBounds                                              | 矩形裁剪区域，view的内容会在该区域绘制                       |
| clipToOutline:Boolean                                   |                                                              |
| fadingEdgeLength                                        | 用于指示此视图中更多内容可用的褪色边缘的大小                 |
| foreground                                              | 前景drawable                                                 |
| layoutParams                                            | 布局参数                                                     |
| minHeight<br/>minWidth                                  | 最小宽高                                                     |
| padding                                                 | 内边距                                                       |
| relativePadding                                         | 减去可能的滚动条尺寸                                         |
| **pivotX<br/>pivotY**                                   | view 旋转缩放所围绕的点。默认为view中点坐标                  |
| **rotation**                                            | 绕pivot点的旋转角度                                          |
| **rotationX<br/>rotationY**                             | 绕通过pivot点的水平线/垂直线的旋转角度                       |
| **scaleX<br/>scaleY**                                   | X/Y方向上绕pivot点的缩放比例，1.0表示无缩放                  |
| **scrollX<br/>scrollY**                                 | 水平/垂直滚动位置的position                                  |
| **translationX<br/>translationY<br/>translationZ**      | 相对于视图左边位置的水平/垂直/深度位置，可以改变布局         |
| **x/y/z**                                               | x: x位置； 等效translationX=x-left<br/>y: y位置； 等效translationY=y-top<br/>z: z位置； 等效translationZ=z-elevation |

与视图变化相关的最基本的就是加粗部分的属性，总结起来就是位置，大小，透明度，旋转，缩放，平移。其他具体的子View则可能引入自己的属性；

### 那么旋转/平移/缩放究竟改变的是啥？

* 滚动及平移（scroll/fling）：改变x和y（亦可以通过translationX/Y，最终都是改变了x和y）
* 缩放： 改变scaleX/scaleY/pivotX/pivotY



### Matrix解析

用途： matrix存储一个3x3的矩阵，用于对坐标进行变换；
$$
\begin{bmatrix}
  MSCALE\_X & MSKEW\_X & MTRANS\_X \\
  MSKEW\_Y & MSCALE\_Y & MTRANS\_Y \\
  MPERSP\_0 & MPERSP\_1 & MPERSP\_2 \\
\end{bmatrix}
$$
矩阵各个元素的用途：

| 字段                                 | 用途                                         |
| ------------------------------------ | -------------------------------------------- |
| `MSCALE_X`，`MSCALE_Y`               | 控制X轴和Y轴方向的缩放                       |
| `MSKEW_X`，`MSKEW_Y`                 | 控制X坐标和Y坐标的扭曲系数(旋转)             |
| `MTRANS_X`，`MTRANS_Y`               | 控制X方向和Y方向的线性平移                   |
| `MPERSP_0` , `MPERSP_1` , `MPERSP_2` | MPERSP_0、MPERSP_1和MPERSP_2是关于透视的控制 |

Matrix提供一系列的辅助变换函数，每种类型有 `pre`,`post`,`set`三种操作方式，矩阵的乘法运算顺序不一致结果不同，pre表示前（preconcats），post表示后（postconcats），set为直接设置；

`postScale`方法来对坐标后接触缩放变换，有两种变体：

| 方法                                                 | 说明                                                         |
| ---------------------------------------------------- | ------------------------------------------------------------ |
| `postScale (float sx, float sy, float px, float py)` | 使用指定的scale执行矩阵postconcats：`M' = S(sx, sy, px, py) * M` <br/>其中sx，sy分别为x轴和y轴的缩放大小，px，py为缩放中心点的坐标 |
| `boolean postScale (float sx, float sy)`             | 使用指定的scale执行矩阵postconcats： `M' = S(sx, sy) * M`    |

#### post和set及pre的区别

##### scale

|           | currentScale                                                 |
| --------- | ------------------------------------------------------------ |
| preScale  | 和postScale对值产生一样的效果，但是如果有其他变换一起使用，他会先于set被应用 |
| setScale  | 直接覆盖，如果matrix中原先有scale的值，那么原先的值会被覆盖  |
| postScale | 只需要设置增量即可，如原先的scale为0.5425669，postScale(1.3947428)后scale的值为 $$0.5425669*1.3947428 = 0.7567413$$ |



### Matrix如何与ImageView结合

那么我们如何才能将Matrix同ImageView或者Canvas或者Bitmap结合起来呢？

查找Canvas的相关方法，可以看到setMatrix方法，

> ```
> public void setMatrix (Matrix matrix)
> ```
>
> Completely replace the current matrix with the specified matrix. If the matrix parameter is null, then the current matrix is reset to identity. **Note:** it is recommended to use `concat(android.graphics.Matrix)`, `scale(float, float)`, `translate(float, float)` and `rotate(float)` instead of this method.

同时下面温馨提示，让我们使用其他方法，其中涉及到矩阵的就有contact，所以我们研究下contact方法：

contact方法接受一个Matrix对象，可以将参数中的矩阵预连接到canvas本身的矩阵上（Preconcat the current matrix with the specified matrix.）；假设当前矩阵为C，要连接的矩阵为S，这里的预连接（preconcat）指的是：`C = S x C`

## 单一效果实现

### 拖动效果实现

1. 初始化`GestureDetector`

   ```kotlin
   private lateinit var mDetector: GestureDetector
   
   override fun onCreate(savedInstanceState: Bundle?) {
           super.onCreate(savedInstanceState)
           mDetector = GestureDetector(this, simpleDetectorListener)
   }
   ```

2. 使用 `GestureDetector` 侦听 `onScroll` 手势

   ```kotlin
   override fun dispatchTouchEvent(ev: MotionEvent?): Boolean {
   	return mDetector.onTouchEvent(ev)
   }
   ```

3. `GestureDetector` 的 `onScroll` 回调方法中处理滚动事件

   ```kotlin
   override fun onScroll(e1: MotionEvent?, e2: MotionEvent?, distanceX: Float, distanceY: Float): Boolean {
       // 改变ImageView 的x和y
       imageView.x -= distanceX
       imageView.y -= distanceY
       return true
   }
   ```

### Fling-投掷效果实现

1. 初始化`GestureDetector`及 `Scroller`

   ```kotlin
   private lateinit var mDetector: GestureDetector
   private lateinit var mScroller: Scroller
   override fun onCreate(savedInstanceState: Bundle?) {
           super.onCreate(savedInstanceState)
           mDetector = GestureDetector(this, simpleDetectorListener)
       	mScroller = Scroller(this)
   }
   ```

2. 在onTouchEvent或dispatchTouchEvent中使用`GestureDetector` 侦听 `onFling` 手势

   ```kotlin
   override fun dispatchTouchEvent(ev: MotionEvent?): Boolean {
           return mDetector.onTouchEvent(ev)
   }
   ```

3. onFling回调中使用`Scroller `完成滚动辅助计算并从Scroller中获取参数来更新视图的x,y相关属性

   ```kotlin
   override fun onFling(e1: MotionEvent?, e2: MotionEvent?, velocityX: Float, velocityY: Float): Boolean {
           return handleFling(e1, e2, velocityX, velocityY)
   }
   
   private fun handleFling(down: MotionEvent?, move: MotionEvent?, velocityX: Float, velocityY: Float): Boolean {
           // 停止
           mScroller.forceFinished(true)
           val minX: Int = (imageView.pivotX * (1 - imageView.scaleX)).roundToInt()
           val minY: Int = (imageView.pivotY * (1 - imageView.scaleY)).roundToInt()
           val maxX: Int = ((imageView.width - imageView.pivotX) * (imageView.scaleX - 1)).roundToInt()
           val maxY: Int = ((imageView.height - imageView.pivotY) * (imageView.scaleY - 1)).roundToInt()
           mScroller.fling(imageView.x.toInt(), imageView.y.toInt(), velocityX.toInt(), velocityY.toInt(),
                   minX, maxX, minY, maxY)
           // Invalidate to request a redraw
           isFling = true
           postFling()
           return true
   }
   
   private fun postFling() {
       imageView.postDelayed(flingRunnable, 16L)
   }
   
   private val flingRunnable = Runnable {
           if (!mScroller.isFinished ) {
               // 计算滚动后的参数
               mScroller.computeScrollOffset()
               // 从滚动器中获取计算出的值并更新图片的x,y属性
               imageView.x = mScroller.currX.toFloat()
               imageView.y = mScroller.currY.toFloat()
               // 定期刷新
               postFling()
           }
   }
   ```

**View缩放后fling边界计算**

![image-20210228180521446](https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20210228180522.png)

**说明：**

1. 缩放前宽：width

2. 缩放前高：height

3. 缩放比例：scale

4. 缩放焦点坐标：focusX，focusY

5. minX = - focusX * （scale-1）

6. minY = - focusY * （scale-1）

7. maxX = （width-focusX）*（scale-1）

8. maxY = （height-focusY）*（scale-1）

### ScaleGestureDetector 实现双指缩放效果

1. 初始化 `ScaleGestureDetector` ；

   ```
       private lateinit var mScaleDetector: ScaleGestureDetector
       private val scaleDetectorListener: ScaleGestureDetector.OnScaleGestureListener = object : ScaleGestureDetector.OnScaleGestureListener {
   
           override fun onScaleBegin(detector: ScaleGestureDetector?): Boolean {
               isScaling = true
               scaleStartX = detector!!.focusX
               scaleStartY = detector.focusY
               return true
           }
   
           override fun onScale(detector: ScaleGestureDetector?): Boolean {
               Timber.tag("GestureDetector").d("handleScale onScale")
               detector?.run {
                   handleScale(detector)
               }
               return true
           }
   
   
           override fun onScaleEnd(detector: ScaleGestureDetector?) {
               Timber.tag("GestureDetector").d("handleScale onScaleEnd")
               isScaling = false
           }
       }
   ```

   

2. 事件分发时调用 `ScaleGestureDetector` 的 onTouchEvent 方法传递事件序列；

3. 在scale事件回调方法中处理scale事件-根据事件参数更新View的缩放（scaleX，scaleY）属性完成视图更新；

## 参考文章 

### matrix参考

* [Android matrix.postScale的用法](https://blog.csdn.net/maxchenfuhai/article/details/51690857)
* [Android Matrix](https://www.jianshu.com/p/a08e589ce5d4)
* [Matrix学习1、基础的知识](https://www.cnblogs.com/li-print/p/3318805.html)
* [MathJax基本的使用方式](https://blog.csdn.net/u010945683/article/details/46757757)
* [Typora Math Block](https://support.typora.io/Markdown-Reference/#math-blocks)
* [What does it mean to “preconcat” a matrix in Android?](https://stackoverflow.com/questions/2695537/what-does-it-mean-to-preconcat-a-matrix-in-android)
* [Android Matrix的pre、post理解](https://www.jianshu.com/p/7ca1d675a7c8)

### android手势

* [手势类型- Material.io](https://material.io/design/interaction/gestures.html#types-of-gestures)


