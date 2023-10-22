---
title: 'Docker构建Arm架构镜像-通用步骤'
date: 2020-08-19 17:20:59
tags: [Docker]
published: true
hideInList: false
feature: 
isTop: false
---

介绍ARM版本的Docker镜像的构建，包括ARM机器上Docker的安装，在ARM机器上构建镜像，及在amd64机器上使用buildx交叉构建arm版本镜像。

<!-- more -->


## 前言

现在很多地方都对服务的国产化适配有所要求，一般的国产化平台都提供arm版本的linux云环境供我们进行服务部署，因此需要构建arm版本的镜像。


## 测试机信息

| CPU      | FT-1500A 4核 arm64 |
| :------- | :----------------- |
| 内存     | 8G                 |
| OS       | 麒麟V10            |
| 包管理器 | apt                |

## ARM机器上安装Docker

>[Docker官方文档](https://docs.docker.com/engine/install/?fileGuid=0l3NVKX0BgflYN3R)

Docker支持如下系统及架构

![图片](https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20210408172838.png!thumbnail)

国产系统依据安装包的格式选择对应的参考系统即可，如麒麟v10基于ubuntu，可以按[官方文档- Install Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/?fileGuid=0l3NVKX0BgflYN3R)进行安装。

### 查看系统信息

```plain
geostar@geostar-ft1500a:~$ cat /proc/version
Linux version 4.4.131-20200515.kylin.desktop-generic (YHKYLIN-OS@Kylin) (gcc version 5.5.0 20171010 (Ubuntu/Linaro 5.5.0-12ubuntu1~16.04) ) #kylin SMP Fri May 15 11:29:10 CST 2020
```

这里可以看到系统是基于ubuntu16.04 的，所以我们添加ubuntu16.04（xenial）的软件源

### 添加软件源

>参考：
>https://mirrors.tuna.tsinghua.edu.cn/help/ubuntu/
>https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/

添加清华镜像软件源（arm架构）

```plain
# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ xenial main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ xenial main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ xenial-updates main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ xenial-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ xenial-backports main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ xenial-backports main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ xenial-security main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ xenial-security main restricted universe multiverse
```

更新：

```plain
sudo apt-get install apt-transport-https
sudo apt-get clean
sudo apt-get update
```

### 安装Docker

```plain
# 卸载旧版本docker
sudo apt-get remove docker docker-engine docker.io containerd runc
sudo apt-get update
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
    
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
# 确认key添加成功(查找：9DC8 5822 9FC7 DD38 854A  E2D8 8D81 803C 0EBF CD88)
sudo apt-key fingerprint 0EBFCD88
```

编辑 /etc/apt/source.list，添加docker软件源（arm64 xenial），并保存

```plain
# https://docs.docker.com/engine/install/ubuntu/
deb [arch=arm64] https://download.docker.com/linux/ubuntu xenial stable
```

安装 docker

```plain
sudo apt-get update
# 安装Docker
sudo apt-get install docker-ce docker-ce-cli containerd.io
# 安装成功，查看版本
docker --version
Docker version 19.03.12, build 48a6621
```

## 在Dockerhub上查找已有的arm镜像

实际上很多镜像都有构建arm版本，对于直接使用的镜像，或者作为Dockerfile中FROM的镜像，如果有对应的arm版本，则可以直接使用，省略构建过程。以[postgres](https://hub.docker.com/_/postgres?fileGuid=0l3NVKX0BgflYN3R)为例，在dockerhub上可以看到

![图片](https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20210408172847.png!thumbnail)

在具体的tag中也可以看到版本的镜像是否支持arm架构

![图片](https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20210408172851.png!thumbnail)

但需要使用的镜像不是我们自己编译的时候，可以通过这种方式来确认该镜像是否有对应的arm版本。

## ARM版本镜像构建（非ARM机器上执行）

>参考：
>-[https://github.com/docker/cli/blob/master/experimental/README.md](https://github.com/docker/cli/blob/master/experimental/README.md?fileGuid=0l3NVKX0BgflYN3R)
>-[跨平台构建 Docker 镜像新姿势，x86、arm 一把梭](https://cloud.tencent.com/developer/article/1543689?fileGuid=0l3NVKX0BgflYN3R)

### 构建ARM镜像的两种方式

对于构建镜像的ARM版本，有如下两种方式：

1. 在ARM机器上使用 docker build 进行构建；
2. 在X86/AMD64 的机器上使用 docker buildx 进行交叉构建；

实际测试中发现第一种方式在某些情况下会有问题，建议采用结合采用这二种方式；

关于第二种构建方式，可先阅读[跨平台构建 Docker 镜像新姿势，x86、arm 一把梭](https://cloud.tencent.com/developer/article/1543689?fileGuid=0l3NVKX0BgflYN3R)进行了解，以下简要介绍使用buildx交叉构建的方式；

> **⚠️注意：**
>
> 1. 交叉构建和交叉运行的方式会有一些无法预知的问题，建议简单的构建步骤（如只是下载解压对应架构的文件）可考虑在x86下交叉构建，复杂的（如需要编译的）则直接在arm机器上进行构建；
>
> 2. 实际测试发现，使用[qemu方式](https://github.com/multiarch/qemu-user-static)在x86平台下运行arm版本的镜像时，执行简单的命令可以成功（如arch），执行某些复杂的程序时（如启动java虚拟机），会无响应，所以镜像的验证工作应尽量放置到arm机器上进行；
>
>    上面第二点按如下方式测试： 
>
>    * `docker run --rm --platform=linux/arm64 openjdk:8u212-jre-alpine arch` 可正常输出；
>    * `docker run --rm --platform=linux/arm64 openjdk:8u212-jre-alpine java -version` 则会**卡住**，且需要使用`docker stop`停止容器才可以退出容器；

### 启用试验性功能

>参考：https://docs.docker.com/engine/reference/commandline/cli/#experimental-features
>注意：buildx 仅支持 docker19.03 及以上docker版本

如需使用 buildx，需要开启docker的实验功能后，才可以使用，开启方式：

* 编辑   /etc/docker/daemon.json
* 添加：

```json
{
    "experimental": true
}
```

* 编辑 ～/.docker/config.json 添加：

```json
"experimental" : "enabled"
```

* 重启Docker使生效：
  * sudo systemctl  daemon-reload
  * sudo systemctl  restart docker
* 确认是否开启：
  * docker version -f'{{.Server.Experimental}}'
  * 如果输出true，则表示开启成功

### 使用buildx构建

buildx 的详细使用可参考：[Docker官方文档-Reference-buildx ](https://docs.docker.com/engine/reference/commandline/buildx/?fileGuid=0l3NVKX0BgflYN3R)

#### 创建 buildx 构建器

使用 docker buildx ls 命令查看现有的构建器

```shell
docker buildx ls
```

创建并构建器：

```shell
# 下面的创建命令任选一条符合情况的即可
# 1. 不指定任何参数创建
docker buildx create --use --name multiarch-builder
# 2. 如创建后使用docker buildx ls 发现构建起没有arm架构支持，可使用--platform明确指定要支持的构建类型，如以下命令
docker buildx create --platform linux/arm64,linux/arm/v7,linux/arm/v6 --name multiarch-builder
# 3. 如需在buildx访问私有registry，可使用host模式，并手动指定配置文件，避免buildx时无法访问本地的registry主机 
docker buildx create --platform linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6  --driver-opt network=host --config=/Users/hanlyjiang/.docker/buildx-config.toml --use --name multiarch-builder 
```

buildx-config.toml 配置文件写法类似：

```plain
# https://github.com/moby/buildkit/blob/master/docs/buildkitd.toml.md
# registry configures a new Docker register used for cache import or output.
[registry."zh-registry.geostar.com.cn"]
  mirrors = ["zh-registry.geostar.com.cn"]
  http = true
  insecure = true
```

**启用构建器**

```shell
# 初始化并激活
docker buildx inspect multiarch-builder --bootstrap
```

**确认成功**

```plain
# 使用 docker buildx ls 查看
docker buildx ls 
```

### 修改Dockerfile

对 Dockerfile 的修改，大致需要进行如下操作：

1. 确认基础镜像（FROM）是否有arm版本，如果有，则可以不用改动，如果没有，则需要寻找替代镜像，如没有替代镜像，则可能需要自行编译；
2. 确认dockerfile的各个步骤中是否有依赖CPU架构的，如果有，则需要替换成arm架构的，如在构建jitis的镜像时，Dockerfile中有添加一个amd64架构的软件

`ADD https://github.com/just-containers/s6-overlay/releases/download/v1.21.4.0/s6-overlay-amd64.tar.gz /tmp/s6-overlay.tar.gz`

此时需要替换为下面的地址(注意amd64替换成了aarch64，当然，需要先确认下载地址中有无对应架构的gz包，不能简单做字符替换)：

`ADD https://github.com/just-containers/s6-overlay/releases/download/v1.21.4.0/s6-overlay-aarch64.tar.gz /tmp/s6-overlay.tar.gz`

当然，我们需要确认该软件有此架构的归档包，如果没有，则需要考虑从源码构建；

> **提示：**
>
> 怎么确定一个可执行文件/so库的对应的执行架构？ 可以通过 `file {可执行文件路径}` 来查看，
>
> 如下面时macOS上执行file命令的输入，可以发现macOS上的git程序可以兼容两种架构-`x86_64&arm64e`：
>
> ```shell
> file $(which git)
> /usr/bin/git: Mach-O universal binary with 2 architectures: [x86_64:Mach-O 64-bit executable x86_64] [arm64e:Mach-O 64-bit executable arm64e]
> /usr/bin/git (for architecture x86_64):	Mach-O 64-bit executable x86_64
> /usr/bin/git (for architecture arm64e):	Mach-O 64-bit executable arm64e
> ```
>
> 下面的命令则对一个so文件执行了file，可以看到其中的架构信息 `ARM aarch64`：
>
> ```shell
> file /lib/aarch64-linux-gnu/libpthread-2.23.so
> /lib/aarch64-linux-gnu/libpthread-2.23.so: ELF 64-bit LSB shared object, ARM aarch64, version 1 (GNU/Linux), dynamically linked, interpreter /lib/ld-linux-aarch64.so.1, BuildID[sha1]=880365ebb22114e4c10108b73243144d5fa315dc, for GNU/Linux 3.7.0, not stripped
> ```

### docker buildx 构建arm64镜像的命令

使用 --platform来指定架构，使用 `--push` 或 `--load` 来指定构建完毕后的动作。

```shell
docker buildx build --platform=linux/arm64,linux/amd64 -t xxxx:tag . --push 
```

> 提示：当指定多个架构时，只能使用 --push 推送到远程仓库，无法 --load，推送成功后再通过 docker pull --platform 来拉取指定架构的镜像

### 检查构建成果

1. 通过 `docker buildx imagetools inspect` 命令查看镜像信息，看是否有对应的arm架构信息；
2. 实际运行镜像，确认运行正常；（在arm机器上执行）

>提示：如运行时输出 exec format error 类似错误，则表示镜像中部分可执行文件架构不匹配。



## 在x86上运行arm镜像

可参考 [github/qemu-user-static](https://github.com/multiarch/qemu-user-static) ,简要描述如下：

* 执行如下命令安装：

  `docker run --rm --privileged multiarch/qemu-user-static --reset -p yes`

* 之后即可运行arm版本的镜像，如：

  ```shell
  docker run --rm -t arm64v8/fedora uname -m
  ```

