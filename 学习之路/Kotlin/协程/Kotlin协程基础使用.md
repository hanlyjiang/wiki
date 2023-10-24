# Kotlin 协程基础使用

本篇文章用于介绍协程的基础使用。

## 参考文章：

- 协程指南: [Coroutines guide | Kotlin Documentation (kotlinlang.org)](https://kotlinlang.org/docs/coroutines-guide.html)

- 协程基础：[Coroutines basics | Kotlin Documentation (kotlinlang.org)](https://kotlinlang.org/docs/coroutines-basics.html)

- [kotlinx.coroutines/README.md at master · Kotlin/kotlinx.coroutines (github.com)](https://github.com/Kotlin/kotlinx.coroutines/blob/master/README.md#using-in-your-projects)



## 添加依赖

协程并不是语言的基础部分，也不是标准库的内容，是属于官方库，需要添加`kotlinx-coroutines-core`依赖才能使用。

```kotlin
dependencies {
    testImplementation(kotlin("test"))
    // add dep: https://github.com/Kotlin/kotlinx.coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")
}
```

> 具体可参考：[kotlinx.coroutines/README.md at master · Kotlin/kotlinx.coroutines (github.com)](https://github.com/Kotlin/kotlinx.coroutines/blob/master/README.md#using-in-your-projects)



## 基础

### **什么是协程？**

<mark>协程是一个可以挂起的计算的实例。</mark>

协程可以让一块代码与其他代码并行运行。但是协程并不绑定到具体的线程，可能在一个线程挂起执行，并在另外一个线程中恢复执行。

```kotlin
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking

fun main() = runBlocking {
    launch {// 启动一个新的协程并且继续 StandaloneCoroutine
        delay(1000L) // 非阻塞 delay 1s
        println("World @${threadName()} $this")
    }
    println("Hello @${threadName()} $this") // BlockingCoroutine
}
/* output:
Hello @main BlockingCoroutine{Active}@67b92f0a
World @main StandaloneCoroutine{Active}@27a5f880
 */

fun threadName(): String = Thread.currentThread().name
```

### **关键概念**

- **协程 Builder:**
  
  - 如上述示例中的 launch，就是一个协程构建器。launch 会启动一个协程，可以独立与其他代码运行。
    
    - 注意：launch 是定义在 CoroutineScope 的一个方法，所以必须在 CoroutineScope 中才可以使用， 下面的 runBlocking 就会创建一个 CoroutineScope
  
  - 示例中的 runBlocking 也是一个协程构建器，该构建器可以作为桥将非协程世界（main函数）与协程世界相连接（runBlocking 代码块）；

- **挂起函数**
  
  - 如上述示例中的 delay 函数，可以讲协程挂起指定的时间，协程挂起期间，不会阻塞底层线程，并且允许其他协程使用底层的线程运行它们的代码。
  
  - 挂起函数可以在协程中像正常函数一样使用，不过它还有一些额外的特性：
    
    - 可以调用其他挂起函数来挂起协程的执行

- **Scope Builder**：（协程作用域构建器）
  
  - 可以通过 coroutineScope 来构建一个自定义的 scope，这个协程 scope 会等到其中所有启动的 children 完成之后才会完成。
  
  - 与 runBlocking 的相同与区别：
    
    - 都会等到其中的代码块和所有的子协程执行完毕之后才会结束
    
    - runBlocking 会阻塞底层线程，期间该线程无法执行其他代码，因为它是一个**普通函数**
    
    - coroutineScope 不会阻塞底层线程，因为它是一个**挂起函数**
  
  - coroutineScope 可以被用在任意挂起函数内部用于创建多个并行操作。

- **结构化并行**：Kotlin协程遵循的原则，即：新的协程只能在指定的 CoroutineScope 中被启动，这样可以限制协程的生命周期，避免协程的丢失和泄露。外部的协程会一直等到它的所有的子协程都完成后才会完成。

- **Job**
  
  - launch 构建器会返回一个 Job 对象，通过这个对象来启动协程，可以通过 Job 来显示的等待协程完成。



## 示例说明

### runBlocking 即 coroutineScope 的说明

```kotlin
@Throws(InterruptedException::class)
public actual fun <T> runBlocking(context: CoroutineContext, block: suspend CoroutineScope.() -> T): T {
    // ...
}


public suspend fun <R> coroutineScope(block: suspend CoroutineScope.() -> R): R {
   // ...
}
```

### Job

注意如果不使用 join，job 中的内容会在最后输出

```kotlin
fun main() = runBlocking {
    val job = launch {
        delay(1000L)
        printWord("World!")
    }
    printWord("Hello")
    job.join()
    printWord("Done")
}


/* output:
// 使用 join
2023-10-24 23:22:26.306: Hello @main BlockingCoroutine{Active}@e874448
2023-10-24 23:22:27.321: World! @main StandaloneCoroutine{Active}@13eb8acf
2023-10-24 23:22:27.323: Done @main BlockingCoroutine{Active}@e874448

// 不使用 join
2023-10-24 23:22:57.212: Hello @main BlockingCoroutine{Active}@e874448
2023-10-24 23:22:57.213: Done @main BlockingCoroutine{Active}@e874448
2023-10-24 23:22:58.230: World! @main StandaloneCoroutine{Active}@2a70a3d8
 */
```

### 轻量级的协程

实际上并没有启动新的线程，全是在当前线程中进行的，所以轻量

```kotlin
fun main() = runBlocking {
    repeat(50_000) {
        launch {
            delay(2000L)
            printWord("...")
        }
    }
}


/* output:
2023-10-24 23:26:46.832: ... @main StandaloneCoroutine{Active}@269a37bc
2023-10-24 23:26:46.832: ... @main StandaloneCoroutine{Active}@106e816c
2023-10-24 23:26:46.832: ... @main StandaloneCoroutine{Active}@53d3ae89
2023-10-24 23:26:46.832: ... @main StandaloneCoroutine{Active}@7c98bac0
2023-10-24 23:26:46.832: ... @main StandaloneCoroutine{Active}@bc85538
2023-10-24 23:26:46.832: ... @main StandaloneCoroutine{Active}@6fc9c0cc
...
 */
```



## 仓库

- https://gitee.com/ColorlessAndOdorless/learnkt.git






