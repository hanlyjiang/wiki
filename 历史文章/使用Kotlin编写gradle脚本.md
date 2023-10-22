---
title: '使用Kotlin编写gradle脚本'
date: 2022-02-24 22:29:04
tags: [Gradle]
published: true
hideInList: false
feature: 
isTop: false
---


将gradle 脚本从 groovy 迁移到 kotlin dsl。

<!-- more -->

## 概述

### IDE 支持

|                          | Build import | Syntax highlighting <sub>1</sub> | Semantic editor <sub>2</sub> |
| -----------------------: | :----------: | :------------------------------: | :--------------------------: |
|            IntelliJ IDEA |    **✓**     |              **✓**               |            **✓**             |
|           Android Studio |    **✓**     |              **✓**               |            **✓**             |
|              Eclipse IDE |    **✓**     |              **✓**               |              ✖               |
|                    CLion |    **✓**     |              **✓**               |              ✖               |
|          Apache NetBeans |    **✓**     |              **✓**               |              ✖               |
| Visual Studio Code (LSP) |    **✓**     |              **✓**               |              ✖               |
|            Visual Studio |    **✓**     |                ✖                 |              ✖               |

1. Gradle Kotlin DSL scripts 中的Kotlin语法高亮
2.  Gradle Kotlin DSL scripts 中支持代码补全，导航到源码，文档查看，重构等等；

### Kotlin DSL 脚本命名

#### 命名

Groovy DSL script 文件使用 `.gradle` 扩展文件名

Kotlin DSL script 文件使用 `.gradle.kts` 扩展文件名

#### 激活并使用 kotlin dsl

* 将脚本文件命名为 `.gradle.kts` 即可激活。也适用于 [settings file](https://docs.gradle.org/current/userguide/build_lifecycle.html#sec:settings_file)（ `settings.gradle.kts`)和 [initialization scripts](https://docs.gradle.org/current/userguide/init_scripts.html#init_scripts).
* 为了得到更好的IDE支持，建议使用如下命名约定：
  * Settings脚本命名为 `*.settings.gradle.kts`（包括所有从settings脚本中引入的脚本）
  * [initialization scripts](https://docs.gradle.org/current/userguide/init_scripts.html#init_scripts) 按 `*.init.gradle.kts`的命名模式命名，或者简单的取名为 `init.gradle.kts`。
* kotlin DSL 构建脚本隐式的导入了如下内容：
  * [default Gradle API imports](https://docs.gradle.org/current/userguide/writing_build_scripts.html#script-default-imports)
  * 在`org.gradle.kotlin.dsl` 和 `org.gradle.kotlin.dsl.plugins.dsl` 包中的Kotlin DSL API



### kotlin中读取运行时属性

> [Gradle Kotlin DSL Primer](https://docs.gradle.org/current/userguide/kotlin_dsl.html#kotdsl:properties)

gradle 拥有两种运行时属性:

1.  [*project properties*](https://docs.gradle.org/current/userguide/build_environment.html#sec:project_properties) 
2. [*extra properties*](https://docs.gradle.org/current/userguide/writing_build_scripts.html#sec:extra_properties)

#### 项目属性

可以通过kotlin的代理属性来访问:

**build.gradle.kts**

```kotlin
// 属性必须存在
val myProperty: String by project  
// 属性可以不存在
val myNullableProperty: String? by project 
```

#### extra 属性

extra属性在任意实现了[ExtensionAware](https://docs.gradle.org/current/dsl/org.gradle.api.plugins.ExtensionAware.html#org.gradle.api.plugins.ExtensionAware) 接口的对象上都可以访问; 

**build.gradle.kts**

```kotlin
val myNewProperty by extra("initial value")   // ❶
val myOtherNewProperty by extra { "calculated initial value" }   //❷ 

val myProperty: String by extra   // ❸
val myNullableProperty: String? by extra   // ❹
```

❶ 在当前上下文(当前为project中)创建一个名为`myNewProperty`新的extra属性,并且初始化其值为 "initial value"

❷ 同 ❶ ，不过属性的初始值是通过lamdba表达式来计算的;

❸ 绑定当前上下文(当前为project)中的属性到myProperty属性中;

❹ 同 ❸ ，不过允许值为null；

#### 在子项目中访问rootProject的属性

```kotlin
val myNewProperty: String by rootProject.extra
```

> `by`是kotlin的关键字，表示 provided by ，即属性由某个其他的对象代理

#### 在任务中定义和使用属性

任务也继承了ExtensionAware，所以我们也可以在任务中使用extra属性

```kotlin
tasks {
    test {
        val reportType by extra("dev")  
        doLast {
            // Use 'suffix' for post processing of reports
        }
    }

    register<Zip>("archiveTestReports") {
        val reportType: String by test.get().extra  
        archiveAppendix.set(reportType)
        from(test.get().reports.html.destination)
    }
}
```

#### 通过map格式定义和访问extra属性

```kotlin
extra["myNewProperty"] = "initial value"   // ❶

tasks.create("myTask") {
    doLast {
        println("Property: ${project.extra["myNewProperty"]}")  // ❷ 
    }
}
```



## 迁移gradle构建逻辑到Kotlin

> 参考文档：
>
> 1. [Migrating build logic from Groovy to Kotlin (gradle.org)](https://docs.gradle.org/current/userguide/migrating_from_groovy_to_kotlin_dsl.html)
> 2. [Android Gradle脚本从Groovy迁移到Kotlin DSL - 圣骑士wind - 博客园 (cnblogs.com)](https://www.cnblogs.com/mengdd/p/android-gradle-migrate-from-groovy-to-kotlin.html)

### 准备groovy脚本

1. 引号统一为双引号
2. 方法调用加上括号
3. 赋值操作加上等号

#### 引号统一

* 通过==⌘⇧R==快捷键调出查找替换工具窗，将文件匹配设置为 `.gradle` ，然后将所有单引号替换为双引号。

* 完成之后重新使用gradle文件同步项目，查看是否有错误

#### 赋值和属性修改

* 将所有的赋值操作添加上等号
* 所有的函数调用操作添加括号

这里就需要根据实际情况进行调整了。



### 重命名文件

将 `.gradle`文件重命名为`.gradle.kts`，通过如下命令可以完成重命名操作

```shell
find . -name "*.gradle" -type f | xargs -I {} mv {} {}.kts
```



### 其他常见修改

#### 在kotlin rootProject脚本中访问 gradle 属性

```kotlin
allprojects {
    repositories {
        maven {
            name = "Sonatype-Snapshots"
            setUrl("https://oss.sonatype.org/content/repositories/snapshots")
            credentials(PasswordCredentials::class.java) {
                username = property("ossrhUsername").toString()
                password = property("ossrhPassword").toString()
            }
        }
        google()
        jcenter()
        mavenCentral()
    }
}
```



#### 定义任务

```kotlin
tasks.register("clean", Delete::class.java) {
    group = "build"
    delete(rootProject.buildDir)
}
```



## 迁移配置实例

### rootProject kotlin dsl build脚本模板

```kotlin
// Top-level build file where you can add configuration options common to all sub-projects/modules.
buildscript {
    // 定义extra 属性
    val kotlin_version by extra("1.4.32")
    val android_gradle_build_version by extra("4.1.3")
    repositories {
        maven { setUrl("https://maven.aliyun.com/repository/gradle-plugin") }
        maven { setUrl("https://maven.aliyun.com/repository/jcenter") }
        maven { setUrl("https://maven.aliyun.com/repository/google") }
        maven { setUrl("https://maven.aliyun.com/repository/public") }
        google()
        jcenter()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:$android_gradle_build_version")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version")
        // NOTE: Do not place your application dependencies here; they belong
        // in the individual module build.gradle files
    }
}

allprojects {
    repositories {
        maven { setUrl("https://maven.aliyun.com/repository/jcenter") }
        maven { setUrl("https://maven.aliyun.com/repository/google") }
        maven { setUrl("https://maven.aliyun.com/repository/gradle-plugin") }
        maven { setUrl("https://maven.aliyun.com/repository/public") }
        // 加入项目临时仓库，方便测试
        maven {
            name = "ProjectLocal-Snapshots"
            setUrl(File(rootProject.rootDir, "local-maven-repo${File.separator}snapshots"))
        }
        maven {
            name = "ProjectLocal-Release"
            setUrl(File(rootProject.rootDir, "local-maven-repo${File.separator}release"))
        }

        // 加入 maven snapshot 仓库及 release 仓库
        maven {
            name = "Sonatype-Snapshots"
            setUrl("https://oss.sonatype.org/content/repositories/snapshots")
        }
        maven {
            name = "Sonatype-Staging"
            setUrl("https://oss.sonatype.org/service/local/staging/deploy/maven2/")
            credentials(PasswordCredentials::class.java) {
                username = property("ossrhUsername").toString()
                password = property("ossrhPassword").toString()
            }
        }
        google()
        mavenCentral()
        jcenter()
    }
}

tasks.register("clean", Delete::class.java) {
    group = "build"
    delete(rootProject.buildDir)
}
```

### 模块 build.gradle 模块build脚本模板

```kotlin
plugins {
    id("com.android.library")
    id("signing")
    // 等同于 id("")
    `maven-publish`
    kotlin("android")
    kotlin("android.extensions")

    // 引入三方Gradle插件
    id("com.github.hanlyjiang.android_maven_pub") version ("0.0.9") apply (false)
}

android {
    compileSdkVersion(30)
    buildToolsVersion("30.0.3")

    defaultConfig {
        minSdkVersion(22)
        targetSdkVersion(30)
        versionCode(1)
        versionName("1.0.0")

        testInstrumentationRunner("androidx.test.runner.AndroidJUnitRunner")
        consumerProguardFiles("consumer-rules.pro")
    }

    buildTypes {
        getByName("release") {
            minifyEnabled(false)
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility(JavaVersion.VERSION_1_8)
        targetCompatibility(JavaVersion.VERSION_1_8)
    }
}

dependencies {
    implementation("org.jetbrains:annotations:21.0.1")
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.3")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.4.0")
    
    // StringRes 注解
    implementation("androidx.appcompat:appcompat:1.3.1")
    // 注解库 https://developer.android.com/jetpack/androidx/releases/annotation#annotation-1.2.0
    implementation("androidx.annotation:annotation:1.2.0")
}

// 创建自定义任务
tasks.create("showGitRepoInfo") {
    group = "help"
    doLast {
        println("${getGitBranch()}/${getGitRevision()}")
    }
}

// 扩展函数
fun String.execute(): String {
    val process = Runtime.getRuntime().exec(this)
    return with(process.inputStream.bufferedReader()) {
        readText()
    }
}

/**
 * Get git revision with work tree status
 *
 * @return
 */
fun getGitRevision(): String {
    val rev = "git rev-parse --short HEAD".execute().trim()
    val stat = "git diff --stat".execute().trim()
    return if (stat.isEmpty()) {
        rev
    } else {
        "$rev-dirty"
    }
}

/**
 * Get git branch name
 *
 * @return
 */
fun getGitBranch(): String {
    return "git rev-parse --abbrev-ref HEAD".execute().trim()
}
```

### 7.0.2 版本AGP插件配置实例-模块build脚本

```kotlin
plugins {
    id("com.android.application")
}

android {
    compileSdk = 31

    defaultConfig {
        applicationId = "com.github.hanlyjiang.sample"
        minSdk = 21
        targetSdk = 31
        versionCode = 1
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility(JavaVersion.VERSION_1_8)
        targetCompatibility(JavaVersion.VERSION_1_8)
    }

}

dependencies {
    implementation(files("../libs/lib-mod-release.aar"))

    // https://mvnrepository.com/artifact/io.reactivex.rxjava3/rxjava
    implementation("io.reactivex.rxjava3:rxjava:3.1.3")

    implementation("androidx.appcompat:appcompat:1.2.0")
    implementation("com.google.android.material:material:1.3.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.3")
    testImplementation("junit:junit:4.+")
    androidTestImplementation("androidx.test.ext:junit:1.1.2")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.3.0")
}
```

### 7.0.2 root Build gradle 脚本配置

```kotlin
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        jcenter() // Warning: this repository is going to shut down soon
        flatDir {
            dir("libs")
        }
    }
}
rootProject.name = "NoSuchMethodError"
include ':app'
include ':lib-mod'
```



## 限制/不足

在 kotlin dsl 脚本中引入其他独立的 kotlin 的dsl 脚本不方便，会存在无法识别相关依赖对象的问题，部分情况下还是得导入使用 groovy 编写的 gradle 脚本。




