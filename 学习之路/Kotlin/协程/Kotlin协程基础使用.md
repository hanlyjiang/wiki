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
  
  - 如上述示例中的` launch`，就是一个协程构建器。launch 会启动一个协程，可以独立于其他代码运行。
    
    - 注意：launch 是定义在 CoroutineScope 的一个方法，所以必须在 CoroutineScope 中才可以使用， 下面的 runBlocking 就会创建一个 CoroutineScope
  
  - 示例中的 runBlocking 也是一个协程构建器，该构建器可以作为桥将非协程世界（main函数）与协程世界相连接（runBlocking 代码块）；
  
  - `async`：

- **挂起函数**
  
  - 如上述示例中的 delay 函数，可以讲协程挂起指定的时间，协程挂起期间，不会阻塞底层线程，并且允许其他协程使用底层的线程运行它们的代码。
  
  - 挂起函数可以在协程中像正常函数一样使用，不过它还有一些额外的特性：
    
    - 可以调用其他挂起函数来挂起协程的执行

- **coroutine scope**：
  -

- **Scope Builder**：（协程作用域构建器）
  
  - 可以通过 coroutineScope 来构建一个自定义的 scope，这个协程 scope 会等到其中所有启动的 children 完成之后才会完成。
  
  - 与 runBlocking 的相同与区别：
    
    - 都会等到其中的代码块和所有的子协程执行完毕之后才会结束
    
    - runBlocking 会阻塞底层线程，期间该线程无法执行其他代码，因为它是一个**普通函数**
    
    - coroutineScope 不会阻塞底层线程，因为它是一个**挂起函数**
  
  - coroutineScope 可以被用在任意挂起函数内部用于创建多个并行操作。
  
  - GlobalScope：绑定到应用生命周期的 scope，顶级的独立协程
    
    - 在 GlobalScope 中启动的协程是完全独立的，生命周期只受限与整个应用的生命周期
    
    - 在 GlobalScope 中启动的协程无法向结构化并行中一样自动完成或取消，不过你可以存储它的引用，然后手动等待其完成或者取消。

- **Coroutine context**：
  
  - 待补充

- **结构化并行**：Kotlin协程遵循的原则，即：新的协程只能在指定的 CoroutineScope 中被启动，这样可以限制协程的生命周期，避免协程的丢失和泄露。外部的协程会一直等到它的所有的子协程都完成后才会完成。
  
  - 子协程的生命周期绑定到 scope 上
  
  - 在发生错误或者用户取消操作时，scope 可以自动取消所有的子协程
  
  - scope 自动等待所有子协成执行完毕，如果 scope 关联到一个协程，那么直到该协程中启动的所有子协程完成之前，这个父协程不会结束。

- **Job**
  
  - launch 构建器会返回一个 Job 对象，通过这个对象来启动协程，可以通过 Job 来显示的等待协程完成。

- **CoroutineDispatcher**： 决定协程应该在哪个线程上运行。
  
  - `async` 可指定，如果不指定，则默认使用外层scope的 dispatcher
  - `Dispatchers.Default` 共享的线程池，提供和 CPU 核心数量相等的线程数量，不过单核也会有两个。
  - `Dispatchers.Main` 代表 UI 线程

- **Channels**: 用于协程间通讯的组件，类似于生产消费模式，一端发送，一端接收，实现协程间通讯。

- **取消协程**：
  
  - 所有 `kotlinx.coroutines` 包中的挂起函数都是可以取消的。它们会检测协程的取消动作并且在取消时抛出一个  [CancellationException](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/-cancellation-exception/index.html)
  
  - 不过，如果协程正在执行一项计算，并且没有检测取消动作，那么它就不会被取消
  
  - 如何使得计算代码可取消：
    
    - 在计算代码中检查 isActive 属性（isActive 是通过 CoroutineScope 创建的协程中的一个扩展属性）
    
    - 通过try finally 或 use 来在协程取消时关闭资源
    
    - finally 中使用挂起函数会抛出 CancellationException 异常，因为挂起函数是可以被挂起的，所以一般不建议这么做；如果确实需要，则可以通过 `withContext(NonCancellable) {...}` 包装代码来规避，使之不可取消；
  
  - 超时取消：
    
    - 通过 `withTimeout` 可以使得协程超时时取消，会抛出 kotlinx.coroutines.TimeoutCancellationException 异常，实际上是 [CancellationException](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/-cancellation-exception/index.html) 的子类
    
    - 通过`try {...} catch (e: TimeoutCancellationException) {...}`包裹之后可以在超时取消时执行一些逻辑
    
    - 如果不需要做任何处理，则可以使用  [withTimeoutOrNull](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/with-timeout-or-null.html)，这样就不会抛出异常，只是返回 null
    
    - withTimeout 的超时事件相对于运行于它包裹的代码块中的代码是异步的，它有可能在任意时刻发生，有可能在 withTimeout block 代码返回之前发生，如果在withTimeout block 中获取需要关闭的资源，但是在外部关闭，则有可能没有正确关闭，需要在外部持有其引用，以正确的关闭；（[Cancellation and timeouts | Kotlin Documentation](https://kotlinlang.org/docs/cancellation-and-timeouts.html#asynchronous-timeout-and-resources)）

## 问题

如何控制挂起和恢复的线程？

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





# Channels

编写具有共享可变状态的代码相当困难且容易出错（例如在使用回调的解决方案中）。一种更简单的方法是通过通信而不是使用常见的可变状态共享信息。Coroutines可以通过渠道相互沟通。

![Using channels](https://kotlinlang.org/docs/images/using-channel.png "Using channels")
