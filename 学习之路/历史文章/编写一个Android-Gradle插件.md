---
title: '编写一个Android Gradle插件'
date: 2020-09-20 10:18:50
tags: [Android,Gradle]
published: true
hideInList: false
feature: 
isTop: false
---

gradle有三种编写插件的方式，我们这里使用在项目中的buildSrc模块中编写插件的方式，自定义了一个应用于Android项目的根据flavor过滤so库的gradle插件；

<!-- more -->

## 概述   

自定义gradle插件有如下三种方式（[🔗链接](https://docs.gradle.org/current/userguide/custom_plugins.html#sec:packaging_a_plugin)）：

1. 在buildscript中直接编写；
2. 在buildSrc项目中编写插件代码；
3. 在独立的项目中编写插件代码；

这里我们将使用buildSrc方式实现一个gradle插件。

## 新建 buildSrc module

gradle会在项目中寻找名称为buildSrc模块，将其加载为gradle的插件代码目录。所以我们直接通过菜单新建一个名为 buildSrc 的java/kotlin模块。

然后在build.gradle中添加相关的plugin(java-gradle-plugin)及依赖：

```groovy
plugins {
    id 'java'
    id 'java-gradle-plugin'
    id "org.jetbrains.kotlin.jvm" version '1.3.61'
}

group = "io.github.hanlyjiang.gradle"
version = "0.0.2"

dependencies {
    testCompile group: 'junit', name: 'junit', version: '4.12'
    // 添加android相关build tools依赖，以便使用 android gradle 相关的API
    compile 'com.android.tools.build:gradle:3.2.0'
}
```

## 编写插件

### 需求简介

* **应用场景：**我们的产品中集成了两种VPN SDK，但是具体到每个项目上面，都只会落地到具体的一种，这个时候需要排除对应的SDK的SO库以减小APP包大小，不同的地区的打包配置通过flavor来进行区分配置，即每个地区会对应不同的flavor；

* **需求提取**： 这里实际上我们需要的是能够根据flavor，在打包过程中移除指定的so文件；

* **实现思路：** 

  * flavor配置方式：在flavor中配置一个buildConfigField字段，用于指定我们的flavor需要的配置

    ```groovy
    // 配置VPN类型
    buildConfigField "String", "VPN_TYPE", "\"$VpnType.SANG_FOR\""
    ```

  * 插件配置：我们使用一个so_exclude配置来指定具体的exclude规则，包含两个字段。

    * buildConfigFieldKey 用于指定之前在flavor中定义的配置；
    * configMap 为一个配置表，指定上面的字段可取的值，即对应值应该exclude的so文件列表；

    ```groovy
    so_exclude {
        /**
         * 使用VPN_TYPE 来设置so过滤的规则
         */
        buildConfigFieldKey = "VPN_TYPE"
        configMap = [
                (VpnType.H3C_iNode.name()): [
                        // 新华三过滤深信服的
                        "lib/armeabi-v7a/libauth_forward.so",
                        "lib/armeabi-v7a/libhttps.so",
                        "lib/armeabi-v7a/libpkcs12cert.so",
                        "lib/armeabi-v7a/libsvpnservice.so"
                ],
                (VpnType.SANG_FOR.name()) : [
                        // 深信服过滤新华三的
                        "lib/armeabi-v7a/libies.so",
                ],
                (VpnType.NONE.name())     : [
                        // 如配置成 NONE，则过滤掉所有的VPN的
                        // 深信服的so
                        "lib/armeabi-v7a/libauth_forward.so",
                        "lib/armeabi-v7a/libhttps.so",
                        "lib/armeabi-v7a/libpkcs12cert.so",
                        "lib/armeabi-v7a/libsvpnservice.so",
                        // inode的so
                        "lib/armeabi-v7a/libies.so",
                ]
        ]
    }
    ```

### 定义插件及使用插件简介

* 插件需要继承 `org.gradle.api.Plugin`，可在Plugin对构建流程进行自定义（如：创建任务，定义任务关系，修改已有任务动作等）
* 插件如果需要能够读取一些配置，可通过 `project.extensions.create` 来从build.gradle中提取
* 如需在自己的 android代码模块中使用插件，通过 `apply plugin: 插件类引用即可`

### 插件实现

* 插件的实现如下：
  * 读取 so_exclude 配置，存储到 extension（类型为 FlavorSoExcludePluginExtension ）中
  * 读取 android 的配置，找到 AppExtension类型的配置，也就是应用了 `apply application` 的模块的配置，我们的项目中只有一个app模块应用此配置-即我们的apk模块；
  * 遍历所有变体，获取对应变体的 so_exclude 对应的配置字段的值，建立flavor到配置值的映射表；
  * 修改 packageApplication 任务，让其在执行之前即删除待打包临时目录中的对应so文件；

```kotlin
package io.github.hanlyjiang.gradle.plugin.soexclude

import com.android.build.gradle.AppExtension
import com.android.build.gradle.api.ApkVariantOutput
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.logging.LogLevel
import org.gradle.api.logging.Logger
import org.gradle.api.logging.Logging
import java.io.File

/**
 * so 插件的 gradle 配置实体
 */
open class FlavorSoExcludePluginExtension {

    /**
     * so 过滤配置表
     */
    var configMap: Map<String, List<String>>? = null

    /**
     * 配置字段的名称
     */
    var buildConfigFieldKey: String = FlavorSoExcludePlugin.DEFAULT_CONFIG_KEY
}

/**
 * flavor so 打包过滤配置
 *
 * ## 用法说明：
 *
 * 1. 在build.gradle 中引入插件 <code>apply plugin: FlavorSoExcludePlugin</code>;
 * 2. 添加 so_exclude 配置段：
 *
 * ```groovy
 * so_exclude {
 *   buildConfigFieldKey = "VPN_TYPE"
 *   configMap = [
 *       (VpnType.H3C_iNode.name()): [
 *           "lib/armeabi-v7a/libauth_forward.so",
 *           "lib/armeabi-v7a/libhttps.so",
 *           "lib/armeabi-v7a/libpkcs12cert.so",
 *           "lib/armeabi-v7a/libsvpnservice.so"
 *      ],
 *      (VpnType.SANG_FOR.name()) : [
 *           "lib/armeabi-v7a/libies.so",
 *       ],
 *       (VpnType.NONE.name())     : [
 *               // 深信服的so
 *               "lib/armeabi-v7a/libauth_forward.so",
 *               "lib/armeabi-v7a/libhttps.so",
 *               "lib/armeabi-v7a/libpkcs12cert.so",
 *               "lib/armeabi-v7a/libsvpnservice.so",
 *               // inode的so
 *               "lib/armeabi-v7a/libies.so",
 *        ]
 *   ]
 *}
 *```
 * 3. 在flavor的配置中添加 buildConfigField 配置，如：
 * ```
 * buildConfigField "String", "VPN_TYPE", "\"$VpnType.H3C_iNode\""
 * ```
 * 其中字段的名称为 之前 so_exclude 中配置的 `buildConfigFieldKey` 字段，对应的值为 configMap 中的 key ，如此配置后，打包时就会将configMap对应key中的so列表过滤掉
 * @author hanlyjiang 09/20/20 2:42 PM
 * @version 1.0
 */
class FlavorSoExcludePlugin : Plugin<Project> {
    companion object {
        const val PLUGIN_NAME = "FlavorSoExcludePlugin"
        const val DEFAULT_CONFIG_KEY = "SO_EXCLUDE"
        const val DEBUG = false

        private val logger: Logger = Logging.getLogger(FlavorSoExcludePlugin::class.java)

        fun logInfo(msg: String) {
            logger.log(LogLevel.LIFECYCLE, "<- $PLUGIN_NAME: $msg ->")
        }

        fun logDebug(msg: String) {
            if (DEBUG) {
                logInfo(msg)
            }
        }
    }

    lateinit var extension: FlavorSoExcludePluginExtension

    override fun apply(project: Project) {
        // 添加自己的配置
        extension = project.extensions.create("so_exclude", FlavorSoExcludePluginExtension::class.java)

        // 创建一个打印配置的任务，用于定义
        val task = project.tasks.create("printConfig")
        task.group = "soExclude-plugin"
        task.doLast {
            logInfo("-- 配置字段：buildConfigFieldKey= " + extension.buildConfigFieldKey)
            logInfo("-- 当前配置：")
            extension.configMap?.run {
                this.keys.forEach { key ->
                    logInfo("-- config: $key -- ")
                    get(key)?.forEach {
                        logInfo("values: $it")
                    }
                    logInfo("------------------ ")
                }
            }
        }
		// 获取android的配置
        val androidExtensions = project.extensions.getByName("android")
        logInfo("" + androidExtensions.javaClass)
        if (androidExtensions is AppExtension) { 
            // applicatoin类型的就进行任务处理
            initPackageOptions(project, androidExtensions)
        }
    }


    /**
     * vpn 配置
     */
    private var configMap: MutableMap<String, String> = HashMap()

    private fun initPackageOptions(project: Project, android: AppExtension) {
        project.afterEvaluate {
            android.productFlavors.all {
                val flavorName = it.name
                logDebug("--productFlavors : ${it.name}")
                var soExcludeConfig = ""
                it.buildConfigFields[extension.buildConfigFieldKey]?.run {
                    soExcludeConfig = value.replace("\"", "")
                }
                logDebug("--productFlavors : $flavorName, soExcludeConfig: $soExcludeConfig")
                configMap[flavorName] = soExcludeConfig
            }
            android.applicationVariants.all { variant ->
                logDebug("app variant flavorName: ${variant.flavorName}")
                val flavorName = variant.flavorName
                val configKey = configMap[flavorName]
                variant.outputs.forEach { output ->
                    if (output is ApkVariantOutput) {
                        //核心逻辑：修改packageApplication任务，在生成apk包之前，删除打包临时目录中的so文件即可避免打包so到apk中
                        output.packageApplication.doFirst {
                            output.packageApplication.jniFolders.all {
                                // jniFolder 目录为最后打包apk时，用于存放so文件的临时目录
                                logInfo("变体名称: ${variant.flavorName} , configKey: ${configKey}, jniFolders: " + it.absoluteFile)
                                handleExclude(it, configKey);
                                true
                            }
                        }
                    }
                }
            }
        }
    }

    private fun handleExclude(jniFolder: File?, configKey: String?) {
        extension.configMap?.run {
            val soExcludeList: List<String>? = get(configKey)
            soExcludeList?.run {
                deleteJniSoFiles(jniFolder, *(soExcludeList.toTypedArray()))
            }
        }

    }

    private fun deleteJniSoFiles(jniFolder: File?, vararg files: String) {
        for (item in files) {
            val file = File(jniFolder, item)
            if (file.exists()) {
                val deleteResult = file.delete()
                logInfo("删除so文件 $item : ${if (deleteResult) "成功" else "失败"}")
            }
        }
    }

}

```



## 使用枚举进行配置

我们在buildSrc中定义一个枚举类，用于约定可以配置的值，即可以清晰定义配置值避免配置时直接写字符串容易出错，又可以支持代码自动补全方便配置。

```kotlin
package io.github.hanlyjiang.gradle.plugin.vpn

/**
 * VPN 类型
 */
enum class VpnType {
    /**
     * 深信服
     */
    SANG_FOR,

    /**
     * 新华三
     */
    H3C_iNode,

    /**
     * 不使用VPN
     */
    NONE,
}
/**
 * VPN 类型
 */
enum class VpnType {
    /**
     * 深信服
     */
    SANG_FOR,

    /**
     * 新华三
     */
    H3C_iNode,

    /**
     * 不使用VPN
     */
    NONE,
}
```

## 使用插件

1. 通过 apply plugin 引入插件，直接使用插件类名称即可；
2. 枚举配置使用，在gradle配置中导入对应的枚举类，然后直接使用即可：

具体配置如下：

```groovy
// app/build.gradle
import io.github.hanlyjiang.gradle.plugin.soexclude.FlavorSoExcludePlugin
import io.github.hanlyjiang.gradle.plugin.vpn.VpnType

apply plugin: 'com.android.application'
// 应用插件
apply plugin: FlavorSoExcludePlugin

so_exclude {
    /**
     * 使用VPN_TYPE 来设置so过滤的规则
     */
    buildConfigFieldKey = "VPN_TYPE"
    configMap = [
            (VpnType.H3C_iNode.name()): [
                    // 新华三过滤深信服的
                    "lib/armeabi-v7a/libauth_forward.so",
                    "lib/armeabi-v7a/libhttps.so",
                    "lib/armeabi-v7a/libpkcs12cert.so",
                    "lib/armeabi-v7a/libsvpnservice.so"
            ],
            (VpnType.SANG_FOR.name()) : [
                    // 深信服过滤新华三的
                    "lib/armeabi-v7a/libies.so",
            ],
            (VpnType.NONE.name())     : [
                    // 如配置成 NONE，则过滤掉所有的VPN的
                    // 深信服的so
                    "lib/armeabi-v7a/libauth_forward.so",
                    "lib/armeabi-v7a/libhttps.so",
                    "lib/armeabi-v7a/libpkcs12cert.so",
                    "lib/armeabi-v7a/libsvpnservice.so",
                    // inode的so
                    "lib/armeabi-v7a/libies.so",
            ]
    ]
}

android {
    defaultConfig {
        // 配置VPN类型
        buildConfigField "String", "VPN_TYPE", "\"$VpnType.SANG_FOR\""
    }
    productFlavors {
        // ...
    }
}
```

## 参考文档

- [自定义插件-官方文档](https://docs.gradle.org/current/userguide/custom_plugins.html)
- [再见吧 buildSrc, 拥抱 Composing builds 提升Android 编译速度](https://juejin.im/post/6844904176250519565)
- [如何判断任务是否UP-TO-DATE](https://www.jianshu.com/p/eb3fb33e4287)
- [如何让任务支持UP_TO_DATE-Gradle官方文档](https://docs.gradle.org/current/userguide/more_about_tasks.html#sec:up_to_date_checks)
- 创建任务-https://docs.gradle.org/current/dsl/org.gradle.api.Project.html#org.gradle.api.Project:task(java.util.Map,java.lang.String)
- [增量任务-Gradle官方文档](https://docs.gradle.org/current/userguide/custom_tasks.html#incremental_tasks)
- [增量构建如何实现？-gradle官方文档](https://docs.gradle.org/current/userguide/more_about_tasks.html#sec:how_does_it_work)