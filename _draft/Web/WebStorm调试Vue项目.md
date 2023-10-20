# WebStorm 调试Vue项目



## **💻 版本信息：**

* macOS 12.0.1
* WebStorm 2021.2.3
* Vue 2.6.14

## 开启调试流程

实际上，开启调试的流程非常简单，但是网络上找了好些文章，描述都不太准确。无法成功。



使用WebStorm的项目向导新建Vue项目，会自动生成两个运行配置：

<img src="https://gitee.com/hanlyjiang/image-repo/raw/master/image/202112031011462.png" alt="image-20211203101153400" style="zoom:50%;" />

* Debug Application
* npm server



然后编写代码，打上断点，之后依次以Debug模式运行 `npm server` 及 `Debug Application`这两个运行配置即可。就是

1. 先选中 `npm server` 点那个 <span style="color:green;">绿色🐞</span>的图标；
2. 然后再选中  `Debug Application` 然后再点那个 <span style="color:green;">绿色🐞</span> 。



这个地方 第二步也可以不直接运行   `Debug Application`  ，在第一步运行成功之后，在debug的工具窗口中，找到 `npm serve` 的tab页下方的`Process Console`，按住 `Shift + Cmd` 然后点击其中`http://localhost:8080/` 的链接，即可自动运行 `Debug` 配置。

<img src="https://gitee.com/hanlyjiang/image-repo/raw/master/image/202112031029076.png" alt="image-20211203102909056" style="zoom:50%;" />

另外，如果遇到调试无法生效的时候，可以关闭项目或者关闭WebStorm之后，再重新开启进行尝试。

## 注意事项

* 断点的设置，包括是否启用/禁用所有断点的设置需要在启动  `Debug Application`  运行配置之前进行设置，如果启动之后再添加新的断点，或者禁用断点，是不会实时生效的，需要先停止原先的  `Debug Application` 的任务，然后重新启动  `Debug Application` 任务。

##  参考文档

* [Vue.js | WebStorm (jetbrains.com)](https://www.jetbrains.com/help/webstorm/vue-js.html#vue_running_and_debugging_debug)

