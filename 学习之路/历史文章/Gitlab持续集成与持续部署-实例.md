---
title: 'Gitlab持续集成与持续部署-实例'
date: 2021-05-26 16:12:17
tags: [Gitlab,CICD]
published: true
hideInList: false
feature: 
isTop: false
---


本篇文章介绍如何基于Gitlab来配置一个服务集群的自动构建与部署更新，其中服务的更新基于docker来完成，本文主要关注如何完成部署操作，及如何完成gitlab上ci的配置；在完成单一的服务自动部署更新后，我们通过gitlab的include及trigger机制来简化统一部署流程；
<!-- more -->

## 前言

我们需要实现服务的自动构建后的自动更新部署，注意这里我们只需要能做到更新部署的服务即可，服务的初次部署属于低频操作，且和服务器环境相关，需要手动来完成；我们这里假定机器上已经部署好了服务；


## 单一项目的自动部署的示例

这里我们首先以一个springboot的服务作为示例，实现了整个自动打包及部署更新的流程；

### 效果

* 提交之后，自动构建jar，并打包docker镜像

  ![202203192258673](https://s2.loli.net/2022/05/26/15jIx7oVTpdN2qG.png)

* 构建完成后，通过gitlab界面，可以触发部署，完成后可以访问对应的环境（详见下方说明）



### 触发部署步骤的方式

触发部署有多个入口：

1. 流水线列表尾部的手动作业按钮

   ![20210526101412](https://s2.loli.net/2022/05/26/H4IPizrx1pOlMwG.png)

2. 流水线列表中，点击对应的手动任务，在弹出框中点击运行

   ![20210526101519](https://s2.loli.net/2022/05/26/TN472VCvmxjhHwe.png)

3. 流水线详情中，点击触发部署

   ![202203192259870](https://s2.loli.net/2022/05/26/TpsmiNOa5AWVf32.png)

4. 对应手动作业的详情中，点击“触发此手动操作”

   ![202203192300715](https://s2.loli.net/2022/05/26/GDTRWdy2iXAP1Le.png)

5. 作业列表中对应的部署作业的尾部

   ![202203192301127](https://s2.loli.net/2022/05/26/574YeyxSfMqoaju.png)

### 访问部署环境的方式

部署之后，会在gitlab中生成一个环境，在环境的相关界面即可访问对应的服务地址

1. 在项目的“运维-环境”入口可以查看所有的环境

![20210526101758](https://s2.loli.net/2022/05/26/z6jTAhZRkmXGFqe.png)

2. 点击对应环境尾部的链接图标即可访问

   ![20210526101901](https://s2.loli.net/2022/05/26/NHU1YLsjnP8x3ib.png)

3. 也可以在对应的环境详情页面，点击“查看部署” （注意在部署作业的详情中也可以找到对应环境的入口哦-触发部署步骤的方式的第四中方式的附图）

   ![](https://s2.loli.net/2022/05/26/NHU1YLsjnP8x3ib.png)

### 实现方式

我们有三个任务：

* 构建jar
* 构建docker镜像
* 部署服务（通过swarm）

其中构建jar和构建docker镜像是自动完成的，部署步骤则需要手动通过gitlab界面进行触发；

#### gitlab-ci.yml 配置

```yaml
variables:
  #  配置仓库环境
  DOCKER_REGISTRY: zh-registry.colorless.com.cn
  DOCKER_NAMESPACE: colorless
  DEPLOY_PATH: /Wksp/colorlessWork/colorless-deploy/deploy/
  #  配置镜像服务名
  SERVICE_NAME: graphql-token

stages:
  - test
  - build
  - build_image
  - deploy

# 引入代码检查任务
#include:
#  local: ci/gitlab-ci-sonar.yml

build:jar:
  # 部分模块若不使用1.8编译会报错
  image: maven:3.6.3-jdk-8
  stage: build
  script:
    - mvn package
    - mkdir _archiver
    - cp target/*.jar _archiver/
    - ls -lh _archiver/
  artifacts:
    name: "dist-$CI_PROJECT_NAME-$CI_COMMIT_SHORT_SHA"
    paths:
      - _archiver/*.jar
    # 生成的归档包比较大，我们只保留短时间
    expire_in: 1 hours
  tags:
    - common-build
  only:
    - master
    - web

build:docker:
  stage: build_image
  script:
    # 登录公司的Harbor，注意必须在环境变量配置 HARBOR_PWD
    - echo $HARBOR_PWD | docker login --username=$HARBOR_USER $DOCKER_REGISTRY --password-stdin
    # 定义镜像TAG
    - IMAGE_NAME=$DOCKER_REGISTRY/$DOCKER_NAMESPACE/$SERVICE_NAME:$CI_COMMIT_SHORT_SHA
    - echo "Docker build options $DOCKER_OPTIONS, set DOCKER_OPTIONS to --no-cache force rebuild all stage"
    - cp _archiver/*.jar docker/
    # build镜像
    - JAR_FILE=`ls docker/ | grep -E *.jar`
    - echo $JAR_FILE
    - docker build $DOCKER_OPTIONS --build-arg JAR_FILE=$JAR_FILE -t $IMAGE_NAME ./docker/
    # 推送镜像
    - docker push $IMAGE_NAME
    - echo "镜像构建完成：$IMAGE_NAME"
  tags:
    - docker
  only:
    - master
    - web

deploy:
  stage: deploy
  script:
    - echo $HARBOR_PWD | docker login --username=$HARBOR_USER $DOCKER_REGISTRY --password-stdin
    - cd $DEPLOY_PATH
    - source deploy.sh
    - update_service $DOCKER_NAMESPACE $SERVICE_NAME $DOCKER_REGISTRY/$DOCKER_NAMESPACE/$SERVICE_NAME:$CI_COMMIT_SHORT_SHA
  environment:
    name: test_env_deploy
    url: $APP_URL/
  when: manual
  only:
    - branches
    - web
  tags:
    - deploy_graphql

```

注意 deploy 任务中定义的环境配置：

```yaml
  environment:
    name: test_env_deploy
    url: $APP_URL/
  when: manual
```

1. 通过environment配置，我们可以在gitlab的 “运维-环境” 中生成一条环境信息，一个环境信息即对应一个部署服务；

   定义环境信息，需要配置name和url两个字段，其中name是环境名称，url则应指向服务的地址，该url即是我们在gitlab环境中查看部署时跳转的页面；

2. 这里的url我们通过变量来进行配置，也可以直接写死；

3. 注意这里的name不能设置为中文；

2. 通过将when 设置为 manual ，可以将部署任务设置为手动触发的方式；

## 优化改进方案研究

### 改进目标

我们的一个集群之中有多个服务单元，每个服务单元提交代码更新之后，都需要自动部署更新到对应的环境中。我们可以选择将上面单个项目中的流程在所有项目中都复制一遍，不过：

* 重复工作较多，一旦部署脚本发生变化，每个项目都需要单独变化
* 每个项目都需要配置到部署服务器的runner

所以，我们需要考虑将这个重复的步骤集中起来。

> 实际上，打包jar和构建镜像的流程我们也可以考虑优化复用，不过我们这里主要专注于部署的改进。当服务被打包成镜像之后，部署的流程只关注于镜像，无需针对不同的服务进行区分对待，是非常适合提取统一的；

### 现状

经过上面的步骤，我们已经可以实现上传代码后自动编译，构建镜像，通过gitlab界面实现部署了。不过项目比较多时，我们每个都如此配置，一旦需要改动，会比较麻烦，我们可以考虑将这些任务提取成公用的脚本，在项目中进行引入。

现在，我们尝试将这部署任务提取成公共的。

实际上，上面的部署流程中，我们已经部署更新的流程做了封装，具体脚本如下，在更新服务时，我们只需要使用 `update_service` 函数即可完成服务的更新及本地yml部署文件的修改；

```shell
# 更新服务
update_service colorless graphql-engine zh-registry.colorless.com.cn/colorless/graphql-engine:1aaa7ad9
```

deploy.sh 脚本内容：（只关注update_service 的流程即可）

```shell
#!/usr/bin/env bash
#set -eo pipefail

REGISTRY_ALIYUN=registry.cn-hangzhou.aliyuncs.com/hasura
REGISTRY_HARBOR=zh-registry.colorless.com.cn/colorless
# 部署服务
STACK_NAME=colorless

function getSedOption() {
  if [ "$(uname)" = "Darwin" ]; then
    echo "-i .bak"
  else
    echo "-i.bak"
  fi
}

function logInfo() {
  echo "-->: $*"
}

function logError() {
  echo "-->Error: $*" >&2
}

# 设置部署目录
if [ "$0" = "-bash" ]; then
  DEPLOY_DIR=$PWD
else
  DEPLOY_DIR=$(
    cd $(dirname $0)
    pwd
  )
fi
echo "DEPLOY_DIR:$DEPLOY_DIR"

# 使用阿里云的镜像
function use_aliyun_images() {
  sed "$(getSedOption)" "s|$REGISTRY_HARBOR|$REGISTRY_ALIYUN|g" $DEPLOY_DIR/*/*.yml
}

# 使用内网 harbor 镜像
function use_harbor_images() {
  sed "$(getSedOption)" "s|$REGISTRY_ALIYUN|$REGISTRY_HARBOR|g" $DEPLOY_DIR/*/*.yml
}

# 部署单个脚本服务
function deploy() {
  service=$1
  stack_name=$2
  if [ -z "$service" ]; then
    echo "用法：deploy {服务名称} [stack名称]"
    echo "     {服务名称} - 可为 hasura，kafka，event_track"
    return
  fi
  if [ -z "$stack_name" ]; then
    stack_name=$STACK_NAME
  fi
  printf "\n%s\n" "获取镜像: $service "
  grep "image:" "$DEPLOY_DIR/$service/docker-compose.yml" | sed 's/image://g' | xargs -I {} docker pull {}
  printf "\n%s\n" "启动服务: $service "
  docker stack deploy -c "$DEPLOY_DIR/$service/docker-compose.yml" $stack_name
  printf "\n\n"
}

function deploy_offline() {
  service=$1
  stack_name=$2
  if [ -z "$service" ]; then
    echo "用法：deploy {服务名称} [stack名称]"
    echo "     {服务名称} - 可为 hasura，kafka，event_track"
    return
  fi
  if [ -z "$stack_name" ]; then
    stack_name=$STACK_NAME
  fi
  printf "\n%s\n" "启动服务: $service "
  docker stack deploy -c "$DEPLOY_DIR/$service/docker-compose.yml" $STACK_NAME
  printf "\n\n"
}

# 导出一个脚本中的镜像
function export_images() {
  service=$1
  if [ -z "$service" ]; then
    echo "用法：deploy {服务名称}"
    echo "     {服务名称} - 可为 hasura，kafka，event_track"
    return
  fi
  printf "\n%s\n" "导出镜像: $service "
  image_list=$(grep "image:" "$DEPLOY_DIR/$service/docker-compose.yml" | sed 's/image://g' | awk '{print $1}' | tr "\n" " ")
  echo "docker image save --output=$DEPLOY_DIR/$service.tar $image_list"
  docker image save --output="$DEPLOY_DIR/$service".tar "$image_list"
  printf "\n\n"
}

# 部署所有服务
# deploy_all [stack_name]
# - stack_name ： stack 名称，不传则为 colorless
function deploy_all() {
  stack_name=$1
  if [ -z "$stack_name" ]; then
    stack_name=$STACK_NAME
  fi
  deploy graphql $stack_name
  deploy kafka $stack_name
  deploy "gpl-datacollection" $stack_name
}

# 不pull镜像，部署所有服务
# deploy_all_offline [stack_name]
# - stack_name ： stack 名称，不传则为 colorless
function deploy_all_offline() {
  stack_name=$1
  if [ -z "$stack_name" ]; then
    stack_name=$STACK_NAME
  fi
  deploy_offline graphql $stack_name
  deploy_offline kafka $stack_name
  deploy_offline "gpl-datacollection" $stack_name
}

function pull_image() {
  image=$1
  if [ -z $image ]; then
    logError "image参数未指定"
    return
  fi
  docker pull $image
}

function _usage_update_service() {
  logInfo "用法： update_service {stack} {service} {image}"
}

# 更新服务，用法如下：
# update_service {stack} {service} {image}
# update_service colorless graphql-engine zh-registry.colorless.com.cn/colorless/graphql-engine:1aaa7ad9
# 本函数按如下流程执行：
# 1. 获取镜像；
# 2. 更新服务；如更新失败，则尝试回滚服务；
# 3. 如更新成功，则修改本地yml文件；
function update_service() {
  # 要更新的stack
  stack=$1
  # 要更新的服务
  service=$2
  # 服务的镜像
  image=$3
  if [ -z "$stack" ]; then
    logError "stack 参数不能为空"
    _usage_update_service
    return 1
  fi
  if [ -z "$service" ]; then
    logError "service 参数不能为空"
    _usage_update_service
    return 1
  fi
  if [ -z "$image" ]; then
    logError "image 参数不能为空"
    _usage_update_service
    return 1
  fi
  logInfo "获取镜像：$image"
  pull_image "$image"
  if [ $? -eq 1 ]; then
    logError "镜像获取失败"
    return 1
  fi
  service_name="${stack}_${service}"
  logInfo "开始更新服务：docker service update $service_name --image=$image"
  docker service update "$service_name" --image="$image"
  update_result=$?
  logInfo "当前服务状态: "
  docker stack services $stack
  # 更新失败
  if [ $update_result -eq 1 ]; then
    logError "更新失败，确定是否需要回滚服务"
    docker service ls --format="{{.Image}}" | grep -E "^$image$"
    find_image=$?
    if [ $find_image -eq 0 ]; then
      logInfo "开始回滚服务：$service_name"
      docker service rollback "$service_name"
      logInfo "回滚完成，输出服务状态：(可手动确认服务状态)"
      docker service ls
    else
      logInfo "无需回滚"
    fi
    # 直接退出
    logError "更新失败，即将退出，请手动检查服务镜像是否正常"
    return 1
  fi
  # 更新成功，开始更新本地yml部署脚本
  logInfo "开始更新本地yml部署脚本"
  update_service_yaml_config "$stack" "$service" "$image"
}

# 更新本地的yml文件配置
function update_service_yaml_config() {
  # 要更新的stack
  stack=$1
  # 要更新的服务
  service=$2
  # 服务的镜像
  image=$3
  if [ -z "$stack" ]; then
    logError "stack 参数不能为空"
    return 1
  fi
  if [ -z "$service" ]; then
    logError "service 参数不能为空"
    return 1
  fi
  if [ -z "$image" ]; then
    logError "image 参数不能为空"
    return 1
  fi
  service_name="${stack}_${service}"

  # 查找需要修改的文件(根据服务名查找，排除arm）
  # -H 输出匹配的文件路径
  # -v 过滤掉 arm
  # -print0 | xargs -0 用于处理文件名中可能存在的特殊字符
  # 这里 /b:/b 的匹配模式 确保有空格的情况下尽可能的匹配到service
  # 完成后输出类似如下：
  # ./graphql/docker-compose-20210325.yml:  graphql-engine:
  # ./graphql/docker-compose.yml:  graphql-engine:
  # 获取需要修改的文件列表
  #   IFS=" " read -r -a file_list <<< find . -type f -name "*.yml" -print0 | xargs -0 -I {} grep -H "$service *: *$" {} | grep -v "arm" | awk -F: '{print $1}' | tr "\n" " "
#  file_list=($(find . -type f -name "*.yml" -print0 | xargs -0 -I {} grep -H "$service *: *$" {} | grep -v "arm" | awk -F: '{print $1}' | tr "\n" " "))
# 上面变量的写法在gitlab-runner上有问题
#  for file in "${file_list[@]}"; do
  for file in $(find . -type f -name "*.yml" -print0 | xargs -0 -I {} grep -H "$service *: *$" {} | grep -v "arm" | awk -F: '{print $1}' | tr "\n" " "); do
    logInfo 开始修改文件:"$file"
    # 获取文件中的镜像全名 " *" 匹配一个或多个空格
    # 注意：这里通过服务名称来查找镜像名称，通过 grep -A 4 多输出四行，然后在这四行中寻找image段，从而获取文件中对应service的image的全名
    raw_image=$(grep -A 4 "$service *: *$" "$file" | grep image | sed 's/.*image: *//g')
    logInfo "备份文件: $file.bak"
    #    cp -f "$file" "$file.bak"
    # 开始修改文件
    sed "$(getSedOption)" "s|$raw_image|$image|g" "$file"
    if [ $? -eq 0 ]; then
      confirm_ed_result=$(grep "$image" "$file")
      if [ -n "$confirm_ed_result" ]; then
        logInfo "修改成功"
        logInfo "服务更新完成"
      else
        logError "文件修改失败"
      fi
    else
      logError "文件修改失败"
    fi
  done
}

# 导出所有镜像
function export_all_images() {
  export_images graphql
  export_images kafka
  export_images "gpl-datacollection"
}

echo "导入部署脚本成功"

```

### 调查

观察如下一个具体的deploy的job，我们可以有如下提取方向：

1. 将整个job都提取出去；
2. 将script段提取出来；
3. 将部署任务集中到一个单独的部署项目，各个服务模块更新后触发部署项目进行部署；

```yaml
deploy:
  stage: deploy
  script:
    - echo $HARBOR_PWD | docker login --username=$HARBOR_USER $DOCKER_REGISTRY --password-stdin
    - cd $DEPLOY_PATH
    #- sudo chmod 777 -R $DEPLOY_PATH   需要自行使用root用户添加权限
    - echo "$SERVICE_NAME"
    - echo "$DEPLOY_PATH"
    - echo "$DOCKER_REGISTRY/$DOCKER_NAMESPACE/$SERVICE_NAME:$CI_COMMIT_SHORT_SHA"
    - source deploy.sh
    - update_service $DOCKER_NAMESPACE $SERVICE_NAME $DOCKER_REGISTRY/$DOCKER_NAMESPACE/$SERVICE_NAME:$CI_COMMIT_SHORT_SHA
  environment:
    name: test_env_deploy
    url: $APP_URL/
  when: manual
  only:
    - branches
    - web
  tags:
    - deploy_graphql
```

接下来，我们带着上述两个问题来寻找相关的技术支持 - 即：gitlab能帮助我们做到哪些及什么程度？

经过简单的调查我们可以知道，gitlabci的配置中，有一个`include` 的配置可以引入外部的yaml，我们详细了解下这个配置（[Keyword reference for the .gitlab-ci.yml file | GitLab](https://docs.gitlab.com/ee/ci/yaml/README.html#include)）

而提取脚本是一个比较确定可以实现的事情，所以我们不予调查；

#### **include**

**用途：**

1. 在ci配置中导入外部的yaml配置；
2. 拆分长的配置，提升可读性；
3. 提取公共的配置，减少重复配置；
4. 拆分放置到中心仓库，在其他项目中引入；

**支持的源**：

| Keyword                                                      | Method                                      |
| :----------------------------------------------------------- | :------------------------------------------ |
| [`local`](https://docs.gitlab.com/ee/ci/yaml/README.html#includelocal) | 本项目中的文件                              |
| [`file`](https://docs.gitlab.com/ee/ci/yaml/README.html#includefile) | 引入其他项目中的文件                        |
| [`remote`](https://docs.gitlab.com/ee/ci/yaml/README.html#includeremote) | 引入远程的URL中的文件（必须能被公开访问到） |
| [`template`](https://docs.gitlab.com/ee/ci/yaml/README.html#includetemplate) | 引入Gitlab提供的模板文件                    |

这里我们主要查看`file`- 即如何引入其他项目中的文件；

**基本用法：**（需要使用project指定项目）

项目的地址是相对于根目录（`/`）

```yaml
include:
  - project: 'my-group/my-project'
    file: '/templates/.gitlab-ci-template.yml'
```

**指定分支/Tag/提交：**(通过ref指定)

```yaml
include:
  - project: 'my-group/my-project'
    ref: main
    file: '/templates/.gitlab-ci-template.yml'

  - project: 'my-group/my-project'
    ref: v1.0.0
    file: '/templates/.gitlab-ci-template.yml'

  - project: 'my-group/my-project'
    ref: 787123b47f14b552955ca2786bc9542ae66fee5b  # Git SHA
    file: '/templates/.gitlab-ci-template.yml'
```

**同时引入多个文件：**（file中使用数组语法）

```yaml
include:
  - project: 'my-group/my-project'
    ref: main
    file:
      - '/templates/.builds.yml'
      - '/templates/.tests.yml'
```

**嵌套引入：**

所有嵌套的includes都在当前目标项目的范围内执行，所以可以使用local (相对于目标项目), project, remote, 或者 template includes。

* 可以最多有 100 个 includes；
* 不能有重复的include

* 在[GitLab 12.4](https://gitlab.com/gitlab-org/gitlab/-/issues/28212) 及后续版本中, 解析所有文件的时间被限制在30秒之内，所以可能需要考虑文件的复杂度；

**权限：**

执行人需要具有项目的权限；

All [nested includes](https://docs.gitlab.com/ee/ci/yaml/README.html#nested-includes) are executed only with the permission of the user, so it’s possible to use project, remote or template includes.

#### trigger

gitlab可以使用trigger来触发多项目构建，在gitlab-ci配置中，可以使用trigger来定义一个下游流水线的触发器，当Gitlab启动这个trigger的任务时，会创建一个下游流水线；

对比于正常的任务，trigger类型的任务只有少量关键字可以使用；

Gitlab中可使用trigger创建两种类型的下游流水线：

1. 多项目流水线： 触发其他项目的流水线；
2. 子流水线： 触发当前项目的流水线；

**多项目流水线的触发任务基本写法：**

```yaml
rspec:
  stage: test
  script: bundle exec rspec

staging:
  stage: deploy
  trigger: my/deployment
```

**多项目流水线的触发任务复杂写法：**

* 通过branch指定分支

    ```yaml
    rspec:
      stage: test
      script: bundle exec rspec

    staging:
      stage: deploy
      trigger:
        project: my/deployment
        branch: stable
    ```

* 镜像下流流水线的状态(通过设置`strategy: depend`,默认情况下，触发器任务会被标记为成功，设置此标记后，则会等待下游流水线执行完成，然后使用下流流水线的状态来标记该触发器任务的状态)

  ```yaml
  trigger_job:
  trigger:
    project: my/project
    strategy: depend
  ```

* 在下游流水线中，也可以获取上游流水线的状态

    ```shell
    upstream_bridge:
      stage: test
      needs:
        pipeline: other/project
    ```

**子流水线的写法：**

* 指定项目中的YAML文件的路径即可创建子流水线

  ```shell
  trigger_job:
    trigger:
      include: path/to/child-pipeline.yml
  ```

* 同样的，也可以设置获取下游状态

  ```yaml
  trigger_job:
    trigger:
      include:
        - local: path/to/child-pipeline.yml
      strategy: depend
  ```

* 可以使用其他项目中的YAML文件来定义子流水线

  ```yaml
  child-pipeline:
    trigger:
      include:
        - project: 'my-group/my-pipeline-library'
          ref: 'main'
          file: '/path/to/child-pipeline.yml'
  ```

* 可以使用自动生成的配置来生成子流水线(参考：[Parent-child pipelines | GitLab](https://docs.gitlab.com/ee/ci/parent_child_pipelines.html#dynamic-child-pipelines))

  ```yaml
  generate-config:
    stage: build
    script: generate-ci-config > generated-config.yml
    artifacts:
      paths:
        - generated-config.yml
  
  child-pipeline:
    stage: test
    trigger:
      include:
        - artifact: generated-config.yml
          job: generate-config
  ```

### 整体方案

通过上面的分析，我们可以看到

* gitlab支持通过`include`来引入外部的脚本，脚本可以来自于本项目，也可以来自于其他项目；
* 通过`trigger`可以触发其他项目的流水线或者在本项目中生成一个子流水线，可以选择跟踪子流水线的执行状态；

经过如上分析，我们决定使用如下方案对现有部署需求进行实施：


<svg width="982px" height="690px" viewBox="0 0 982 690" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
    <g id="🐶-colorless部署策略" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd">
        <g id="PPT" transform="translate(-417.000000, -233.000000)">
            <g id="colorless" transform="translate(863.000000, 481.000000)">
                <g id="架构图/标题/带栏框/圆角">
                    <g id="分组">
                        <rect id="边框栏" stroke="#FF9500" x="0.5" y="0.5" width="226" height="155" rx="6"></rect>
                        <path d="M6,0 L221,0 C224.313708,-1.44363618e-14 227,2.6862915 227,6 L227,32 L227,32 L0,32 L0,6 C4.82366169e-16,2.6862915 2.6862915,1.4968968e-15 6,0 Z" id="标题栏" fill="#FF9500"></path>
                    </g>
                    <text id="标题" font-family="PingFangSC-Regular, PingFang SC" font-size="18" font-weight="normal" letter-spacing="0.107999999" fill="#FFFFFF">
                        <tspan x="35.5778135" y="22">colorless部署仓库</tspan>
                    </text>
                </g>
                <g id="架构图/标题/纯标题/直角备份-2" transform="translate(42.000000, 78.000000)">
                    <rect id="标题框" fill="#34C759" x="0" y="0" width="142" height="31"></rect>
                    <text id="标题" font-family="NotoSansCJKsc-Medium, Noto Sans CJK SC" font-size="14" font-weight="400" letter-spacing="0.153999999" fill="#FFFFFF">
                        <tspan x="43.0598756" y="21.5">部署服务</tspan>
                    </text>
                </g>
            </g>
            <g id="TokenManager" transform="translate(417.000000, 233.000000)">
                <g id="架构图/标题/带栏框/圆角">
                    <g id="分组">
                        <rect id="边框栏" stroke="#FF9500" x="0.5" y="0.5" width="260" height="149" rx="6"></rect>
                        <path d="M6,0 L255,0 C258.313708,-6.08718376e-16 261,2.6862915 261,6 L261,32 L261,32 L0,32 L0,6 C-4.05812251e-16,2.6862915 2.6862915,6.08718376e-16 6,0 Z" id="标题栏" fill="#FF9500"></path>
                    </g>
                    <text id="标题" font-family="PingFangSC-Regular, PingFang SC" font-size="18" font-weight="normal" letter-spacing="0.107999999" fill="#FFFFFF">
                        <tspan x="66.0686269" y="22">TokenManager</tspan>
                    </text>
                </g>
                <g id="架构图/标题/纯标题/直角" transform="translate(34.000000, 52.000000)">
                    <rect id="标题框" fill="#34C759" x="0" y="0" width="193" height="31"></rect>
                    <text id="标题" font-family="NotoSansCJKsc-Medium, Noto Sans CJK SC" font-size="14" font-weight="400" letter-spacing="0.153999999" fill="#FFFFFF">
                        <tspan x="69.826" y="21.5">构建JAR</tspan>
                    </text>
                </g>
                <g id="架构图/标题/纯标题/直角备份" transform="translate(34.000000, 99.000000)">
                    <rect id="标题框" fill="#34C759" x="0" y="0" width="193" height="31"></rect>
                    <text id="标题" font-family="NotoSansCJKsc-Medium, Noto Sans CJK SC" font-size="14" font-weight="400" letter-spacing="0.153999999" fill="#FFFFFF">
                        <tspan x="44.745" y="21.5">打包Docker镜像</tspan>
                    </text>
                </g>
                <path id="直线" d="M131,82 L131,90 L135,90 L130.5,99 L126,90 L130,90 L130,82 L131,82 Z" fill="#979797" fill-rule="nonzero"></path>
            </g>
            <g id="RESTAPI" transform="translate(417.000000, 413.000000)">
                <g id="架构图/标题/带栏框/圆角">
                    <g id="分组">
                        <rect id="边框栏" stroke="#FF9500" x="0.5" y="0.5" width="260" height="149" rx="6"></rect>
                        <path d="M6,0 L255,0 C258.313708,-6.08718376e-16 261,2.6862915 261,6 L261,32 L261,32 L0,32 L0,6 C-4.05812251e-16,2.6862915 2.6862915,6.08718376e-16 6,0 Z" id="标题栏" fill="#FF9500"></path>
                    </g>
                    <text id="标题" font-family="PingFangSC-Regular, PingFang SC" font-size="18" font-weight="normal" letter-spacing="0.107999999" fill="#FFFFFF">
                        <tspan x="95.9576269" y="22">RestAPI</tspan>
                    </text>
                </g>
                <g id="架构图/标题/纯标题/直角" transform="translate(34.000000, 52.000000)">
                    <rect id="标题框" fill="#34C759" x="0" y="0" width="193" height="31"></rect>
                    <text id="标题" font-family="NotoSansCJKsc-Medium, Noto Sans CJK SC" font-size="14" font-weight="400" letter-spacing="0.153999999" fill="#FFFFFF">
                        <tspan x="69.826" y="21.5">构建JAR</tspan>
                    </text>
                </g>
                <g id="架构图/标题/纯标题/直角备份" transform="translate(34.000000, 99.000000)">
                    <rect id="标题框" fill="#34C759" x="0" y="0" width="193" height="31"></rect>
                    <text id="标题" font-family="NotoSansCJKsc-Medium, Noto Sans CJK SC" font-size="14" font-weight="400" letter-spacing="0.153999999" fill="#FFFFFF">
                        <tspan x="44.745" y="21.5">打包Docker镜像</tspan>
                    </text>
                </g>
                <path id="直线" d="M131,82 L131,90 L135,90 L130.5,99 L126,90 L130,90 L130,82 L131,82 Z" fill="#979797" fill-rule="nonzero"></path>
            </g>
            <g id="GraphQLAPI" transform="translate(417.000000, 593.000000)">
                <g id="架构图/标题/带栏框/圆角">
                    <g id="分组">
                        <rect id="边框栏" stroke="#FF9500" x="0.5" y="0.5" width="260" height="149" rx="6"></rect>
                        <path d="M6,0 L255,0 C258.313708,-6.08718376e-16 261,2.6862915 261,6 L261,32 L261,32 L0,32 L0,6 C-4.05812251e-16,2.6862915 2.6862915,6.08718376e-16 6,0 Z" id="标题栏" fill="#FF9500"></path>
                    </g>
                    <text id="标题" font-family="PingFangSC-Regular, PingFang SC" font-size="18" font-weight="normal" letter-spacing="0.107999999" fill="#FFFFFF">
                        <tspan x="69.7226269" y="22">GraphQLAPI引擎</tspan>
                    </text>
                </g>
                <g id="架构图/标题/纯标题/直角" transform="translate(34.000000, 52.000000)">
                    <rect id="标题框" fill="#34C759" x="0" y="0" width="193" height="31"></rect>
                    <text id="标题" font-family="NotoSansCJKsc-Medium, Noto Sans CJK SC" font-size="14" font-weight="400" letter-spacing="0.153999999" fill="#FFFFFF">
                        <tspan x="82.846" y="21.5">构建</tspan>
                    </text>
                </g>
                <g id="架构图/标题/纯标题/直角备份" transform="translate(34.000000, 99.000000)">
                    <rect id="标题框" fill="#34C759" x="0" y="0" width="193" height="31"></rect>
                    <text id="标题" font-family="NotoSansCJKsc-Medium, Noto Sans CJK SC" font-size="14" font-weight="400" letter-spacing="0.153999999" fill="#FFFFFF">
                        <tspan x="44.745" y="21.5">打包Docker镜像</tspan>
                    </text>
                </g>
                <path id="直线" d="M131,82 L131,90 L135,90 L130.5,99 L126,90 L130,90 L130,82 L131,82 Z" fill="#979797" fill-rule="nonzero"></path>
            </g>
            <g id="其他服务" transform="translate(417.000000, 773.000000)">
                <g id="架构图/标题/带栏框/圆角">
                    <g id="分组">
                        <rect id="边框栏" stroke="#FF9500" x="0.5" y="0.5" width="260" height="149" rx="6"></rect>
                        <path d="M6,0 L255,0 C258.313708,-6.08718376e-16 261,2.6862915 261,6 L261,32 L261,32 L0,32 L0,6 C-4.05812251e-16,2.6862915 2.6862915,6.08718376e-16 6,0 Z" id="标题栏" fill="#FF9500"></path>
                    </g>
                    <text id="标题" font-family="PingFangSC-Regular, PingFang SC" font-size="18" font-weight="normal" letter-spacing="0.107999999" fill="#FFFFFF">
                        <tspan x="83.7086269" y="22">其他服务…</tspan>
                    </text>
                </g>
                <g id="架构图/标题/纯标题/直角" transform="translate(34.000000, 52.000000)">
                    <rect id="标题框" fill="#34C759" x="0" y="0" width="193" height="31"></rect>
                    <text id="标题" font-family="NotoSansCJKsc-Medium, Noto Sans CJK SC" font-size="14" font-weight="400" letter-spacing="0.153999999" fill="#FFFFFF">
                        <tspan x="82.846" y="21.5">构建</tspan>
                    </text>
                </g>
                <g id="架构图/标题/纯标题/直角备份" transform="translate(34.000000, 99.000000)">
                    <rect id="标题框" fill="#34C759" x="0" y="0" width="193" height="31"></rect>
                    <text id="标题" font-family="NotoSansCJKsc-Medium, Noto Sans CJK SC" font-size="14" font-weight="400" letter-spacing="0.153999999" fill="#FFFFFF">
                        <tspan x="44.745" y="21.5">打包Docker镜像</tspan>
                    </text>
                </g>
                <path id="直线" d="M131,82 L131,90 L135,90 L130.5,99 L126,90 L130,90 L130,82 L131,82 Z" fill="#979797" fill-rule="nonzero"></path>
            </g>
            <path id="直线-2" d="M792.124777,345 L792.124,566.999 L845,566.999 L845,559 L864,568.5 L845,578 L845,569.999 L789.124777,570 L789.124,347.999 L642,348 L642,345 L792.124777,345 Z" fill="#AFAFAF" fill-rule="nonzero"></path>
            <path id="直线-3" d="M676.006644,509.993385 L677.50663,510.000015 L790.631407,510.500015 L792.124777,510.506615 L792.124,567 L845,567 L845,559 L864,568.5 L845,578 L845,570 L789.124777,570 L789.124,513.492 L677.49337,512.999985 L675.993385,512.993356 L676.006644,509.993385 Z" fill="#AFAFAF" fill-rule="nonzero"></path>
            <path id="直线-4" d="M845,559 L864,568.5 L845,578 L845,570 L792.301,570 L792.301081,707 L642,707 L642,704 L789.301,704 L789.301081,567 L845,567 L845,559 Z" fill="#AFAFAF" fill-rule="nonzero"></path>
            <path id="直线-5" d="M845,559 L864,568.5 L845,578 L845,570 L792.301,570 L792.301081,889 L642,889 L642,886 L789.301,886 L789.301081,567 L845,567 L845,559 Z" fill="#AFAFAF" fill-rule="nonzero"></path>
            <text id="触发" font-family="PingFangSC-Regular, PingFang SC" font-size="18" font-weight="normal" letter-spacing="0.6264844" fill="#6272A4">
                <tspan x="710" y="340">触发</tspan>
            </text>
            <text id="触发备份" font-family="PingFangSC-Regular, PingFang SC" font-size="18" font-weight="normal" letter-spacing="0.6264844" fill="#6272A4">
                <tspan x="710" y="506">触发</tspan>
            </text>
            <text id="触发备份-2" font-family="PingFangSC-Regular, PingFang SC" font-size="18" font-weight="normal" letter-spacing="0.6264844" fill="#6272A4">
                <tspan x="710" y="700">触发</tspan>
            </text>
            <text id="触发备份-3" font-family="PingFangSC-Regular, PingFang SC" font-size="18" font-weight="normal" letter-spacing="0.6264844" fill="#6272A4">
                <tspan x="710" y="882">触发</tspan>
            </text>
            <g id="部署机器" transform="translate(1195.000000, 463.000000)">
                <g id="架构图/标题/纯标题/直角备份-2">
                    <rect id="标题框" fill="#AF52DE" x="0" y="0" width="193" height="31"></rect>
                    <text id="标题" font-family="NotoSansCJKsc-Medium, Noto Sans CJK SC" font-size="14" font-weight="400" letter-spacing="0.153999999" fill="#FFFFFF">
                        <tspan x="67.649" y="21.5">postgres</tspan>
                    </text>
                </g>
                <g id="架构图/标题/纯标题/直角备份-3" transform="translate(0.000000, 46.000000)">
                    <rect id="标题框" fill="#AF52DE" x="0" y="0" width="193" height="31"></rect>
                    <text id="标题" font-family="NotoSansCJKsc-Medium, Noto Sans CJK SC" font-size="14" font-weight="400" letter-spacing="0.153999999" fill="#FFFFFF">
                        <tspan x="80.095" y="21.5">redis</tspan>
                    </text>
                </g>
                <g id="架构图/标题/纯标题/直角备份-4" transform="translate(0.000000, 92.000000)">
                    <rect id="标题框" fill="#AF52DE" x="0" y="0" width="193" height="31"></rect>
                    <text id="标题" font-family="NotoSansCJKsc-Medium, Noto Sans CJK SC" font-size="14" font-weight="400" letter-spacing="0.153999999" fill="#FFFFFF">
                        <tspan x="41.847" y="21.5">graphql-engine</tspan>
                    </text>
                </g>
                <g id="架构图/标题/纯标题/直角备份-5" transform="translate(0.000000, 138.000000)">
                    <rect id="标题框" fill="#AF52DE" x="0" y="0" width="193" height="31"></rect>
                    <text id="标题" font-family="NotoSansCJKsc-Medium, Noto Sans CJK SC" font-size="14" font-weight="400" letter-spacing="0.153999999" fill="#FFFFFF">
                        <tspan x="45.69" y="21.5">graphql-token</tspan>
                    </text>
                </g>
                <g id="架构图/标题/纯标题/直角备份-6" transform="translate(0.000000, 184.000000)">
                    <rect id="标题框" fill="#AF52DE" x="0" y="0" width="193" height="31"></rect>
                    <text id="标题" font-family="NotoSansCJKsc-Medium, Noto Sans CJK SC" font-size="14" font-weight="400" letter-spacing="0.153999999" fill="#FFFFFF">
                        <tspan x="41.476" y="21.5">graphql-restapi</tspan>
                    </text>
                </g>
                <g id="架构图/标题/纯标题/直角备份-7" transform="translate(0.000000, 228.000000)">
                    <rect id="标题框" fill="#AF52DE" x="0" y="0" width="193" height="31"></rect>
                    <text id="标题" font-family="NotoSansCJKsc-Medium, Noto Sans CJK SC" font-size="14" font-weight="400" letter-spacing="0.153999999" fill="#FFFFFF">
                        <tspan x="89.048" y="21.5">…</tspan>
                    </text>
                </g>
            </g>
            <path id="直线-6" d="M1161,565 L1180,574.5 L1161,584 L1161,576 L1089,576 L1089,573 L1161,573 L1161,565 Z" fill="#979797" fill-rule="nonzero"></path>
            <text id="deploy" font-family="PingFangSC-Regular, PingFang SC" font-size="18" font-weight="normal" letter-spacing="0.6264844" fill="#6272A4">
                <tspan x="1104" y="562">deploy</tspan>
            </text>
            <g id="架构图/标题/带栏框/圆角" transform="translate(1179.000000, 418.500000)">
                <g id="分组">
                    <rect id="边框栏" stroke="#FF9500" x="0.5" y="0.5" width="219" height="318" rx="6"></rect>
                    <path d="M6,0 L214,0 C217.313708,-6.08718376e-16 220,2.6862915 220,6 L220,32 L220,32 L0,32 L0,6 C-4.05812251e-16,2.6862915 2.6862915,6.08718376e-16 6,0 Z" id="标题栏" fill="#FF9500"></path>
                </g>
                <text id="标题" font-family="PingFangSC-Regular, PingFang SC" font-size="18" font-weight="normal" letter-spacing="0.107999999" fill="#FFFFFF">
                    <tspan x="72.5016166" y="22">部署机器</tspan>
                </text>
            </g>
        </g>
    </g>
</svg>

1. 每个项目分别定义自己的构建和镜像打包任务；
2. 镜像打包完成后通过`trigger`来触发colorless部署仓库的部署任务，需要传递自己的信息给部署仓库生成的流水线；
3. 触发任务的定义文件放置到colorless部署仓库中，在各个服务项目中通过`include`来引入；

## 优化方案实现

如上所述，我们将部署操作集中到一个单独项目中，而又各个服务项目触发其部署流程，这里我们将这个单独的用于部署的项目称为独立部署项目，将其他服务的项目称之为子服务项目；以下分别说明上述方案中两种项目中的配置方式；

### 各子服务项目的配置

#### gitlab-ci.yml配置

我们将部署任务替换为一个触发任务，并从独立部署项目中引入任务的配置

```yaml
stages:
  - test
  - build
  - build_image
  - auto-build-deploy

# 省略其他定义

# 引入触发自动编译部署任务配置 
include:
  - project: 'Deptproduct-project/colorless/colorless-deploy'
    # ref: master
    file: '/ci/gitlab-ci-base.yml'
```

这段配置会从 `Deptproduct-project/colorless/colorless-deploy` 项目中导入 `/ci/gitlab-ci-base.yml` 的配置，具体内容如下：

```yaml
# 子模块用的公用触发项目，可以在子模块源码中 include
trigger:auto-build-deploy:
  stage: auto-build-deploy
  variables:
    TRIGGER_CI_COMMIT_SHORT_SHA: $CI_COMMIT_SHORT_SHA
    #  配置仓库环境
    # 自定义变量必须配置在上游UI界面
    DOCKER_REGISTRY: $DOCKER_REGISTRY
    DOCKER_NAMESPACE: $DOCKER_NAMESPACE
    HARBOR_PWD: $HARBOR_PWD
    HARBOR_USER: $HARBOR_USER
    SERVICE_NAME: $SERVICE_NAME
  trigger:
    project: Deptproduct-project/colorless/colorless-deploy
```

在子项目中的ci配置中`include`该文件时，会生成一个触发任务，这个触发任务会触发`Deptproduct-project/colorless/colorless-deploy`这个项目，也就是我们的独立部署项目；

也就是说会触发我们独立部署项目生成一个流水线，此时流水线读取的就是我们独立部署项目的`.gitlab-ci.yml` 文件；

####  web UI中CI/CD变量配置

上述的触发任务的配置中，我们定义了几个变量，用于向部署项目的流水线说明我们自身的一些信息

```yaml
    TRIGGER_CI_COMMIT_SHORT_SHA: $CI_COMMIT_SHORT_SHA
    DOCKER_REGISTRY: $DOCKER_REGISTRY
    DOCKER_NAMESPACE: $DOCKER_NAMESPACE
    HARBOR_PWD: $HARBOR_PWD
    HARBOR_USER: $HARBOR_USER
    SERVICE_NAME: $SERVICE_NAME
```

其中，由我们自行定义的变量（`$DOCKER_REGISTRY`,`DOCKER_NAMESPACE`,`$HARBOR_PWD`,`$HARBOR_USER`,`$SERVICE_NAME`）需要在项目/群组的CI的变量中进行配置，在解析此触发任务时才可以读取到；

![202203192303519](https://s2.loli.net/2022/05/26/tLyelhx2DPbznmV.png)

### 独立部署项目的配置

#### gitlab-ci.yml 配置

```yaml
variables:
#  UI界面配置 DEPLOY_PATH
  DEPLOY_PATH: /Wksp/colorlessWork/colorless-deploy/deploy/
#  部署的stack
  DOCKER_STACK: colorless

deploy:
  stage: deploy
  script:
    - echo $HARBOR_PWD | docker login --username=$HARBOR_USER $DOCKER_REGISTRY --password-stdin
    - cd $DEPLOY_PATH
    - source deploy.sh
    - update_service $DOCKER_STACK $SERVICE_NAME $DOCKER_REGISTRY/$DOCKER_NAMESPACE/$SERVICE_NAME:$TRIGGER_CI_COMMIT_SHORT_SHA
  environment:
    name: test_env_deploy
    url: $APP_URL/
  when: manual
  tags:
    - deploy_graphql
```

#### web UI中CI/CD变量配置

现在，我们有些部署相关的变量需要从子服务项目中提取到当前独立部署项目中来定义，包括：`DEPLOY_PATH`,`DOCKER_STACK`,`APP_URL`，其中`DEPLOY_PATH`,`DOCKER_STACK`我们在yml中有定义默认值，可以不在UI界面中进行定义，只需要在UI界面中定义APP_URL即可；

### 运行效果说明

1. 每次子服务项目中提交代码，且满足ci配置中定义的条件时，即会生成一个触发任务，执行完前期阶段的任务后，当执行触发任务时，就会触发我们的独立仓库的部署任务。具体界面如下图所示；

![20210526155720](https://s2.loli.net/2022/05/26/dQ9ZWJeE7GOcqYz.png)

2. 点击下游任务即可跳转到我们的独立部署仓库中对应的流水线中；

![202203192305536](https://s2.loli.net/2022/05/26/38HPnbIrW17AiUY.png)

3. 点击deploy任务的运行按钮，即可进行部署；

4. 部署完成后，可在独立部署仓库中生成一个部署环境，点击即可前往；

   ![202203192306371](https://s2.loli.net/2022/05/26/Xf8ygsvLGwIzbqE.png)

