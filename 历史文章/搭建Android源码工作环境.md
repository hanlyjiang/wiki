---
title: '搭建Android源码工作环境'
date: 2021-04-08 10:18:50
tags: [Android,源码分析]
published: true
hideInList: false
feature: 
isTop: false
---


* 简单介绍系统架构、编译环境的搭建
* 简单介绍利用 AndroidStudio 调试 system_process 进程的方法及编译更新部分系统模块的方式

<!-- more -->


## Android系统架构

Android 系统架构如下两图所示：

![20210401092831](https://s2.loli.net/2022/05/26/iVWSvDPlA9I4afd.png)

![20210401092925](https://s2.loli.net/2022/05/26/3KYlCuj5zXc9EUs.png)

<?xml version="1.0" encoding="UTF-8"?>



- **应用框架**。应用框架最常被应用开发者使用。很多此类 API 都可以直接映射到底层 HAL 接口，并可提供与实现驱动程序相关的实用信息。
- **Binder IPC**。Binder 进程间通信 (IPC) 机制允许应用框架跨越进程边界并调用 Android 系统服务代码，这使得高级框架 API 能与 Android 系统服务进行交互。在应用框架级别，开发者无法看到此类通信的过程，但一切似乎都在“按部就班地运行”。
- **系统服务**。系统服务是专注于特定功能的模块化组件，例如窗口管理器、搜索服务或通知管理器。应用框架 API 所提供的功能可与系统服务通信，以访问底层硬件。Android 包含两组服务：“系统”（诸如窗口管理器和通知管理器之类的服务）和“媒体”（与播放和录制媒体相关的服务）。
- **硬件抽象层 (HAL)**。HAL 可定义一个标准接口以供硬件供应商实现，这可让 Android 忽略较低级别的驱动程序实现。借助 HAL，硬件开发者可以顺利实现相关功能，而不会影响或更改更高级别的系统。HAL 实现会被封装成模块，并会由 Android 系统适时地加载。如需了解详情，请参阅[硬件抽象层 (HAL)](https://source.android.google.cn/devices/architecture/hal?hl=zh-cn)。
- **Linux 内核**。开发设备驱动程序与开发典型的 Linux 设备驱动程序类似。Android 使用的 Linux 内核版本包含一些特殊的补充功能，例如低内存终止守护进程（一个内存管理系统，可更主动地保留内存）、唤醒锁定（一种 [`PowerManager`](https://developer.android.google.cn/reference/android/os/PowerManager.html?hl=zh-cn) 系统服务）、Binder IPC 驱动程序，以及对移动嵌入式平台来说非常重要的其他功能。这些补充功能主要用于增强系统功能，不会影响驱动程序开发。可以使用任意版本的内核，只要它支持所需功能（如 Binder 驱动程序）即可。不过建议使用 Android 内核的最新版本。如需了解详情，请参阅[构建内核](https://source.android.google.cn/setup/building-kernels?hl=zh-cn)一文。

> 以上部分内容来源： https://source.android.google.cn/devices/architecture?hl=zh-cn

## 搭建开发环境并编译源码

本节将讨论 Android 11 源码下载和编译的方法、AndroidStudio开发环境的搭建方法，及 system_process 进程的调试方法等相关知识。

### 选择分支

可参考 source.android.google.cn 的文档 [代号、标记和 Build 号](https://source.android.google.cn/setup/start/build-numbers) ，可以看到当前最新的版本及标记如下：

| Build           | 标记               | 版本      | 支持的设备                                                   | 安全补丁程序级别 |
| :-------------- | :----------------- | :-------- | :----------------------------------------------------------- | :--------------- |
| RQ2A.210305.007 | android-11.0.0_r33 | Android11 | --                                                           | --               |
| RQ1D.210105.003 | android-11.0.0_r28 | Android11 | Pixel 3、Pixel 3 XL、Pixel 4a (5G)、Pixel 5                  | 2021-01-05       |
| RQ1A.210105.003 | android-11.0.0_r27 | Android11 | Pixel 3、Pixel 3 XL、Pixel 4、Pixel 4a (5G)、Pixel 4 XL、Pixel 5 | 2021-01-05       |
| RQ1A.210105.002 | android-11.0.0_r26 | Android11 | Pixel 3a、Pixel 3a XL、Pixel 4a                              | 2021-01-05       |

参考代码仓库中的[最新Tag](https://android.googlesource.com/platform/bionic/+/refs/tags/android-11.0.0_r33)，我们选择 `android-11.0.0_r33`

### 搭建Android构建环境

构建环境的搭建可参考官方的 [搭建构建环境](https://source.android.google.cn/setup/build/initializing) 文档，以下结合实际搭建过程中遇到的问题简要进行介绍。

#### 构建环境要求

首先需要机器满足一些[要求](https://source.android.google.cn/setup/build/requirements)，一般来说，需要：

* 操作系统： Linux 或者 macOS
* 内存： 16GB的可用RAM/交换空间
* 硬盘： 检出代码至少250GB可用磁盘空间，如果需要构建，则还需要150GB

从Android8.0 开始，可以使用源码中带的Dockerfile来构建一个镜像用于编译aosp源码；下面我们将分别介绍如何构建编译用的Docker镜像及直接在macOS11.2上搭建构建环境，构建时根据情况任选一种即可。

> 提示：
>
> 最新的构建要求可以参考官方文档 [aosp源码构建要求](https://source.android.google.cn/setup/build/requirements)

#### 搭建构建环境-Docker

> docker镜像基于ubuntu:18.04，所以ubuntu上也可以按照dockerfile中的命令配置环境

这里假设安装了Docker，如果没有安装，可以参考[Docker官方安装文档](https://docs.docker.com/engine/install/)进行安装。

```shell
mkdir docker
cd docker
```

将如下内容保存为Dockerfile，并存储到之前建立的docker目录

```dockerfile
FROM ubuntu:18.04

ARG userid
ARG groupid
ARG username

RUN apt-get update \
    && apt-get install -y git-core gnupg flex bison build-essential zip \
    curl zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 lib32ncurses5-dev \
    x11proto-core-dev libx11-dev lib32z1-dev libgl1-mesa-dev libxml2-utils xsltproc unzip fontconfig \
    python3 \
    && rm -rf /var/lib/apt/lists/* 
    
# 最新的AOSP源码中已经带了JDK，所以无需安装
# RUN curl -o jdk8.tgz https://android.googlesource.com/platform/prebuilts/jdk/jdk8/+archive/master.tar.gz \
#  && tar -zxf jdk8.tgz linux-x86 \
#  && mv linux-x86 /usr/lib/jvm/java-8-openjdk-amd64 \
#  && rm -rf jdk8.tgz

RUN curl -o /usr/local/bin/repo https://storage.googleapis.com/git-repo-downloads/repo \
 && chmod a+x /usr/local/bin/repo \
 && ln -s /usr/bin/python3 /usr/bin/python

RUN groupadd -f -g $groupid $username || true \
 && useradd -m -u $userid -g $groupid $username \
 && echo $username >/root/username \
 && echo "export USER="$username >>/home/$username/.gitconfig
COPY gitconfig /home/$username/.gitconfig
RUN chown $userid:$groupid /home/$username/.gitconfig
ENV HOME=/home/$username
ENV USER=$username
ENTRYPOINT chroot --userspec=$(cat /root/username):$(cat /root/username) / /bin/bash -i
```

> 以上dockerfile基于源码中 `build/make/tools/docker/Dockerfile` 修改

**构建镜像：**

```shell
# Copy your host gitconfig, or create a stripped down version
$ cp ~/.gitconfig gitconfig
$ docker build --build-arg userid=$(id -u) --build-arg groupid=$(id -g) --build-arg username=$(id -un) -t android-build-bionic .
```

**使用镜像：**

> 可以直接使用我已经构建好的镜像： `hanlyjiang/android-build-bionic`，可以使用如下命令拉取并修改tag：
>
> `docker pull hanlyjiang/android-build-bionic`
>
> `docker tag hanlyjiang/android-build-bionic android-build-bionic:latest`

假设aosp的源码目录位于 ～/aosp

```shell
# 设置变量指向源码顶层目录
ANDROID_BUILD_TOP=~/aosp
# 如自行构建镜像，此处
BUILD_IMAGE=android-build-bionic
cd $ANDROID_BUILD_TOP
# 运行容器，并将aosp源码目录挂载到容器内部的/src目录
docker run -it --rm --name aosp-builder -v $PWD:/src $BUILD_IMAGE
```

启动成功后就会进入容器的shell中，之后在容器中进行执行对应的编译命令即可。

> **docker使用提示：**
>
> 1. 上面的`docker run `命令中添加了 `--rm` 选项，在启动的交互式bash结束后就会自动移除容器。之后需要再次输入`docker run`命令启动容器；为了避免每次都输入如上命令启动容器，可以移除`--rm` 选项
> 2. 我们执行构建一般需要较长时间，期间如果我们退出容器的bash，则构建任务会终止，这显然不是我们想要的，我们可以通过 `ctrl+P ctrl+Q` 命令告诉docker我们需要关闭容器到本机的输入输出重定向，但是并不暂停任何执行的任务。之后再使用 `docker attach aosp-builder`（aosp-builder是我们启动时指定的容器名称） 即可重新将容器输入输出重定向到本机终端，继续与容器内的shell交互。

#### 搭建构建环境-macOS11.2

这里介绍下macOS（x86）编译的环境配置

1. 准备源码目录

   由于macOS默认的分区是不区分大小写的，但是aosp编译需要区分大小写，所以需要创建一个区分大小写的分区，这里可以有两种选择：

   1）使用另外一个磁盘（如外置的移动硬盘），然后使用磁盘工具将其抹掉为区分大小写的分区；

   2）创建一个区分大小写的磁盘映像，可通过如下命令执行

   ```shell
   hdiutil create -type SPARSE -fs 'Case-sensitive Journaled HFS+' -size 250g ~/android.dmg.sparseimage
   
   # 定义装载卸载函数
   mountAndroid() { hdiutil attach ~/android.dmg.sparseimage -mountpoint /Volumes/android; }
   umountAndroid() { hdiutil detach /Volumes/android; }
   # 装载刚刚创建的磁盘映像到 /Volumes/android 目录，之后cd 到此目录执行即可
   mountAndroid
   ```

2. 安装 xcode 命令行工具

   ```shell
   xcode-select --install
   ```

3. 设置bash

   ```shell
   # 可加入到～/.bash_profile 文件中
   ulimit -S -n 2048
   ```

4. 下载 10.15 SDK

   从此处下载： https://github.com/phracker/MacOSX-SDKs/releases

   下载完成后放入到此目录：`/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/`

5. 修复代码（在下载完成源码之后执行）

   * 编辑文件 `system/core/base/cmsg.cpp`

   * 添加一行：`size_t psize = getpagesize();`

     ```cpp
     namespace base {
         
     size_t psize = getpagesize();
         
     ssize_t SendFileDescriptorVector(borrowed_fd sockfd, const void* data, size_t len,
     ```

   * 将文件中所有 **PAGE_SIZE** 替换为 **psize**

> 参考：
>
> * [Building Android 11 for PH-1 on Apple Silicon](https://nf4789.medium.com/building-android-11-for-ph-1-on-apple-silicon-6600436a36a0)
> * [Could not find a supported mac sdk: “10.10” “10.11” “10.12” “10.13”](https://stackoverflow.com/questions/50760701/could-not-find-a-supported-mac-sdk-10-10-10-11-10-12-10-13)
> * [创建区分大小写的磁盘映像-source.android.google.cn](https://source.android.google.cn/setup/build/initializing?hl=zh-cn#creating-a-case-sensitive-disk-image)

### 下载源码

#### 安装Repo

> 提示： 先前构建的docker镜像中已经安装了repo，如使用镜像，可跳过此步骤

```shell
mkdir ~/.bin
PATH=~/.bin:$PATH

# 这里可能需要开启代理
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo

# 验证是否安装成功
repo help
```

输出如下则表示安装成功：

```shell
usage: repo COMMAND [ARGS]

repo is not yet installed.  Use "repo init" to install it here.

The most commonly used repo commands are:

  init      Install repo in the current working directory
  help      Display detailed help on a command

For access to the full online help, install repo ("repo init").
```

#### 获取aosp源码底包

```shell
wget https://mirrors.tuna.tsinghua.edu.cn/aosp-monthly/aosp-latest.tar
# 解压
tar xf aosp-latest.tar
```

或者直接下载：

```shell
mkdir aosp ; cd aosp 
repo init -u https://android.googlesource.com/platform/manifest -b android-11.0.0_r33
```

然后执行代码同步命令：

```shell
repo sync -c -j16
```

> repo sync 命令说明： 
>
> * 通过 `-c` 指定只获取当前分支
> * 通过 `-j16` 指定并行获取的线程数量，这里我电脑为8核，所以指定了16个线程

> **提示：**
>
> 代码下载完成后，我们复制一份到另外一个目录只用于浏览代码 `rsync -a -H --progress aosp aosp-ro`

### 编译源码

首先， 我们使用 repo 启动一个工作分支

```shell
repo start dev_android11_r33 --all
```

初始化环境：

```shell
source build/envsetup.sh
```

`envsetup.sh` 脚本会导入若干命令，可使用 `hmm` 查看完整的可用命令列表。

选择目标：

```shell
lunch aosp_x86_64-eng
```

输出如下：

```shell
$ lunch aosp_x86_64-eng
============================================
PLATFORM_VERSION_CODENAME=REL
PLATFORM_VERSION=11
TARGET_PRODUCT=aosp_x86_64
TARGET_BUILD_VARIANT=eng
TARGET_BUILD_TYPE=release
TARGET_ARCH=x86_64
TARGET_ARCH_VARIANT=x86_64
TARGET_2ND_ARCH=x86
TARGET_2ND_ARCH_VARIANT=x86_64
HOST_ARCH=x86_64
HOST_OS=darwin
HOST_OS_EXTRA=Darwin-20.3.0-x86_64-11.2.3
HOST_BUILD_TYPE=release
BUILD_ID=RQ2A.210305.007
OUT_DIR=out
PRODUCT_SOONG_NAMESPACES=device/generic/goldfish device/generic/goldfish-opengl hardware/google/camera hardware/google/camera/devices/EmulatedCamera device/generic/goldfish device/generic/goldfish-opengl
```

构建：

```shell
make -j16
```

> 提示：构建命令可参考 [官方文档-编译 Android](https://source.android.google.cn/setup/build/building)

构建成功后输出如下：

```shell
[100% 119047/119047] Create system-qemu.img now
removing out/target/product/generic_x86_64/system-qemu.img.qcow2
out/host/darwin-x86/bin/sgdisk --clear out/target/product/generic_x86_64/system-qemu.img

#### build completed successfully (14:34:15 (hh:mm:ss)) ####
```

我们这里使用模拟器进行运行

```shell
emulator
```

运行起来之后，查看其中的系统版本号如下：

![20210403135316](https://s2.loli.net/2022/05/26/ts1xnl2L35HBmeY.png)

## 使用AndroidStudio调试 `system_process`

本小节介绍如何使用AS来调试Android Java Framework的核心进程 system_process。

### 下载安装AndroidStudio

从[AndroidStudio官方页面](https://developer.android.google.cn/studio)下载安装运行即可

### 生成AS项目配置

总的流程如下：

* 全量编译一次aosp源码
* 编译`development/tools/idegen` 生成 `idegen.jar` 文件；
* 使用`development/tools/idegen/idegen.sh` 生成AS项目配置
* 使用AndroidStudio打开生成的配置，导入源码项目

其中 `idegen.sh` 仅是简单的使用java执行idegen.jar，idegen.jar 会在源码根目录生成androidstudio使用的两个文件，即`android.iml`和`android.ipr`，生成过程中会读取 `excluded-paths` 文件，该文件中可以使用正则表达式定义过滤规则，该文件会从三个路径去读取：

* `development/tools/idegen/excluded-paths`
* `vendor/google/excluded-paths`
* 源码根目录的 `excluded-paths`

所以我们只需要将自己的过滤规则定义到源码根目录的 `excluded-paths`文件中即可。

`android.iml` 中有三种xml配置: 

1）`sourceFolder`;

2) `excludeFolder`;

3) `orderEntry`; 

idegen.jar 在执行时会根据配置的规则自动写入这三种规则，其中sourceFolder用于指定源码目录-即as会将其作为源码导入，excludeFolder用于指定排除目录-即as压根不会去搜索任何文件，也不会对其中的文件建立索引，orderEntry 则一般用于指定依赖的jar文件；

在idegen.jar的逻辑中：

* 没有被过滤规则匹配到的目录都会尝试去其中搜寻java及jar文件，只有在其中找到了源码文件，才会被加入到sourceFolder中。
* 过滤规则中配置的目录，只有其中有java及jar文件时，才会被加入到excludeFolder配置中。
* 如果目录中找到了java文件，会去读取java文件，自动确认sourceFolder的开始路径，以保证路径能正确匹配包名，如：有个目录`de vice/test/src/java/android/Test.java`，其中Test.java的包为android，那么sourceFolder的路径会自动设置为`de vice/test/src/java/`。

#### 修改idegen代码并编译idegen.jar

修改 `development/tools/idegen` 模块代码及配置

1. `src/Log.java` 为了方便我们查看生成的过程，打开debug日志开关

   ```java
   class Log {
   
       static final boolean DEBUG = true;
       
       // ...
   }
   ```

2. `src/IntelliJ.java` , 这里由于代码中书写错误，prebuilt 实际上在源码中并不存在，我们手动将其修改为 `prebuilts`

   ```java
           sourceRootsXml.append("<excludeFolder url=\"file://$MODULE_DIR$/out/target/product\"/>\n");
   // 修改这一行 prebuilt --> prebuilts
           sourceRootsXml.append("<excludeFolder url=\"file://$MODULE_DIR$/prebuilts\"/>\n");
   
   ```

3. 编译生成 idegen.jar

   ```shell
   # 在源码根目录执行
   source build/envsetup.sh
   cd development/tools/idegen
   mm -j16
   ```

   成功生成后输出如下：

   ```shell
   [100% 228/228] Install: out/host/darwin-x86/framework/idegen.jar
   #### build completed successfully (05:30 (mm:ss)) ####
   ```



#### 手动获取java文件

##### 手动获取AIDL生成的java文件

我们通过如下命令将aidl生成的java文件拷贝到 源码根目录的`idea/aidl/src`目录下

```shell
croot
mkdir -p idea/aidl/src
find out/soong/.intermediates/frameworks/base/api-stubs-docs-non-updatable/android_common/gen/aidl -name "*.srcjar" | xargs -I {} unzip {} -d idea/aidl/src
```

##### 获取生成的资源

```shell
cp -R out/soong/.intermediates/frameworks/base/core/res/framework-res/android_common/gen/aapt2/R idea/framework-res_R
```



#### 编辑排除规则并生成配置

1. 在项目根目录中添加一个 `excluded-paths` 文件，输入如下内容（一行作为一个匹配规则，规则的格式按Java中Pattern类的规则编写）

   ```shell
   # 几个根目录的规则
   ^art/.*
   ^packages/.*
   ^bootable/.*
   ^build/.*
   ^cts/.*
   ^dalvik/.*
   ^developers/.*
   ^external/.*
   ^platform_testing/.*
   ^pdk/.*
   ^sdk/.*
   ^system/.*
   ^test/.*
   
   # platform-compat中有注解的类
   ^tools/(?!(platform-compat))
   ^development/.*
   ^device/.*
   ^prebuilts/*
   
   # 这里我们查看这两个模块，所以注释掉
   #^libcore/.*
   #^frameworks/.*
   # 关于out其他的一些规则
   ^out/soong/.intermediates/(?!((frameworks)|(libcore)))
   # ./out/soong/.intermediates/frameworks/native/libs/binder/libbinder/android_x86_64_shared/gen/aidl/android/os/BnServiceManager.h
   # ^out/soong/.intermediates/.*
   ^out/target/.*
   
   # 根据实际运行情况补充的规则
   # 移除可能的jar
   # 如 ./frameworks/base/tools/aapt2/integration-tests/CommandTests/android-28.jar
   ^frameworks/base/tools/aapt2/.*\.jar
   ^frameworks/base/tests
   ^libcore/support/src/test
   ^libcore/luni/src/test
   gradle-wrapper.jar
   
   # 对于sdk源码的隐藏，我们exclude掉，以使可以找到真正的源码
   ^libcore/ojluni/annotations
   ```

2. 生成iml文件，执行下面命令生成

   ```shell
   development/tools/idegen/idegen.sh
   ```

   完成后根目录下即生成了`android.iml`,`android.ipr` 

### 导入到AndroidStudio

#### androidstudio 配置

1. 配置jvm选项，根据机器实际情况设置vm分配的内存策略

   ![20210402093304](https://s2.loli.net/2022/05/26/Iubf2vnAUeSt5T9.png)

   ```shell
   -Xmx16g
   -Xms2g
   ```

2. 配置 idea 属性

   ![20210401212321](https://s2.loli.net/2022/05/26/3YAvO65PCwjS971.png)

   ```shell
   # 大小写敏感（macOS）
   idea.case.sensitive.fs=true
   
   idea.max.intellisense.filesize=100000
   ```

#### 导入项目到AS并配置

配置sdk主要是为了避免查看或调试代码时，AS仍然去使用SDK中配置的class，而不是我们的aosp中的java源码。

1. 使用AndroidStudio 打开项目根目录下 `android.ipr` 文件即可导入项目；

2. 配置项目SDK，进入项目设置，添加一个新的JDK，并删除所有依赖jar库，我们这里取名为：`1.8 (No Libraries)`

   ![20210402095209](https://s2.loli.net/2022/05/26/IW7d3v2iURTSrHx.png)

3. 配置项目SDK，进入项目设置，添加一个新的SDK，并删除所有jar库，对应的JDK选择之前创建的`1.8 (No Libraries)`，这里我们将SDK命名为 `Android API 30 Platform-NoLib`

   ![20210402095255](https://s2.loli.net/2022/05/26/zZqhWtRMxOf6j9w.png)

4. 在Project设置中，选择项目SDK为之前设置的 `Android API 30 Platform-NoLib`

   ![20210402095343](https://s2.loli.net/2022/05/26/pPBC8DeMZQH2Sm5.png)

5. 进入项目设置-模块设置，将模块的SDK设置为之前设置的  `Android API 30 Platform-NoLib` 

   ![20210402095449](https://s2.loli.net/2022/05/26/q6RfQivmWCVpy1b.png)

#### 附加调试器到 system_process 

1. 附加调试器到 `system_process` 进程

![20210402093915](https://s2.loli.net/2022/05/26/BCe1wSr2mcDNIhW.png)

![20210402095736](https://s2.loli.net/2022/05/26/EdqxcUp4PvIwKza.png)

2. 成功后的Debugger界面如下所示

   ![20210402100639](https://s2.loli.net/2022/05/26/UFs6MnaOcGKPdJm.png)

3. 打断点测试，这里我们选择在 `Binder.java` 文件中添加断点，然后在模拟器中打开相机APP以触发断点逻辑。下图就表示我们到达了断点，说明我们可以通过AS来调试该进程了。

   ![20210402101258](https://s2.loli.net/2022/05/26/jK9lUkJWfr1xc34.png)

> 提示：附加调试器时，如找不到设备，可参考第5小节中的 *错误解决：Debug中不显示设备*

## 修改并更新系统模块

在调试分析过程中，可能我们需要修改一下其中内容以协助分析，可以按如下方式进行。

### Framework

构建 framework 分两块：

1. JAR 部分使用命令 `mmm frameworks/base/`
2. 资源部分： `mmm frameworks/base/core/res/`

**安装：**

```shell
# 获取root权限
adb root
adb disable-verity
adb reboot
adb remount
# 移除旧的framework
adb shell
cd /system/framework/
rm framework-res.apk
exit

# 推入新的framework
adb push out/target/product/<device_targeted>/system/framework/framework-res.apk /system/framework/

# 重启服务
adb reboot
```

### packages中app

* 构建

```shell
cd ~/aosp
source build/envsetup.sh 
lunch aosp_x86_64-eng
# 重新构建单个模块 (如 Dialer)
mmm packages/apps/dialer/
# 生成的文件会在控制台中输出来
```

* 更新到系统

```shell
adb install -r out/target/product/<device_targeted>/system/priv-app/<app_name>/<app_name>.apk
adb reboot
```

### SystemUI

* 编译

```shell
cd WORKING_DIRECTORY
source build/envsetup.sh
# 选择设备
lunch 31
# 重新构建SystemUI
mmm frameworks/base/packages/SystemUI/
```

* 安装到系统

```shell
adb install -r out/target/product/<device_targeted>/system/priv-app/SystemUI/SystemUI.apk
adb reboot
```



## 使用提示及常见错误

### 使用提示：项目源码浏览配置

#### 筛选Project代码范围

1. 点击project窗口的设置按钮，选择 “Edit Scopes”

   ![20210402104239](https://s2.loli.net/2022/05/26/b54fWpm6liduwHo.png)

2. 新建一个规则，输入名称，并在Pattern中输入过滤规则： `file[android]:frameworks//*||file[android]:libcore//*`

   ![20210402104205](https://s2.loli.net/2022/05/26/O6ulDULrbK8nfPQ.png)

#### 过滤VCS配置中不必要的模块

打开VCS配置，移除frameworks和libcore之外的所有其他模块

![20210402105446](https://s2.loli.net/2022/05/26/4MUamSB37LQDThN.png)

### 使用提示：导入其他模块的源码到AS

不建议直接修改 android.iml 文件，应当通过修改源码根目录自定义的 `excluded-paths` 文件中定义的规则来包含其他模块的源码。

修改此文件后，重新执行 `development/tools/idegen/idegen.sh` 来生成最新的as项目配置。生成完成后一般as如果是打开状态，会自动更新索引，如果索引更新有问题，可关闭项目，然后重新打开。

### 错误解决：macOS .DS_Store 导致打包镜像失败

编译基本完成，但是最后打包system.img文件时报错，报错内容如下：

```shell
set_selinux_xattr: No such file or directory searching for label "/.DS_Store"
e2fsdroid: No such file or directory while configuring the file system

10:00:38 ninja failed with: exit status 1
```

解决方式：删除源码目录中的所有 `.DS_Store`，可通过如下命令进行统一清理

```shell
find . -name ".DS_Store"  | xargs -I {} rm {} 
```

> 说明： .DS_Store 文件为macOS中存储文件夹界面展示相关的一些信息，在Finder中查看对应目录后可能会生成

### 错误解决：附加调试器时不显示设备

在附加调试器时，可能会如下图一样，模拟器已经启动了，但是附加调试器的窗口中设备列表中没有设备

![20210402121454](https://s2.loli.net/2022/05/26/8UdS9MZ3rnAl6mi.png)

此时检查自己的项目配置中的SDK是否选择了AndroidSDK，设置成 Android SDK 即可

![20210402121537](https://s2.loli.net/2022/05/26/yKgSVda9RWo8Jnp.png)



### 错误解决：模拟器无法启动-报找不到内核版本信息

当使用 `android-11.0.0_r28` 版本时，编译通过后，使用emulator启动时，报出如下错误

```shell
emulator: ERROR: Can't find 'Linux version ' string in kernel image file: /Volumes/HIKVISION/google-aosp/out/target/product/generic_x86_64/kernel-ranchu
```

原因是emulator版本过旧，需要使用新的emulator，执行如下命令获取新的版本：

```shell
cd prebuilts/android-emulator
# 查询可用分支，https://android.googlesource.com/platform/prebuilts/android-emulator/+refs
git fetch aosp android-11.0.0_r33:refs/remotes/m/android-11.0.0_r33
# 检出分支
git co -b android-11.0.0_r33 refs/remotes/m/
android-11.0.0_r33
```

获取完成后再次执行 `emulator` 命令

```shell
emulator -version
# Android emulator version 30.3.0.0 (build_id 6946397) (CL:N/A)
emulator 
# 启动模拟器
```

## 参考文章

**参考：** 

* [使用 Android Studio 阅读 AOSP 源码](https://blog.devwu.com/2019/06/23/how-to-reading-AOSP-with-Android-Studio/)
* [AOSP Source Code in Android Studio (Explore only)](https://param105.medium.com/aosp-source-code-in-android-studio-explore-only-1cdc3081cf51)
* [Stackoverflow aosp-and-intellij-idea](https://stackoverflow.com/questions/16582112/aosp-and-intellij-idea)
* [Building Android O with a Mac - Christopher Ney](https://medium.com/@christopherney/building-android-o-with-a-mac-da07e8bd94f9)
* [Building Android 11 for PH-1 on Apple Silicon](https://nf4789.medium.com/building-android-11-for-ph-1-on-apple-silicon-6600436a36a0)
* [Could not find a supported mac sdk: “10.10” “10.11” “10.12” “10.13”](https://stackoverflow.com/questions/50760701/could-not-find-a-supported-mac-sdk-10-10-10-11-10-12-10-13)
* [创建区分大小写的磁盘映像-source.android.google.cn](https://source.android.google.cn/setup/build/initializing?hl=zh-cn#creating-a-case-sensitive-disk-image)



