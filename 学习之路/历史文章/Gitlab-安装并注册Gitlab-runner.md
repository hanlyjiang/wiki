---
title: 'Gitlab-Runner安装并注册 '
date: 2020-06-11 16:11:58
tags: [Gitlab,工具]
published: true
hideInList: false
feature: 
isTop: false
---
本文介绍Gitlab-Runner的安装运行（包括docker方式安装运行及二进制直接运行），并介绍如何将Gitlab注册到Gitlab。同时还介绍了gitlab-runner的一些常用操作命令。


<!-- more -->



## 安装Gitlab-Runner

gitlab-runner可以使用docker方式运行，也可以在主机上运行其二进制可执行文件，可按如下方式进行选择：

* 执行通用的构建测试任务及与不需要直接访问主机目录的，以docker方式安装；
* 执行部署类任务或需要直接访问主机目录的，以二进制方式安装；

以下分别介绍上述两种安装方式。



### 使用docker安装gitlab-runner

使用docker方式安装的，需先在主机上安装docker环境，可参考 Docker 官方安装文档。以下操作假设主机上已正确安装并配置了docker运行环境；

>提示：可以使用基于alpine的镜像来减小大小

```shell
# 建立配置挂载目录
mkdir -p /data/gitlab-runner/config
# 建立构建目录挂载目录
mkdir -p /data/gitlab-runner/home
# 注意，这里我们使用了基于alpine的镜像来减小大小；使用 --restart 标识来自动重启
docker run -d --name gitlab-runner --restart always \
  -v /data/gitlab-runner/config:/etc/gitlab-runner \
  -v /data/gitlab-runner/home:/home/gitlab-runner \
  -v /var/run/docker.sock:/var/run/docker.sock \
  gitlab/gitlab-runner:alpine
  
# 通过以下命令设置docker开机自启
sudo systemctl enable docker
```

### docker安装的gitlab-runner常用操作

#### 运行命令

使用已有容器

```shell
# 容器已经运行的情况下
# 1. 交互式执行，执行以下命令，然后输入命令
docker exec -it gitlab-runner /bin/bash
# 然后执行命令
gitlab-runer --help
# 2. 单次执行
docker exec gitlab-runner gitlab-runner --help
```

使用临时的：

```shell
docker run --rm -t -i gitlab/gitlab-runner:alpine --help
# -it 使用交互式终端
# --rm 自动删除
```

#### 重启gitlab-runner

```
docker restart gitlab-runner
```

#### 升级版本

```shell
# 获取最新
docker pull gitlab/gitlab-runner:alpine
docker stop gitlab-runner && docker rm gitlab-runner
docker run -d --name gitlab-runner --restart always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /data/gitlab-runner/config:/etc/gitlab-runner \
  -v /data/gitlab-runner/home:/home/gitlab-runner \
  gitlab/gitlab-runner:alpine
```

#### 查看日志

```shell
docker logs gitlab-runner
```

#### 配置 gitlab-runner 别名

在 `~/.bash_profile` 或 `~/.bashrc` 文件中加入如下函数配置，后续运行 gitlab-runner 命令时即可省去docker exec 命令

```shell
# 添加 gitlab-runner 直接执行到容器
function gitlab-runner(){
    docker exec -it gitlab-runner gitlab-runner $@
}
```



### 使用二进制包安装运行gitlab-runner

#### 获取安装包安装并运行

* Centos or RedHat 使用如下命令安装：

  ```shell
  ARCH=$(arch)
  
  curl -LJO "https://gitlab-runner-downloads.s3.amazonaws.com/latest/rpm/gitlab-runner$ARCH.rpm"
  
  rpm -i gitlab-runner_$ARCH.rpm
  ```

* Debian or Ubuntu 使用如下命令安装

  ```shell
  ARCH=$(arch)
  
  curl -LJO "https://gitlab-runner-downloads.s3.amazonaws.com/latest/deb/gitlab-runner_$ARCH.deb"
  
  dpkg -i gitlab-runner_$ARCH.deb
  ```

* Windows 安装

  请参考官方文档： https://docs.gitlab.com/runner/install/windows.html#installation

* 测试是否安装成功，如能成功输出gitlab-runner的用法信息，则表示安装成功

  ```
  gitlab-runner --help
  ```

* 测试是否成功启动

  ```
  gitlab-runner status
  # 如输出 Service is running，则表示成功启动了
  ```

  > 通过docker方式运行的runner在运行 `gitlab-runner status`时会输出 `not running`，这对于docker方式运行的runner是正常的，只有直接运行于主机上的runner需要启动对应的服务；

#### 安装并更新Git版本

Gitlab-CI 任务在 runner 机器上执行，会先通过git获取对应仓库的最新代码，这个获取代码的操作是通过git来完成的，所以我们需要安装git工具；

* **安装Git**

  ```shell
  sudo yum install -y git
   # 查看版本
  git --version
  # centos7 上为 1.8.x，无法满足gitlab要求
  ```

* **升级Git版本**

  某些linux发型版上git版本过低，在执行流水线时会失败，需要升级git版本，可按如下方式从源码安装最新git版本；

  * 下载git v2.27.0源码

    ```shell
    ## 以下下载方式任选其一
    # 可选下载方式1 - 从gitee 克隆
    git clone -b v2.27.0 https://gitee.com/hanlyjiang/git.git git-2.27.0
    cd git-2.27.0 && git checkout -b tag-v2.27.0 v2.27.0
    
    # 可选下载方式2 - 从github直接下载包
    curl -LJO https://github.com/git/git/archive/v2.27.0.tar.gz
    tar -xvf git-2.27.0.tar.gz 
    cd git-2.27.0
    ```

  * 编译安装

    ```shell
    # 安装编译依赖库
    sudo yum install  -y autoconf gcc openssh zlib-devel
    
    # 编译并安装
    make configure ;# as yourself
    ./configure --prefix=/usr ;# as yourself
    make -j8 all ;# as yourself
    sudo make install ;# as root
    
    # 确认版本：
    git --version
    # git version 2.27.0
    ```

#### 将gitlab-runner用户添加到docker用户组（可选）

如需要在该gitlab-runner的CI脚本中运行docker命令，这需要将 gitlab-runner用户添加到docker的用户组，可执行如下命令：

```shell
sudo usermod -a -G docker gitlab-runner

# 验证权限
sudo -u gitlab-runner -H docker info
```

#### 修改 gitlab-runner 构建目录

如在执行ci任务时，拉取代码时报build目录权限问题，可尝试按如下方式修改指定runner的构建目录

1. 查找配置文件路径

   ``` shell
   gitlab-runner list 
   # 其中ConfigFile的值就是对应的配置文件，如：
   # ConfigFile=/etc/gitlab-runner/config.toml
   ```

2. 修改 `builds_dir` 指向

   找对该任务对应的`[[runner]]` 配置段，并在该配置中添加 `builds_dir` 指向新的具有权限的目录，然后重启启动gitlab-runner即可；

   ```yaml
   [[runners]]
     name = "blockdataapi-engine"
     url = "http://172.18.0.208/"
     token = "Y-6zdV9zzi8xsY1rygbn"
     executor = "shell"
     builds_dir = "/data/gitlab-runner/builds"
     [runners.custom_build_dir]
     [runners.cache]
       [runners.cache.s3]
       [runners.cache.gcs]
   ```



## 注册 Runner 到 Gitlab

这里我们将runner注册为群组的Runner，群组runner可以在群组中共享，所有子群组和项目都可以使用该Runner。也可以将Runner注册到指定项目仓库上，操作上只有获取gitlab-runner注册信息时不一样；

### 获取gitlab-runner注册信息

> 如需注册到具体项目，在项目的设置在进入对应的CI/CD设置即可，后续操作流程一致；

在群组的设置中打开 CI/CD 设置

![20210224180602](https://s2.loli.net/2022/05/26/IwgQXD4zMr6kCuT.png)

展开 Runner 栏位

![20210224180606](https://s2.loli.net/2022/05/26/SPIA5iMEXOrsZDu.png)

这里我们选择通过手动设置group runner的方式来注册，可以获取到以下信息：

![20210224180610](https://s2.loli.net/2022/05/26/awygY86Wz37MUv5.png)

### 注册runner

以docker方式运行的gitlab-runner可按如下方式进入交互环境，**直接二进制运行的无需此操作**；

在gitlab-runner 的机器上执行注册命令，将runner注册到gitlab，为了方便操作，我们使用以下命令进入gitlab-runner容器shell环境：

```shell
docker exec -it gitlab-runner /bin/bash
```

执行完成后出现如下交互窗口

```shell
bash-4.4#
```

docker方式运行的runner需在此bash中执行命令，主机之间运行的runner直接在shell中执行即可。

### 执行register命令进行注册

```shell
gitlab-runner register 
# url：
http://172.18.0.208/
# token
cEJ611JDeCWSMyu7WXwx
# description - 用于辨识该注册所属的群组或项目，可以设置为方便区分的字符串
sonarqube-runner
# ci-tag - 标签用于后续CI配置中选择此执行器，后期可以通过gitlab界面更改
sonarqube,common-build
# executor - 后续CI任务的执行方式，docker方式运行的请选择docker
docker
# default image - CI配置中未指定镜像时默认使用的镜像
busybox:1.31.1
```

以下为一个注册过程的交互示例：

```shell
bash-4.4# gitlab-runner register 
Runtime platform                                    arch=amd64 os=linux pid=205 revision=05161b14 version=12.4.1
Running in system-mode.                            
                                                   
Please enter the gitlab-ci coordinator URL (e.g. https://gitlab.com/):
http://172.18.0.208/
Please enter the gitlab-ci token for this runner:
cEJ611JDeCWSMyu7WXWi
Please enter the gitlab-ci description for this runner:
[e0311b0ce34b]: sonarqube-runner
Please enter the gitlab-ci tags for this runner (comma separated):
sonarqube,common-build
Registering runner... succeeded                     runner=cEJ611JD
Please enter the executor: virtualbox, docker+machine, docker-ssh+machine, custom, docker-ssh, parallels, kubernetes, docker, shell, ssh:
docker
Please enter the default Docker image (e.g. ruby:2.6):
busybox:1.31.1
Runner registered successfully. Feel free to start it, but if it's running already the config should be automatically reloaded!
```

### 注册后确认

完成后在刚才的页面可以看到；
![图片](https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20210224180615.png)

### 取消注册

使用 list 命令查看当前注册的token及url

```shell
gitlab-runner list
# 输出类似
Runtime platform                                    arch=amd64 os=linux pid=23 revision=05161b14 version=12.4.1
Listing configured runners                          ConfigFile=/etc/gitlab-runner/config.toml
sonarqube-runner                                    Executor=docker Token=wNwxjEztRpKxYDyK1zVd URL=http://172.18.0.208/
```

使用list命令输出的token机url作为参数 使用unregister命令取消注册

```shell
gitlab-runner unregister -t 7KM7ftthLAYeJdsB3Tbk -u http://172.18.0.208/
```



## 了解更多

* [DOCKER 方式安装gitlab-runner](https://docs.gitlab.com/runner/install/docker.html)
* [Linux安装gitlab-runner-Gitlab官方文档](https://docs.gitlab.com/runner/install/linux-manually.html)
* [使用Docker运行Gitlab-Runner-Gitlab官方文档](https://docs.gitlab.com/runner/install/docker.html)
* [注册Runner-Gitlab官方文档](https://docs.gitlab.com/runner/register/index.html)
* [Gitlab-Runner alpine Dockerfile](https://gitlab.com/gitlab-org/gitlab-runner/blob/master/dockerfiles/alpine/Dockerfile)
* [Windows上注册Runner](https://docs.gitlab.com/runner/install/windows.html)
* [如何在docker执行器中构建Docker镜像？](http://github.com/help/ci/docker/using_docker_build.md)