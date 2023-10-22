---
title: 'Gitlab安装配置'
date: 2020-04-06 11:54:06
tags: [Gitlab,工具]
published: true
hideInList: false
feature: 
isTop: false
---
主要内容：
*  使用docker运行 gitlab；
*  配置LDAP及邮箱；
*  配置管理员账号；
*  配置邮箱通知；
*  关闭用户注册；
<!-- more -->

## 安装

我们使用docker来安装Gitlab，执行如下命令即可安装运行，完成后使用

```shell
export GITLAB_DATA=/data/gitlab
# 设置主机的ip域名
export HOST_IP=192.168.43.62
mkdir $GITLAB_DATA/config $GITLAB_DATA/logs $GITLAB_DATA/data
docker run --detach \
        --hostname $HOST_IP \
        --publish 443:443 --publish 80:80 --publish 22:22 \
        --name gitlab \
        --restart always \
        --volume $GITLAB_DATA/config:/etc/gitlab \
        --volume $GITLAB_DATA/logs:/var/log/gitlab \
        --volume $GITLAB_DATA/data:/var/opt/gitlab \
        gitlab/gitlab-ce:13.9.1-ce.0
```

> * 数据全部挂载在外部目录 GITLAB_DATA 中
> * `--hostname 192.168.43.62` : 指定当前服务的IP或者域名，后续将会显示为gitlab代码仓库的克隆地址
> * `--restart always` : 设置服务自动重启

> 查看gitlab的可用版本： 
>
> * [dockerhub/gitlab-ce](dockerhub/gitlab-ce)
> * [gitlab release page](https://about.gitlab.com/releases/categories/releases/)

### **查看启动状态**

启动期间可以使用 `docker ps` 查看状态，如STATUS中显示为`starting`则表示服务还在启动中，如显示为`healthy`则表示服务已正常启动，即可访问 http://192.168.43.62 访问Gitlab的web地址。

```shell
CONTAINER ID        IMAGE                          COMMAND             CREATED             STATUS                 PORTS                                                          NAMES
79b432f0f601        gitlab/gitlab-ce:13.0.6-ce.0   "/assets/wrapper"   2 months ago        Up 2 weeks (healthy)   0.0.0.0:22->22/tcp, 0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp   gitlab
```

也可使用 `docker logs -f gitlab` 来查看gitlab的服务启动日志

### 设置root管理员用户密码

首次打开页面后会提示设置root用户的密码，设置后务必记录好用户密码，后续将使用此用户对Gitlab进行管理

![20210302163607](https://s2.loli.net/2022/05/26/XsnoPBt1K5bZHap.png)

## 配置LDAP

服务启动正常后，`$GITLAB_DATA/config` 文件夹中即生成了gitlab的配置文件，可编辑`$GITLAB_DATA/config/gitlab.rb` （对应容器内部 `/etc/gitlab/gitlab.rb` ）文件来修改gitlab配置以使用LDAP

```shell
vim /etc/gitlab/gitlab.rb
```

通过`?` 搜索`LDAP`，找到如下配置端，按如下方式进行修改：

```ruby

### LDAP Settings
###! Docs: https://docs.gitlab.com/omnibus/settings/ldap.html
###! **Be careful not to break the indentation in the ldap_servers block. It is
###!   in yaml format and the spaces must be retained. Using tabs will not work.**

gitlab_rails['ldap_enabled'] = true

gitlab_rails['ldap_servers'] = YAML.load <<-'EOS'
   main:
     label: '域账号'
     host: '172.17.0.3'
     port: 389
     uid: 'sAMAccountName'
     bind_dn: 'CN=域账号读取用户,OU=colorless-域用户,DC=colorless,DC=com,DC=cn'
     password: '域账号读取用户的登录密码'
     encryption: 'plain' # "start_tls" or "simple_tls" or "plain"
     verify_certificates: false
     smartcard_auth: false
     active_directory: true
     allow_username_or_email_login: false # 是否允许以用户名登录（邮箱也会取用户名来严重）
     lowercase_usernames: false
     block_auto_created_users: false
     base: 'OU=colorless-域用户,DC=colorless,DC=com,DC=cn'
     user_filter: ''
EOS

```

> 配置修改说明：
>
> * `ldap_enabled` 需要设置为true
> * `ldap_servers` 配置AD域相关信息
>   * label： 随便取，会显示在gitlab的登录页面
>   * host： 域控制服务器主机地址
>   * port： 域控制器服务端口
>   * uid：  将域用户信息中的哪个字段作为gitlab上的登录标识（一般都是sAMAccountName）
>   * bind_dn： 用于访问域控制服务器的用户账号，用户账号的格式需要使用`CN=xxx,OU=XXX,DC=XXXX` 类似的格式
>   * password： 对应的base_dn账号的密码
>   * base： 用于登录时，会去base所定义的组里面去检索用户是否存在，如用户在这个范围内，才可以登录；如及用于公司一个部门的登录，可将base值配置到部门级别，则其他部分无法以域账号进行登录；
>
> 提示： 如无法确认 uid，bind_dn，base 等的值，可以咨询信息中心或者使用AD域访问查看软件（如：[Apache Directory](http://directory.apache.org/)）连接到域账号控制器服务后，通过图形界面查看对应信息；

修改完毕后需要保存文件后重启gitlab服务，对于docker启动的gitlab来说，可执行如下命令重启服务：

```shell
# 其中gitlab为我们使用docker run 命令时通过--name选项指定的容器名称
docker restart gitlab 
```

待gitlab重启完毕后，登录界面即出现域账号登录的tab入口，点击域账号tab即可使用域账号进行登录

<img src="https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20210302161215.png" alt="image-20210302161215567" style="zoom:50%;" />

## 配置邮箱通知

公司邮箱服务器配置：

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "mail.colorless.com.cn"
gitlab_rails['smtp_port'] = 25
gitlab_rails['smtp_user_name'] = "gitlab@colorless.com.cn"
gitlab_rails['smtp_password'] = "xxxxx"
gitlab_rails['smtp_domain'] = "colorless.com.cn"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = false
```

163邮箱配置示例：（需在163邮箱中开启SMTP服务，可参考： [CSDN-如何使用163的SMTP服务发邮件？](https://blog.csdn.net/liuyuinsdu/article/details/113878840)）

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.163.com"
gitlab_rails['smtp_port'] = 25
gitlab_rails['smtp_user_name'] = "colorless@163.com"
gitlab_rails['smtp_password'] = "密码"
gitlab_rails['smtp_domain'] = "163.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = false
```



## 关闭及管理员配置

### 赋予指定域账号管理员权限

在配置了域账号登录之后，先让需要设置为管理员的账号使用域账号登录一次gitlab，登录后gitlab即会为该用户创建关联的gitlab账号。

然后使用root用户登录，进入

![20210302164307](https://s2.loli.net/2022/05/26/2z9MUSVjFntBpK1.png)

将用户的访问类型切换为管理员：

![20210302164354](https://s2.loli.net/2022/05/26/VXq4AE2lKjd1PLn.png)

### 关闭用户注册

在配置了域账号登录之后，可以关闭用户注册，即只允许拥有域账号的人员进行登录；

![](https://s2.loli.net/2022/05/26/VXq4AE2lKjd1PLn.png)

