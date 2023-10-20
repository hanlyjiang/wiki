

## Dagger 源码下载并导入到IDEA

### bazel 简要说明

首先，我们看到Dagger的构建方式之后会一脸懵逼，因为它用的不是Maven，不是Gradle，而是[Bazel](https://bazel.build/)。Bazel是类似前面说的Maven及Gradle的构建工具。下面有些文章及网站可以参考：

- [Bazel 与 Gradle 构建工具差异对比 - 掘金 (juejin.cn)](https://juejin.cn/post/7020693024829079565)
- [Importing a Project - IntelliJ with Bazel](https://ij.bazel.build/docs/import-project.html)

现在我们当然只想能够快点看源码，至于Bazel，我并不关心，so，我尝试了给IDEA 安装 Bazel插件，然后导入项目。

<img src="https://gitee.com/hanlyjiang/image-repo/raw/master/image/202203082316194.png" alt="image-20220308231650123" style="zoom: 50%;" />

> 

###  安装

环境：macOS 12.2.1

执行如下命令安装：

```shell
export BAZEL_VERSION=4.2.0
curl -fLO "https://github.com/bazelbuild/bazel/releases/download/$BAZEL_VERSION/bazel-$BAZEL_VERSION-installer-darwin-x86_64.sh"
chmod u+x bazel-$BAZEL_VERSION-installer-darwin-x86_64.sh
# 注意这里官方网站上有个 --user，千万不能加
./bazel-$BAZEL_VERSION-installer-darwin-x86_64.sh 

echo PATH=${USER_HOME}/bin:$PATH >>~/.bashrc

source ~/.bashrc
which bazel
# 输出 /usr/local/bin/bazel
```

将 IDEA 中

> 安装过程可参考：[dagger/CONTRIBUTING.md at master · google/dagger (github.com)](https://github.com/google/dagger/blob/master/CONTRIBUTING.md#building-dagger)
>
> 👇下面是踩过的坑：
>
> 1. brew 安装的版本为 5.0.0 ，dagger项目中配置的为4.2.0，所以不能使用brew 安装的版本，否则可能遇到错误：
>
>    ```shell
>    ERROR: no such package '@io_bazel_rules_kotlin//kotlin': /private/var/tmp/_bazel_hanlyjiang/cf83d906aa6ed63f707573e42e864342/external/io_bazel_rules_kotlin_head: 
>    ERROR: The project you're trying to build requires Bazel 4.2.0 (specified in /private/var/tmp/_bazel_hanlyjiang/cf83d906aa6ed63f707573e42e864342/external/io_bazel_rules_kotlin_head/.bazelversion), but it wasn't found in /usr/local/Cellar/bazel/5.0.0/libexec/bin.
>    ```
>
> 2. 调用 `bazel-$BAZEL_VERSION-installer-darwin-x86_64.sh ` 时，官方文档上写的是添加一个 `--user` 的选项，将 bazel 安装到 用户目录下的 bin目录，但是后续执行同步的时候会有问题（应该是`/private/var/tmp/`目录权限问题），所以不能加 `--user` 。

### 同步

在 dagger 源码目录执行：

```shell
$ bazel sync
Loading: loading...
Loading: loading...
Loading: loading...
Loading: loading...
    Fetching @io_bazel_rules_kotlin; Building //:rules_kotlin_release in io_bazel_rules_kotlin_head... (may take a while.) 433s
```

然后进入漫长的等待时间。

> 首次同步的过程可能异常漫长😂，可以看到 bazel 下载的临时文件目录(`/private/var/tmp/_bazel_hanlyjiang`) 有 9.5 个G
>
> ```shell
> $ du -h -d 1 /private/var/tmp/_bazel_hanlyjiang
> 1.0G	/private/var/tmp/_bazel_hanlyjiang/b496136483b84f5de955421ead3eea4d
> 258M	/private/var/tmp/_bazel_hanlyjiang/install
> 4.9G	/private/var/tmp/_bazel_hanlyjiang/cf83d906aa6ed63f707573e42e864342
> 3.3G	/private/var/tmp/_bazel_hanlyjiang/cache
> 9.5G	/private/var/tmp/_bazel_hanlyjiang
> ```
>
> 中途的下载量已经达到了 8个多G，而此时，sync还没有完成，不知道还有多少要下载。
>
> <img src="https://gitee.com/hanlyjiang/image-repo/raw/master/image/202203090013161.png" alt="image-20220309001321128" style="zoom:50%;" />
>
> so 真不觉得这个bazel是个好东西。
>
> 更新使用量：
>
> ```shell
> $ du -h -d 1 /private/var/tmp/_bazel_hanlyjiang
> 1.0G	/private/var/tmp/_bazel_hanlyjiang/b496136483b84f5de955421ead3eea4d
> 258M	/private/var/tmp/_bazel_hanlyjiang/install
> 6.0G	/private/var/tmp/_bazel_hanlyjiang/cf83d906aa6ed63f707573e42e864342
> 3.9G	/private/var/tmp/_bazel_hanlyjiang/cache
>  11G	/private/var/tmp/_bazel_hanlyjiang
> ```
>
> 至于要花多少时间，按自己的网速来算吧，而且它的同步站点可能是被屏蔽或者境外的慢速站点 😭😭😭
>
> 另外，还发现一个非常奇怪的点，它下载jdk时，居然需要下载 win 和 linux 平台的。

### IDEA 准备就绪

