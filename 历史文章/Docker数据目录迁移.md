---
title: 'Docker数据目录(/var/lib/docker)迁移'
date: 2021-04-21 16:51:40
tags: [Docker]
published: true
hideInList: false
feature: 
isTop: false
---
本文介绍如何安全的迁移Docker的数据目录/var/lib/docker

<!-- more -->


## 为什么要迁移

* 虚拟机创建时，一般分配一个比较小的系统盘，然后挂载一个大容量的数据盘，docker默认情况下数据存储在系统盘(/var/lib/docker)目录，时间一久，会占满系统盘。

## 迁移步骤

1. **首先需要停止docker服务**
```
systemctl stop docker
```
2. **通过命令df -h 先去看下磁盘大概的情况，找一个大的空间**
3. **创建docker的新目录，我这边找了data, 所以我这边的新目录地址是 /data/docker/lib/**
```


mkdir -p /data/docker/lib
```
>注：参数-p 确保目录名称存在，如果目录不存在的就新创建一个。
4. **开始迁移**
```
rsync -avzP /var/lib/docker /data/docker/lib/
```
> 先确认是否安装了rsync.

参数解释：

* -a，归档模式，表示递归传输并保持文件属性。
* -v，显示rsync过程中详细信息。可以使用"-vvvv"获取更详细信息。
* -P，显示文件传输的进度信息。(实际上"-P"="--partial --progress"，其中的"--progress"才是显示进度信息的)。
* -z,   传输时进行压缩提高效率。
5. **指定新的docker目录**
```
vim /lib/systemd/system/docker.service
```
在ExecStart加入:
```
 --graph=/data/docker/lib/docker
```
6. **重启docker**
```
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl enable docker # 运行docker自动启动，这里可以不执行
```
7. **启动之后确认docker 没有问题，确认之前的容器和镜像都还在，然后删除旧的/var/lib/docker/目录**



## 参考文章：

* [https://www.cnblogs.com/insist-forever/p/11739207.html](https://www.cnblogs.com/insist-forever/p/11739207.html?fileGuid=qQhpHWDVq8HrH9kj)



