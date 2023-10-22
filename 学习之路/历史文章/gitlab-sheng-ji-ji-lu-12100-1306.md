---
title: 'Gitlab升级记录（12.10.0-13.0.6）'
date: 2020-05-21 16:50:41
tags: [Gitlab]
published: true
hideInList: false
feature: 
isTop: false
---

将gitlab（Docker方式运行）从12.10.0升级到13.0.6 的过程记录。

<!-- more -->

## 升级准备工作

### **确定升级路线**

- 现有版本：12.10.0
- 当下目标版本：13.0.6
- 结合 [Gitlab升级路线建议](https://docs.gitlab.com/ee/policy/maintenance.html#upgrade-recommendations) 确定如下升级路线：
  - 12.10.0 -> 13.0.0 -> 13.0.6 
  - 由于我们跨大版本升级了（12-13），所以引入了 13.0.0 的中间升级路径

### **获取最新版本信息**

- 查看 gitlab release页面 信息
- 查看 gitlab docker hub 获取gitlab-ce docker镜像版本TAG：
- 13.0.0: `gitlab/gitlab-ce:13.0.0-ce.0`
- 13.0.6: `gitlab/gitlab-ce:13.0.6-ce.0`
- 查看升级注意事项
- 升级流程： https://docs.gitlab.com/omnibus/docker/README.html#update
- 版本升级建议路线：https://docs.gitlab.com/ee/policy/maintenance.html#upgrade-recommendations

## 备份

备份有两种方式，备份的数据量不相同：

* 对docker挂载的gitlab数据目录整体备份
* 使用 gitlab的 `gitlab-backup create` 命令创建备份，可包含所有git仓库，包括wiki及权限信息。

> 建议对挂载的gitlab数据目录进行一次整体备份，目前暂不清楚gitlab-backup create命令创建的备份是否包含ci相关内容。

以下对gitalb-backup 命令执行备份进行简要介绍。数据目录的备份方式直接对目录进行操作即可。

进入到gitlab部署机器，执行如下命令：

```shell l
docker exec -t <container name> gitlab-backup create
# 如果docker容器的名称是gitlab，则可以执行如下命令，备份完成后位于gitlab的数据目录，如：/data/gitlab/data/backups/
docker exec -t $(docker ps | grep gitlab | awk '{print $1}') gitlab-backup create
# 备份配置目录
sudo tar -cvf /data/gitlab/data/backups/1592710400_2020_06_21_12.10.0_gitlab_config_backup.tar /data/gitlab/config 
```

## 执行升级：

- 进入到gitlab部署机器 

```shell
ssh -p 10022 geostar@172.18.0.208
```

- 获取Gitlab中间版本镜像及最终版本镜像

```shell
docker pull gitlab/gitlab-ce:13.0.0-ce.0
docker pull gitlab/gitlab-ce:13.0.6-ce.0
```

- 停止并移除现有服务

```shell
sudo docker stop gitlab 
sudo docker rm gitlab 
```

- 进行升级，使用 13.0.0 的镜像运行gitlab，gitlab会自动处理数据升级流程

```shell
    sudo docker run --detach \
        --hostname 172.18.0.208 \
        --publish 443:443 --publish 80:80 --publish 22:22 \
        --name gitlab \
        --restart always \
        --volume /data/gitlab/config:/etc/gitlab \
        --volume /data/gitlab/logs:/var/log/gitlab \
        --volume /data/gitlab/data:/var/opt/gitlab \
        gitlab/gitlab-ce:13.0.0-ce.0
```

- 待 13.0.0 升级完毕之后，升级到 13.0.6，使用 13.0.6 的镜像运行gitlab

```shell
      sudo docker stop gitlab 
      sudo docker rm gitlab 
      sudo docker run --detach \
        --hostname 172.18.0.208 \
        --publish 443:443 --publish 80:80 --publish 22:22 \
        --name gitlab \
        --restart always \
        --volume /data/gitlab/config:/etc/gitlab \
        --volume /data/gitlab/logs:/var/log/gitlab \
        --volume /data/gitlab/data:/var/opt/gitlab \
        gitlab/gitlab-ce:13.0.6-ce.0
```

## 确认升级成功

登录管理员账号，进入管理中心-仪表盘，查看gitlab版本：

![20210302165417](https://s2.loli.net/2022/05/26/bZVXJwGkjyC6AdL.png)

