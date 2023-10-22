---
title: '鸿蒙开发基础知识'
date: 2021-11-30 10:13:11
tags: []
published: true
hideInList: false
feature: https://alliance-communityfile-drcn.dbankcdn.com/FileServer/getFile/cmtyPub/011/111/111/0000000000011111111.20210729150026.11448964563455945776572720158002:50520728101546:2800:FB99718B0883EC644C7B007DADE0F73F9A35B89CB4A68390F037D3A25D19B8B5.png?needInitFileName=true?needInitFileName=true
isTop: false
---
基于官方文档整理的鸿蒙开发的基础知识
<!-- more -->

# Ability框架

## 简介

### 整体内容

<img src="https://gitee.com/hanlyjiang/image-repo/raw/master/image/202111301012735.png" alt="image-20211028145037926" style="zoom: 50%;" />

同`Android` 对比关系：

* `FeatureAbility` - `Activity`
* `ServiceAbility` - `Service`
* `DataAbility` - `ContentProvider` 
* `CES` - 广播
* `ANS` - 通知
* 线程通信
  * `InnerEvent` - `Message`
  * `EventHandler` - `Handler`
  * `EventRunner` - `Looper`
  * `EventQueue` - `MessageQueue`



### Ability说明

同Android 单独提供 Activity，Service，ContentProvider 的基类不一样，鸿蒙这三个组件全都是继承自 Ability，那么如何区分一个Ability到底是哪种组件呢？

* 继承后实现时选择性实现对应组件的生命周期方法；

* 在 `config.json` 中定义ability时，需要声明对应的类型（page-FA；service - ServiceAbility； data - DataAbility）

  ```json
  {
      "name": "com.hanlyjiang.ohosdemo.MainJSAbility2",
      "icon": "$media:icon",
      "description": "$string:mainjsability2_description",
      "label": "$string:entry_MainJSAbility2",
      "type": "page",
      "launchType": "standard",
  },
  {
      "name": "com.hanlyjiang.ohosdemo.ServiceAbility",
      "icon": "$media:icon",
      "description": "$string:serviceability_description",
      "type": "service"
  },
  {
      "name": "com.hanlyjiang.ohosdemo.DataAbility",
      "icon": "$media:icon",
      "description": "$string:dataability_description",
      "type": "data",
      "uri": "dataability://com.hanlyjiang.ohosdemo.DataAbility"
  }
  ```

## FA（FeatureAbility）

### FA 生命周期

| 生命周期回调 | 说明                                      |
| ------------ | ----------------------------------------- |
| onStart      | 首次创建触发，仅执行一次 需要setMainRoute |
| onActive     | 进入前台可交互状态后调用                  |
| onInactive   | Page失去焦点时调用                        |
| onBackground | Page不再可见 资源释放及耗时保存操作       |
| onForeground | 重新回到前台（获得焦点 重新申请资源       |
| onStop       | 销毁页面时调用 释放系统资源               |

同`Android`对比，关系如下：

![image-20211028144542021](https://gitee.com/hanlyjiang/image-repo/raw/master/image/202111301012429.png)

| 鸿蒙         | 安卓      |
| ------------ | --------- |
| onStart      | onCreate  |
| onActive     | onResume  |
| onInactive   | onPause   |
| onBackground | onStop    |
| onForeground | onRestart |
| onStop       | onDestory |



## Service Ability

同 Android Service，没有界面，可后台运行；

但是鸿蒙可以启动/绑定远程设备上的服务（指定设备ID）。

![点击放大](https://gitee.com/hanlyjiang/image-repo/raw/master/image/202111301012611.jpg)



# UI开发框架

## ArkUI

> 官方文档： [JS FA概述](https://developer.harmonyos.com/cn/docs/documentation/doc-guides/ui-js-fa-overview-0000000000585484)


## ArkUI-JS UI

> 了解更多：
>
> * [HarmonyOS应用开发-服务开发-工具-HUAWEI DevEco Studio使用指南-工程管理-HarmonyOS工程介绍](https://developer.harmonyos.com/cn/docs/documentation/doc-guides/project_overview-0000001053822398)
> * JS API 参考：[HarmonyOS应用开发-服务开发-JS API参考-手机、平板、智慧屏和智能穿戴开发-基于JS扩展的类Web开发范式-框架说明-文件组织](https://developer.harmonyos.com/cn/docs/documentation/doc-references/js-framework-file-0000000000611396)

整体上类似 VUE & 微信小程序

### 关键词

* `AceAbility`：加载JS的Ability的基类实现
* `setInstanceName`： 指定AceAbility加载的js目录（加载多个通过此方法指定js目录）

### 项目结构

<img src="https://gitee.com/hanlyjiang/image-repo/raw/master/image/202111301012153.png" alt="image-20211027164638077" style="zoom:67%;" />

* `AceAbility` 子类（上面对应的是`MainJSAbility`）
* `default` 目录
  * `app.js` ： 全局的JavaScript逻辑文件和应用的生命周期管理
  * `pages/index.js` : JS FA(JS 界面) - ==可以有多个page==
* `config.json`： js 声明

### app.js

应用生命周期回调

```js
export default {
    onCreate() {
        console.info('AceApplication onCreate');
    },
    onDestroy() {
        console.info('AceApplication onDestroy');
    }
};
```

### index.js(JS FA)

* 页面生命生命周期回调
* 页面业务逻辑(数据绑定，事件处理等)



```js
export default {
    data: {
        title: ""
    },
    onInit() {
        console.log("JS Page onInit")
    },
    onActive(){
        console.log("JS Page onActive")
    },
    onInactive(){
        console.log("JS Page onInactive")
    },
    onShow(){
        console.log("JS Page onShow")
    },
    onHide(){
        console.log("JS Page onHide")
    },
    onDestroy(){
        console.log("JS Page onDestroy")
    }
}
```

### 生命周期

详细参考： [HarmonyOS应用开发-服务开发-JS API参考-手机、平板、智慧屏和智能穿戴开发-基于JS扩展的类Web开发范式-框架说明-生命周期](https://developer.harmonyos.com/cn/docs/documentation/doc-references/js-framework-lifecycle-0000001113708038)

![img](https://gitee.com/hanlyjiang/image-repo/raw/master/image/202111301012303.png)



```shell
OHSO_DEMO:  Application initialized
OHSO_DEMO:  MainAbility onStart
OHSO_DEMO:  MainAbility onActive

// 打开JS PAGE
OHSO_DEMO:  MainAbility onInactive
OHSO_DEMO:  MainJSAbility onStart
JSApp:  app Log: AceApplication onCreate（app.js）
OHSO_DEMO:  MainJSAbility onActive
JSApp:  app Log: JS Page onInit
JSApp:  app Log: JS Page onActive
JSApp:  app Log: JS Page onShow
OHSO_DEMO:  MainAbility onBackground

// 切换最近任务
OHSO_DEMO:  MainJSAbility onInactive
JSApp:  app Log: JS Page onInactive
OHSO_DEMO:  MainJSAbility onBackground
JSApp:  app Log: JS Page onHide

// 恢复
OHSO_DEMO:  MainJSAbility onForeground
JSApp:  app Log: JS Page onShow
OHSO_DEMO:  MainJSAbility onActive
JSApp:  app Log: JS Page onActive

// 回退（退出JS PAGE）
JSApp:  app Log: JS Page onHide
JSApp:  app Log: JS Page onDestroy
OHSO_DEMO:  MainJSAbility onInactive
OHSO_DEMO:  MainAbility onInactive
OHSO_DEMO:  MainAbility onActive
OHSO_DEMO:  MainJSAbility onBackground
OHSO_DEMO:  MainJSAbility onStop
JSApp:  app Log: AceApplication onDestroy （app.js）
```

* JS 的生命周期在Java Ability的内部。



### HML 

> HML（HarmonyOS Markup Language）是一套类HTML的标记语言。通过组件、事件构建出页面的内容。页面具备数据绑定、事件绑定、列表渲染、条件渲染等高级能力。

具体可参考： [HarmonyOS应用开发-服务开发-JS API参考-手机、平板、智慧屏和智能穿戴开发-基于JS扩展的类Web开发范式-框架说明-语法-HML语法参考](https://developer.harmonyos.com/cn/docs/documentation/doc-references/js-framework-syntax-hml-0000000000611413)



### index.CSS

参考： [HarmonyOS应用开发-服务开发-JS API参考-手机、平板、智慧屏和智能穿戴开发-基于JS扩展的类Web开发范式-框架说明-语法-CSS语法参考](https://developer.harmonyos.com/cn/docs/documentation/doc-references/js-framework-syntax-css-0000000000611425)



# 鸿蒙特性

鸿蒙特有的功能和特性，主要包括：服务卡片，流转，华为分享及平行视界。

## 服务卡片

服务卡片（以下简称“卡片”）是[FA](https://developer.harmonyos.com/cn/docs/documentation/doc-guides/glossary-0000000000029587#section5406185415236)的一种界面展示形式，将FA的重要信息或操作前置到卡片，以达到服务直达，减少体验层级的目的。服务卡片也是一个FA，只不过是显示在其他应用中的界面。

卡片常用于嵌入到其他应用（当前只支持系统应用）中作为其界面的一部分显示，并支持拉起页面，发送消息等基础的交互功能。卡片使用方负责显示卡片。

![img](https://alliance-communityfile-drcn.dbankcdn.com/FileServer/getFile/cmtyPub/011/111/111/0000000000011111111.20210729150026.11448964563455945776572720158002:50520728101546:2800:FB99718B0883EC644C7B007DADE0F73F9A35B89CB4A68390F037D3A25D19B8B5.png?needInitFileName=true?needInitFileName=true)

Java/JS卡片场景能力差异如下表所示：

| 场景                 | Java卡片                                                     | JS卡片                                                       | 支持的版本          |
| -------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------- |
| 实时刷新（类似时钟） | Java使用ComponentProvider做实时刷新代价比较大                | JS可以做到端侧刷新，但是需要定制化组件                       | HarmonyOS 2.0及以上 |
| 开发方式             | Java UI在卡片提供方需要同时对数据和组件进行处理，生成ComponentProvider远端渲染 | JS卡片在使用方加载渲染，提供方只要处理数据、组件和逻辑分离   | HarmonyOS 2.0及以上 |
| 组件支持             | Text、Image、DirectionalLayout、PositionLayout、DependentLayout | div、list、list-item、swiper、stack、image、text、span、progress、button（定制：chart 、clock、calendar） | HarmonyOS 2.0及以上 |
| 卡片内动效           | 不支持                                                       | 暂不开放                                                     | HarmonyOS 2.0及以上 |
| 阴影模糊             | 不支持                                                       | 支持                                                         | HarmonyOS 2.0及以上 |
| 动态适应布局         | 不支持                                                       | 支持                                                         | HarmonyOS 2.0及以上 |
| 自定义卡片跳转页面   | 不支持                                                       | 支持                                                         | HarmonyOS 2.0及以上 |

综上所述，==JS卡片比Java卡片支持的控件和能力都更丰富==：

- Java卡片：适合作为一个直达入口，没有复杂的页面和事件。
- JS卡片：适合有复杂界面的卡片。

### 卡片开发（[link](https://developer.harmonyos.com/cn/docs/documentation/doc-guides/ability-service-widget-provider-js-0000001150602175)）

需要通过一些参数进行配置。

1. 配置；
2. FA中实现特定的回调方法用来处理卡片的界面相关事件

> 待补充

## 服务流转

> [HarmonyOS应用开发-服务开发-专题-流转-流转架构](https://developer.harmonyos.com/cn/docs/documentation/doc-guides/hop-architecture-0000001143104837)

两种类型：

* 跨端迁移
* 多端协同

### 基本概念

- 流转：在HarmonyOS中泛指多设备分布式操作。流转能力打破设备界限，多设备联动，使用户应用程序可分可合、可流转，实现如邮件跨设备编辑、多设备协同健身、多屏游戏等分布式业务。流转为开发者提供更广的使用场景和更新的产品视角，强化产品优势，实现体验升级。流转按照体验可分为**跨端迁移**和**多端协同**。
- **跨端迁移**：一种实现用户应用程序流转的技术方案，指在A端运行的FA迁移到B端上，完成迁移后， B端FA继续任务，而A端应用退出。在用户使用设备的过程中，当使用情境发生变化时（例如：从室内走到户外或者周围有更合适的设备等），之前使用的设备可能已经不适合继续当前的任务，此时，用户可以选择新的设备来继续当前的任务。常见的跨端迁移场景实例：
  - 视频来电时从手机迁移到智慧屏，视频聊天体验更佳，手机视频应用退出。
  - 手机上阅读应用浏览文章，迁移到平板上继续查看，手机阅读应用退出。
- **多端协同**：一种实现用户应用程序流转的技术方案，指多端上的不同FA/PA同时运行、或者交替运行实现完整的业务；或者，多端上的相同FA/PA同时运行实现完整的业务。多个设备作为一个整体为用户提供比单设备更加高效、沉浸的体验。例如：用户通过智慧屏的应用A拍照后，A可调用手机的应用B进行人像美颜，最终将美颜后的照片保存在智慧屏的应用A。常见的多端协同场景实例还有：
  - 手机侧应用A做游戏手柄，智慧屏侧应用B做游戏显示，为用户组成一个全新的游戏体验。
  - 平板侧应用A做答题板，智慧屏侧应用B做直播，为用户组成一个全新的上网课体验。

#### 任务流转管理服务

在流转发起端，接受用户应用程序注册，提供流转入口、状态显示、退出流转等管理能力。流转任务管理服务提供的注册、解注册、显示设备列表、上报业务状态是实现跨端迁移的前提。

*任务流转管理服务*由一个实现了流转 `IContinuationRegisterManager` 接口的管理器提供，包括如下接口：

* `register`：注册并连接到流转任务管理服务。
* `showDeviceList`：显示组网内可选择设备列表信息。
* `updateConnectStatus`：通知流转任务管理服务更新当前用户程序的连接状态，并在流转任务管理服务界面展示给用户。
* `disconnect`：在应用退出时，主动调用断开和流转任务管理服务的连接。
* `unregister`：从流转任务管理服务解注册。

一般流程是: FA start时注册，然后显示设备列表，用户选择设备后更新连接状态。页面销毁时断开连接并解除注册。

**部分设备上有内置的流转管理服务，部分设备没有。**

- 当前仅手机、平板设备支持流转任务管理服务。
- 如果没有内置的流转任务管理服务，则需要开发者自行通过 DeviceManager 实现流转任务管理

#### [跨端迁移流程：](https://developer.harmonyos.com/cn/docs/documentation/doc-guides/hop-architecture-0000001143104837)

![点击放大](https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20211101142614.png)

> **说明**
>
> 跨端迁移后，设备A上的应用需要自行退出。

#### [多端协同流程](https://developer.harmonyos.com/cn/docs/documentation/doc-guides/hop-architecture-0000001143104837)

![点击放大](https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20211101142633.png)

> **说明**
>
> 设备A和B进行多端协同后，设备A和设备C重复如上流程，可实现设备A、B、C进行多端协同，此时设备A是中心控制点。



### 跨端迁移开发流程

#### 流程

整体流程如下：

<img src="https://alliance-communityfile-drcn.dbankcdn.com/FileServer/getFile/cmtyPub/011/111/111/0000000000011111111.20211009142428.92713305432234037812857590541318:50521008090619:2800:FA3F702E046589CA52C8B1239687350203E8377D522BB15B8B25BF2F4F6BC475.png?needInitFileName=true?needInitFileName=true" alt="img" style="zoom:67%;" />

#### 限制

- 每个应用注册流转任务管理服务的`Ability`数量上限为5个，后续新增注册的Ability会将最开始注册的覆盖。
- 一个应用可能包含多个FA，仅需要在支持跨端迁移的FA及其所包含的`AbilitySlice`中，调用或实现相关接口。
- 跨端迁移不支持两个设备之间分别登录不同的帐号，也就是要求多个设备是同帐号。
- **跨端迁移不支持对PA的迁移，只支持对FA的迁移**。
- 跨端迁移完成时，系统不会主动关闭发起迁移的FA，开发者可以根据业务需要，主动调用`terminateAbility`或`stopAbility`关闭FA，并调用`updateConnectStatus()`更新设备的连接状态。
- 通过`continueAbility`进行跨端迁移过程中，远端FA首先接收到发起端FA传输的数据，再执行启动，即`onRestoreData()`发生在`onStart()`之前。
- **跨端迁移的数据大小限制200KB以内，即`onSaveData`只能传递200KB以内的数据。**
- 迁移传输的数据，当前仅支持基础类型数据传递和系统`Sequenceable`对象，不支持自定义对象及文件数据传递。
- FA流转过程中，在流转未完成时再次调用`continueAbility`发起流转，接口将会抛出状态异常，应用需要加以限制处理。
- 跨端迁移要求HarmonyOS 2.0以上版本才能支持，注册到流转任务管理服务时jsonParams中需要增加`{"harmonyVersion":"2.0.0"}`过滤条件。



### 多端协同开发流程

#### 流程

相对跨端迁移，多了 DeviceManager 的参与，用于初始化和关闭分布式环境。另外，跨端迁移只涉及FA，而多端协同需要PA参与。

![img](https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20211102112816.png)



协同实际上的流程就是，通过startAbility 启动FA，及PA，通过connectAbility连接到PA，然后通过远程PA来进行协作。

#### 限制



- 每个应用注册流转任务管理服务的Ability数量上限为5个，后续新增注册的Ability会将最开始注册的覆盖。
- **startAbility、connectAbility中跨设备传递的intent数据大小限制200KB以内。**
- 不支持使用connectAbility触发远端PA的免安装。
- **connectAbility中跨设备传递的remoteObject数据大小限制200KB以内。**
- 多端协同要求HarmonyOS 2.0以上版本才能支持，注册到流转任务管理服务时jsonParams中需要增加{"harmonyVersion":"2.0.0"}过滤条件。
- stopAbility不支持两个设备之间分别登录不同的帐号，也就是要求多个设备是同帐号。

### 示例

参考官方示例：

* [ability/DistributedScheduler · HarmonyOS/harmonyos_app_samples - 码云 - 开源中国 (gitee.com)](https://gitee.com/harmonyos/harmonyos_app_samples/tree/master/ability/DistributedScheduler)
* [HarmonyOS应用开发-服务开发-专题-流转-HarmonyOS端发起多端协同-多端协同开发指导](https://developer.harmonyos.com/cn/docs/documentation/doc-guides/hop-multi-device-collaboration-guidelines-0000001139737211#section27065313575)





# 其他


## 日志输出

### HiLog

```java
    static final HiLogLabel label = new HiLogLabel(HiLog.LOG_APP, MY_MODULE, "MY_TAG"); //MY_MODULE=0x00201
    HiLog.warn(label, "Failed to visit %{private}s, reason:%{public}d.", url, errno);
```

输出如下：

```shell
Result: 05-26 11:01:06.870 1051 1051 W 00201/test: Failed to visit <private>, reason:503.
```

> 注意： <private> 隐藏了本该被输出的 url 



## 对应概念/类

* `LayoutBoost` -> `LayoutInflater`

## 常见问题

### 隐藏 ActionBar 

将如下配置段添加到 module 中，或者添加到 ability 中。

```json
	"metaData": {
          "customizeData": [
            {
              "name": "hwc-theme",
              "value": "androidhwext:style/Theme.Emui.Light.NoTitleBar"
            }
          ]
    }
```

> 按理应该提供直接对Ability设置主题的配置方式，但是不知道配置项。



## HDC 使用

hdc 路径： `$USER_HOME/Library/Huawei/sdk/toolchains/`

* 查看帮助： `hdc help`

  一般用法如下：

  ```shell
  hdc [options] <command> [arguments]
  ```

* 查看设备列表： `hdc list targets -v `

* 查看日志： hilog

  ```
  hdc hilog | grep com.hanlyjiang.ohosdemo
  ```

* 查看可调试应用PID列表： `hdc listpid`



### 使用手机内的`android`命令

使用 hdc shell 进入手机shell环境，然后可执行对应的android命令



如下，通过`dumpsys activity services -p com.hanlyjiang.ohosdemo`可以看到实际上 鸿蒙为我们的 `com.hanlyjiang.ohosdemo.pa.ServiceAbility` 生成了一个对应的shellService（`com.hanlyjiang.ohosdemo/.pa.ServiceAbilityShellService`）

```shell
$ dumpsys activity services -p com.hanlyjiang.ohosdemo
ACTIVITY MANAGER SERVICES (dumpsys activity services)
  User 0 active services:
  * ServiceRecord{b2375c9 u0 com.hanlyjiang.ohosdemo/.pa.ServiceAbilityShellService}
    intent={pkg=com.hanlyjiang.ohosdemo cmp=com.hanlyjiang.ohosdemo/.pa.ServiceAbilityShellService}
    packageName=com.hanlyjiang.ohosdemo
    processName=com.hanlyjiang.ohosdemo
    baseDir=/data/app/com.hanlyjiang.ohosdemo-XmLCnshi-zSpv76TYXTvwA==/base.apk
    dataDir=/data/user/0/com.hanlyjiang.ohosdemo
    app=ProcessRecord{b340b59 7888:com.hanlyjiang.ohosdemo/u0a191}
    createTime=-10m43s889ms startingBgTimeout=--
    lastActivity=-10m43s889ms restartTime=-10m43s889ms createdFromFg=true
    startRequested=true delayedStop=false stopIfKilled=true callStart=true lastStartId=1
```