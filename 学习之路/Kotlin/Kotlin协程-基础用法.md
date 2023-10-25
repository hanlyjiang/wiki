# Kotlin 协程基础用法

看了一些书，感觉讲的不是特别好理解。

1. 不是很好看到全览图景；

2. 基础和扩展的地方看不清楚；

协程背后的想法是它们可以被挂起并回复。通过使用 suspend 关键字标记一个函数，就是在高速系统，它可以暂时挂起该函数，并稍后在另外一个线程上恢复，而不必自己编写复杂的多线程代码。

## 关键概念

- 挂起

- 恢复

- 协程构建器
  
  - runBlocking
  
  - launch
  
  - async、await
    
    - withContext 扩展
  
  - CoroutineScope

- 协程调度器

- Scope
  
  - CoroutineScope
  
  - GlobalScope
  
  - 自定义Scope：
  
  - ViewModelScope
