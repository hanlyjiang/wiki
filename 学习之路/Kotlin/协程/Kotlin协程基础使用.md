# Kotlin 协程基础使用

本篇文章用于介绍协程的基础使用。

## 参考文章：

- [Coroutines guide | Kotlin Documentation (kotlinlang.org)](https://kotlinlang.org/docs/coroutines-guide.html)

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

- **结构化并行**：Kotlin协程遵循的原则，即：新的协程只能在指定的 CoroutineScope 中被启动，这样可以限制协程的生命周期，避免协程的丢失和泄露。外部的协程会一直等到它的所有的子协程都完成后才会完成。














