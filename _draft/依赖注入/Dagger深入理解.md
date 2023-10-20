# Dagger 深入理解

## Singleton 的 Provider 方法的区别

### 有/无 Singleton + provider

声明方式：

```java
@Module
public abstract class NormalObjModule {

    @Provides
    static TestSingleton provideTestSingleton() {
        return new TestSingleton();
    }
}
```

生成的工厂：

```java
public final class NormalObjModule_ProvideTestSingletonFactory implements Factory<TestSingleton> {
  @Override
  public TestSingleton get() {
    return provideTestSingleton();
  }

  public static NormalObjModule_ProvideTestSingletonFactory create() {
    return InstanceHolder.INSTANCE;
  }

  public static TestSingleton provideTestSingleton() {
      return Preconditions.checkNotNullFromProvides(NormalObjModule.provideTestSingleton());
  }

  private static final class InstanceHolder {
    private static final NormalObjModule_ProvideTestSingletonFactory INSTANCE = new NormalObjModule_ProvideTestSingletonFactory();
  }
}
```

注入方式Component生成代码：

```java
  private Provider<TestSingleton> provideTestSingletonProvider;

	@Override
  public void inject(SdkContainer sdkContainer) {
    injectSdkContainer(sdkContainer);
  }

 @SuppressWarnings("unchecked")
  private void initialize(final Application applicationParam) {
// 使用Singleton注解时有这一句
    this.provideTestSingletonProvider = DoubleCheck.provider(NormalObjModule_ProvideTestSingletonFactory.create());
  }

// 并且使用provider进行注入工作
  private SdkContainer injectSdkContainer(SdkContainer instance) {
    SdkContainer_MembersInjector.injectAndroidInjector(instance, dispatchingAndroidInjectorOfObject());
    // 使用Singleton 注解
    SdkContainer_MembersInjector.injectTestSingleton(instance, provideTestSingletonProvider.get());
    // 不使用Singleton 注解
    SdkContainer_MembersInjector.injectTestSingleton(instance, NormalObjModule_ProvideTestSingletonFactory.provideTestSingleton());
    SdkContainer_MembersInjector.injectTestObj(instance, NormalObjModule_ProviderTestOjbFactory.providerTestOjb());
    return instance;
  }
```

可以看到，如果**没有使用** `@Singleton` 注解，则相当于每次注入对象时，都直接调用我们自己定义的 provider 方法（`NormalObjModule.provideTestSingleton()`） 

而使用  `@Singleton` 注解时，则会有一个 `provideTestSingletonProvider` 用于缓存，保证组件中该实例唯一。

### 无 Singleton provider，直接使用Singleton标记类

```java
@Singleton
public class TestSingleton {
    @Inject
    public TestSingleton() {
    }
}
```

1. 删除了提供对象的ProviderFactory

2. 添加了一个Factory，实际上和之前的那个Factory差别不大，只是获取实例对象的方式变成了直接 `new TestSingleton()` ，而之前使用的是我们提供的 Provider方法（`NormalObjModule.provideTestSingleton()`)

   ```java
   public final class TestSingleton_Factory implements Factory<TestSingleton> {
     @Override
     public TestSingleton get() {
       return newInstance();
     }
   
     public static TestSingleton_Factory create() {
       return InstanceHolder.INSTANCE;
     }
   
     public static TestSingleton newInstance() {
       return new TestSingleton();
     }
   
     private static final class InstanceHolder {
       private static final TestSingleton_Factory INSTANCE = new TestSingleton_Factory();
     }
   }
   ```

3. 使用时差别不大，同样使用了provider成员变量来缓存。

<img src="https://gitee.com/hanlyjiang/image-repo/raw/master/image/202203072140408.png" alt="image-20220307214056373" style="zoom: 50%;" />





## Singleton 的实现

DoubleCheck 实现的缓存机制。

```java
public final class DoubleCheck<T> implements Provider<T>, Lazy<T> {
  private static final Object UNINITIALIZED = new Object();

  private volatile Provider<T> provider;
  private volatile Object instance = UNINITIALIZED;

  private DoubleCheck(Provider<T> provider) {
    assert provider != null;
    this.provider = provider;
  }  
  
	@Override
  public T get() {
    Object result = instance;
    if (result == UNINITIALIZED) {
      synchronized (this) {
        result = instance;
        if (result == UNINITIALIZED) {
          result = provider.get();
          instance = reentrantCheck(instance, result);
          /* Null out the reference to the provider. We are never going to need it again, so we
           * can make it eligible for GC. */
          provider = null;
        }
      }
    }
    return (T) result;
  }
  
}
```

### Singleton 和自定义Scope注解的区别

**没有啥区别**，都一样使用了DoubleCheck来进行缓存，生成的工厂代码也一样

```java
  private Provider<TestSingleton> testSingletonProvider;

this.testSingletonProvider = DoubleCheck.provider(TestSingleton_Factory.create());

  private SdkContainer injectSdkContainer(SdkContainer instance) {
    SdkContainer_MembersInjector.injectTestSingleton(instance, testSingletonProvider.get());
    return instance;
  }

// 自定义Scope MvpScope>
    private Provider<TestMvpScope> testMvpScopeProvider;
this.testMvpScopeProvider = DoubleCheck.provider(TestMvpScope_Factory.create());

    @Override
    public TestMvpScope testMvpScope() {
      return testMvpScopeProvider.get();
    }
```

