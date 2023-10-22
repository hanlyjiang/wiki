---
title: 'Dagger 在Android库(SDK)模块中的使用实践'
date: 2022-03-06 15:11:54
tags: [Android,源码分析,依赖注入,开源框架]
published: true
hideInList: false
feature: 
isTop: false
---


本文主要描述如何使用Dagger解决实际项目中遇到的问题，这两个问题是：

1. 如何在库（SDK）模块中使用Dagger依赖注入？
2. MVP中的Dagger依赖注入如何实现无感注入？

本文不会介绍如何使用Dagger，只专注于描述如上两个问题的解决的前因后果及解决方案。



<!-- more -->

## 背景

接手开发一个SDK，大致情况如下：

- 该SDK内部有若干界面，包括Activity，Fragment等
- 使用MVP架构

逐渐发现内部依赖混乱，在得空后，遂对其依赖部分进行重构改造。

### 为什么使用依赖注入进行改造？

主要是依赖混乱，单例的滥用导致依赖关系不明显，无法管理，无法测试

某些对象，我们在很多类中都需要使用，如 Retrofit 的请求对象，代表信息的标识字段等，此时为了避免通过构造函数或者setter方法来传递，就直接起了个单例，还有很多其他类似的情况，最终导致单例有10多个，调用单例 getInstance 的地方更是数不胜数。

导致我们要对对应的代码进行单元测试做mock操作异常困难，

1. 因为依赖关系太不明显，几乎得一行行找才能找到类或方法到底依赖了哪些对象
2. 同时mock的过程也变得麻烦，由于没有作为类成员，所以无法简单通过mock替换对应成员；

### 依赖注入改造的问题点

主要有如下问题：

<p style="color:red;">1. 没有Application。该模块为SDK，我们并不能直接修改Application对象，Application为集成方自行编写。</p>

<p style="color:red;">2. MVP的绑定。MVP绑定中模板代码较多，我们希望能尽可能的实现无感的注入。</p>

之所以提第一个问题，是因为Google 针对Android，在Dagger的基础上针对性的构建了一个Hilt 的依赖注入框架，能够减少Android中直接使用Dagger的模板代码。但是Hilt的使中有要求：

> **所有使用 Hilt 的应用都必须包含一个带有 `@HiltAndroidApp` 注释的 `Application` 类。**
>
> 参考： [使用 Hilt 实现依赖项注入  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/training/dependency-injection/hilt-android)

也就是必须能控制住Application，如上所述，我们作为一个SDK的提供方：

1. 是没有机会修改Application的代码的
2. 而且，我们也不能要求使用方去做这种限制；同时，如果使用方有使用 Hilt 呢，我们的代码是否会对其产生影响？

**故，我们只能直接使用Dagger。**



而另外一个问题在于MVP的架构限制，P 层需要持有V层的引用，也就是P依赖V，而V通常是Activity或者Fragment，而Activity及Fragment的创建过程由Android系统控制，所以在使用Dagger时我们需要添加一些模板代码（下方会说明），将 Activity及Fragment对象注入到 Dagger 的依赖图谱中。



## 没有 Application 的问题解决

首先，我们要解决的是没有Application的问题，那么没有Application会给我们带来哪些问题呢？

1. 无法使用 Hilt
2. 无法直接使用 dagger-android

这两个问题实际上是类似的，Hilt及Dagger-Android都是用于解决 Android 组件（Activity，Fragment，Service，BroadcastReceiver 等）的依赖注入的。但是他们都要求我们必须使用 Application。

### 为什么一定要Application？

首先，让我们看下 dagger-android 的使用方式，这里参考 [Google 的示例]([architecture-components-samples/GithubBrowserSample at master · android/architecture-components-samples](https://github.com/android/architecture-components-samples/tree/master/GithubBrowserSample)) 进行说明。

#### Dagger-Android 的使用

这里我们省略 gradle 依赖的引入部分，直接解释代码。

##### 1. Application 进行改造

如下代码所述，主要有如下修改：

1. 令 Application 实现 `HasActivityInjector` 接口；
2. Application 中注入一个类型为 `DispatchingAndroidInjector<Activity>` 的成员，同时通过HasActivityInjector接口定义的重载方法 `activityInjector()` 返回该成员。
3. 在 `Application.onCreate` 中调用 `AppInjector.init(this)` 执行注入操作。

至此，准备工作就完毕了，之后就可以使用Dagger 无感注入Activity或者Fragment了。

```kotlin
class GithubApp : Application(), HasActivityInjector {
    @Inject
    lateinit var dispatchingAndroidInjector: DispatchingAndroidInjector<Activity>

    override fun onCreate() {
        super.onCreate()
        if (BuildConfig.DEBUG) {
            Timber.plant(Timber.DebugTree())
        }
        AppInjector.init(this)
    }

    override fun activityInjector() = dispatchingAndroidInjector
}
```

AppInjector.init 的实现也很简单，实际上就是：

- 在 Activity Create 的时候调用 `AndroidInjection.inject(activity)` 及 
- 在 Fragment Create 的时候调用 `AndroidSupportInjection.inject(f)`

```kotlin
object AppInjector {
    fun init(githubApp: GithubApp) {
        DaggerAppComponent.builder().application(githubApp)
            .build().inject(githubApp)
        githubApp
            .registerActivityLifecycleCallbacks(object : Application.ActivityLifecycleCallbacks {
                override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {
                    handleActivity(activity)
                }
            })
    }

    private fun handleActivity(activity: Activity) {
        if (activity is HasSupportFragmentInjector) {
            AndroidInjection.inject(activity)
        }
        if (activity is FragmentActivity) {
            activity.supportFragmentManager
                .registerFragmentLifecycleCallbacks(
                    object : FragmentManager.FragmentLifecycleCallbacks() {
                        override fun onFragmentCreated(fm: FragmentManager,f: Fragment,savedInstanceState: Bundle?
                        ) {
                            if (f is Injectable) {
                                AndroidSupportInjection.inject(f)
                            }
                        }
                    }, true
                )
        }
    }
}
```

> `AndroidInjection.inject` 及 `AndroidSupportInjection.inject`为 dagger-android 提供的接口，我们后续进行分析。

##### 2. 使用

再完成上述准备工作之后，要想让Activity或者Fragment能够自动注入，只需要进行如下操作（我们同样还是参考[Google示例代码](https://github.com/android/architecture-components-samples/blob/master/GithubBrowserSample/app/src/main/java/com/android/example/github/di/MainActivityModule.kt)）

1. 在 Module 中使用`@ContributesAndroidInjector` 标记一个返回对应Activity（如MainActivity）的方法

```kotlin
// https://github.com/android/architecture-components-samples/blob/master/GithubBrowserSample/app/src/main/java/com/android/example/github/di/MainActivityModule.kt
@Module
abstract class MainActivityModule {
    @ContributesAndroidInjector(modules = [FragmentBuildersModule::class])
    abstract fun contributeMainActivity(): MainActivity
}
```

2. 当然还需要将这个Module包含到 AppComponent中（同时 AppComponent中需要包含 `AndroidInjectionModule`这个 dagger-android 提供的module）

```kotlin
// https://github.com/android/architecture-components-samples/blob/master/GithubBrowserSample/app/src/main/java/com/android/example/github/di/AppComponent.kt
@Singleton
@Component(
    modules = [
        AndroidInjectionModule::class,
        MainActivityModule::class]
)
interface AppComponent {
    // 删除其他部分
}
```

##### 3. 总结

也就是说，使用dagger-android时，在完成了准备动作之后，**后续只需要添加一个 `@ContributesAndroidInjector` 注解的方法，就可以让你的Activity支持自动依赖注入。**

### 为什么需要 Application

上面介绍了 dagger-android 的使用方式，实际上是为了展示在使用Dagger-Android之后，我们**可以无需对Activity进行修改，就可以自动向其中注入依赖**。 这里的修改实际上指的是手动在每个Activity 的 onCreate 方法调用Dagger组件的注入方法。

但是我们的问题并没有得到回答，即：

<b><span style="color:red;">为什么需要Application？</span></b>

现在，让我们看下 `AndroidInjection.inject(activity)` 的实现：(AndroidInjection 为dagger-android 库提供的辅助工具类)

```kotlin
public static void inject(Activity activity) {
    checkNotNull(activity, "activity");
    Application application = activity.getApplication();
    if (!(application instanceof HasActivityInjector)) {
      throw new RuntimeException(
          String.format(
              "%s does not implement %s",
              application.getClass().getCanonicalName(),
              HasActivityInjector.class.getCanonicalName()));
    }

    AndroidInjector<Activity> activityInjector =
        ((HasActivityInjector) application).activityInjector();
    checkNotNull(activityInjector, "%s.activityInjector() returned null", application.getClass());

    activityInjector.inject(activity);
  }
```

从代码中我们可以看到，执行了如下步骤：

1. **由Activity获取Application**；
2. 判断 Application 是否实现了 HasActivityInjector
3. 从 Application 获取 `AndroidInjector<Activity>`，然后使用此对象执行对目标Activity的注入。



另外，AndroidInjection 类还有对 Service，Fragment等的注入辅助方法，过程中也都类似对Activity的注入，会获取 Application 对象，然后从Application对象中获取AndroidInejctor，再用此对象进行目标组件的依赖注入。

所以，我们现在知道了为什么一定要Application了：

1. **实际上，是需要其中的 AndroidInjector ；**
2. **在各种Android组件中（Activity，Service，等）我们都能直接通过其获取到Application对象，这样就能找到存在于Application中的 AndroidInjector，然后执行注入操作。**

### 扩展 - AndroidInjector 哪里来的？

通过上面的分析，我们知道了为什么 dagger-android 一定需要Application，是为了获取其中的AndroidInjector 用来执行目标Android组件的注入操作。

那么，**这个 AndroidInjector 是哪里来的呢？**

由前面的GithubApp代码中我们看到，这个 AndroidInject 就是Application中使用了 `@Inject` 标记的类型为` DispatchingAndroidInjector<Activity>` 的对象

```kotlin
// AndroidInjection.inject(activity)
AndroidInjector<Activity> activityInjector =
        ((HasActivityInjector) application).activityInjector();    

// GithubApp
@Inject
lateinit var dispatchingAndroidInjector: DispatchingAndroidInjector<Activity>
override fun activityInjector() = dispatchingAndroidInjector
```

我们去Dagger 的生成代码中( `DaggerAppComponent` )中查找对应的类型 `DispatchingAndroidInjector<Activity>`

```java
// DaggerAppComponent.java  
	private DispatchingAndroidInjector<Activity> getDispatchingAndroidInjectorOfActivity() {
    return DispatchingAndroidInjector_Factory.newDispatchingAndroidInjector(
        getMapOfClassOfAndProviderOfFactoryOf());
  }

  private GithubApp injectGithubApp(GithubApp instance) {
    GithubApp_MembersInjector.injectDispatchingAndroidInjector(
        instance, getDispatchingAndroidInjectorOfActivity());
    return instance;
  }
 
	@Override
  public void inject(GithubApp githubApp) {
    injectGithubApp(githubApp);
  }

// GithubApp_MembersInjector.java
  @Override
  public void injectMembers(GithubApp instance) {
    injectDispatchingAndroidInjector(instance, dispatchingAndroidInjectorProvider.get());
  }

  public static void injectDispatchingAndroidInjector(
      GithubApp instance, DispatchingAndroidInjector<Activity> dispatchingAndroidInjector) {
    instance.dispatchingAndroidInjector = dispatchingAndroidInjector;
  }
```

可以看到 DaggerAppComponent中在注入`inject(GithubApp)`时，会将`DispatchingAndroidInjector<Activity>` 类型的依赖注入到 GithubApp 中。

> **更多细节：**
>
> 1. dagger-android-processor  处理其会根据 `@ContributesAndroidInjector` 自动生成一个Module的代码，内容如下：
>
>    ```java
>    @Module(subcomponents = MainActivityModule_ContributeMainActivity.MainActivitySubcomponent.class)
>    public abstract class MainActivityModule_ContributeMainActivity {
>      private MainActivityModule_ContributeMainActivity() {}
>    
>      @Binds
>      @IntoMap
>      @ActivityKey(MainActivity.class)
>      abstract AndroidInjector.Factory<? extends Activity> bindAndroidInjectorFactory(
>          MainActivitySubcomponent.Builder builder);
>    
>      @Subcomponent(modules = FragmentBuildersModule.class)
>      public interface MainActivitySubcomponent extends AndroidInjector<MainActivity> {
>        @Subcomponent.Builder
>        abstract class Builder extends AndroidInjector.Builder<MainActivity> {}
>      }
>    }
>    ```
>
>    - 此模块中定义了 `bindAndroidInjectorFactory` 方法，使用 `@Binds @IntoMap`生成  `Map<Class<? extends T>, Provider<AndroidInjector.Factory<? extends T>>>` 类型的Map
>    - 在这里注入到Map中的内容就是 `(MainActivity.class, MainActivitySubcomponent.Builder builder)`, 其中 `MainActivitySubcomponent.Builder`  用于构建 `MainActivitySubcomponent`
>    - `MainActivitySubcomponent` 继承了 `AndroidInjector<MainActivity>` 类，所以会有一个 `inject(MainActivity instance)`的方法，这个方法就是最中实现对 MainActivity 依赖注入的实现入口；
>
> 2. 同时 `dagger-android` 中的`DispatchingAndroidInjector` 类中，会声明对 类型`Map<Class<? extends T>, Provider<AndroidInjector.Factory<? extends T>>>` 的依赖，所以上面的`(MainActivity.class, MainActivitySubcomponent.Builder builder)`会自动被注入到 `DispatchingAndroidInjector` 对象中
>
>    ```java
>     public final class DispatchingAndroidInjector<T> implements AndroidInjector<T> {
>         private final Map<Class<? extends T>, Provider<AndroidInjector.Factory<? extends T>>>
>          injectorFactories;
>       
>         @Inject
>          DispatchingAndroidInjector(
>            Map<Class<? extends T>, Provider<AndroidInjector.Factory<? extends T>>> injectorFactories) {
>            this.injectorFactories = injectorFactories;
>          }
>     }
>    ```
>
> 3. 而这个 `DispatchingAndroidInjector<Activity>` 在 GithubApp中被声明为依赖，所以也会被自动注入，从而我们能在GithubApp中通过 AndroidInjection 获取到 `DispatchingAndroidInjector<Activity>`, 然后调用其 `MainActivitySubcomponent` ，然后调用其 inject 方法完成注入
>
>    ```java
>    public final class DispatchingAndroidInjector<T> implements AndroidInjector<T> { 
>    	public boolean maybeInject(T instance) {
>        Provider<AndroidInjector.Factory<? extends T>> factoryProvider =
>          // instance 类型为 MainActivity，所以可以获取到 Provider<MainActivitySubcomponent.Builder>
>            injectorFactories.get(instance.getClass());
>    		// 这里就通过 MainActivitySubcomponent.Builder 获取到 factory = MainActivitySubcomponent.Builder
>        AndroidInjector.Factory<T> factory = (AndroidInjector.Factory<T>) factoryProvider.get();
>        try {
>          AndroidInjector<T> injector =
>              checkNotNull(
>                  factory.create(instance), "%s.create(I) should not return null.", factory.getClass());
>    			// 上面调用  factory.create(instance) 就是调用 MainActivitySubcomponent.Builder.create 方法创建 MainActivitySubcomponent
>          // 这里的 inejctor 就是 MainActivitySubcomponent
>          // 然后通过 MainActivitySubcomponent 的 inejct(MainActivity) 方法来实现对 MainActivity 的注入
>          injector.inject(instance);
>          return true;
>        } catch (ClassCastException e) {
>          throw new InvalidInjectorBindingException(
>              String.format(
>                  "%s does not implement AndroidInjector.Factory<%s>",
>                  factory.getClass().getCanonicalName(), instance.getClass().getCanonicalName()),
>              e);
>        }
>      }
>    }
>    ```

### 总结

现在，我们对前面的内容总结一下：

**dagger-android 为了实现对于Activity等Android组件的无感注入，将Activity等注入的实现Component放在了Application的成员变量中**

### 解决方案

之所以选择Application对象，是因为其生命周期比较持久，和应用一致。而为了对Activity实现无感注入，使用到的只是被注入到Application中的 DispatchingAndroidInjector 对象。

故我们可以将Application替换为任意一个静态的对象即可，类似如下：

```java
public class SdkContainer implements HasAndroidInjector {
    @Inject
    protected DispatchingAndroidInjector<Object> androidInjector;

    @Override
    public AndroidInjector<Object> androidInjector() {
        return androidInjector;
    }
}

public class SdkInjector {
    private static final String TAG = "SdkInjector";

    private static SdkContainer sSdkContainer;

    public static SdkContainer getSdkContainer() {
        return sSdkContainer;
    }

    public static void init(Application application) {
        if (sSdkContainer != null) {
            return;
        }
        SdkComponent sSdkComponent = DaggerSdkComponent.builder()
                .application(application)
                .build();
        SdkInjector.sSdkContainer = new SdkContainer(sSdkComponent);
        sSdkComponent.inject(sSdkContainer);
    }
}

@Singleton
@Component(
        modules = {  AndroidInjectionModule.class,}
)
public interface SdkComponent {
    void inject(SdkContainer sdkContainer);
    @Component.Builder
    interface Builder {
        @BindsInstance
        Builder application(Application application);
        SdkComponent build();
    }
}
```

## MVP 架构的注入问题

### MVP 中的注入问题？

一个 Presenter 的一般构造方式如下：

```java
public class TestDiMvpActivityPresenter {
  public TestDiMvpActivityPresenter(TestDiView view) {}
}

public class TestDiMvpActivity extends Activity implements TestDiView {
}
```

可以看到Presenter构造时需要一个TestDiView，而这个TestDiView实际上是 TestDiMvpActivity，而我们无法手动构造 TestDiMvpActivity 的实例，只能等系统创建之后才能获取实例，然后进行注入，所以**一般MVP的注入写法如下**：

#### MVP 注入的一般写法

1. **定义子组件及模块**

```java
// 修改点1⃣️    
@Module(
          subcomponents = TestDiMvpActivityModule.MvpComponent.class
    )
    public interface TestDiMvpActivityModule {
  
      @Module
      class MvpModule {
          TestDiMvpActivityPresenter.TestDiView testDiView;
  
          public MvpModule(TestDiMvpActivityPresenter.TestDiView testDiView) {
              this.testDiView = testDiView;
          }
  
          @Provides
          public TestDiMvpActivityPresenter.TestDiView providerView() {
              return testDiView;
          }
      }
  
      @Subcomponent(modules = MvpModule.class)
      interface MvpComponent {
  
          void inject(TestDiMvpActivity activity);
  
          @Subcomponent.Builder
          interface Builder {
              MvpComponent build();
  
              Builder module(MvpModule mvpModule);
          }
      }
    }
```

2. **在 RootComponent 中注册模块并提供Builder获取函数**
```java
   @Singleton
   @Component(
           modules = {
             			 //  修改点2⃣️
                   TestDiMvpActivityModule.class,
           }
   )
   public interface SdkComponent {
	     // 修改点3⃣️
       TestDiMvpActivityModule.MvpComponent.Builder testDiMvpActivityMComponentBuilder();
   
       @Component.Builder
       interface Builder {
       }
   }
```

3. **使用时在 TestDiMvpActivity.onCreate** 中

```java
   public class TestDiMvpActivity extends Activity implements TestDiMvpActivityPresenter.TestDiView {
   
       @Override
       protected void onCreate(@Nullable  Bundle savedInstanceState) {
          // 修改点4⃣️
   				SdkInjector.getSdkComponent().testDiMvpActivityMComponentBuilder()
                   .module(new TestDiMvpActivityModule.MvpModule(this)).build()
                   .inject(this);
          super.onCreate(savedInstanceState);
       }
   }
```

<span style="color:green">**其实现原理在于：**</span>

<span style="color:green">1. 在Activity被系统初始化之后，在其onCreate中获取其实例 </span>

<span style="color:green">2. 将Activity实例传入到MvpModule中，然后由MvpModule中的 providers 方法来提供 View 层对象 </span>

<span style="color:green">3. 将 MvpModule作为参数构造MvpComponent，然后使用MvpComponent 的inject 方法对TestDiMvpActivity 执行注入动作。</span>

#### MVP 注入一般写法的问题

<span style="color:red;">**这里的的问题在于：**</span>

<span style="color:red;">1. 每添加一个Mvp的组件，都修改四个地方，添加起来非常麻烦，容易漏掉； </span>

<span style="color:red;">2. 每次添加组件都都需要修改顶层的 Root Component（示例代码中的SdkComponent）； </span>

<span style="color:red;">3. 需要在每个具体Mvp组件的生命周期方法（如MvpActiviy的onCreate）中添加注入代码，导致具体的实现知道了注入细节； </span>

### 解决方案

上面提到的问题就是新增一个支持注入的MVP组件太麻烦，我们希望使用一种修改点少的方案，而且对于组件无感的方案。就像 dagger-android 一样。

**现在我们先给出方案，以便能够快速的查看解决方案的全貌效果，然后再说明其中的关键细节**。

整体方案由如下主要流程：

#### 提供统一的Mvp模块及组件声明

我们希望最终增加一个组件时，只修改一个地方，不用修改 Dagger 父组件，故我们用一个统一的MvpModule来定义，在下面的例子中，我们添加了两个需要支持Mvp的组件，其中一个为Activity，一个为Fragment。增加一个Mvp 的Activity或者Fragment时，我们只需要在MvpProvider中添加两个方法即可，一个`@Provider`标记，另外一个 `@ContributesAndroidInjector` 标记

注意其中用到了我们自定义的一个AndroidProvider 的类，后面我们会说明此类的作用：

```java
@Module(subcomponents = {
        MvpModule.MvpComponent.class,
})
public interface MvpModule {
    @Module
    abstract class MvpProvider {

        @MvpScope
        @Provides
        static TestDiMvpActivityPresenter.TestDiView bindTestDiView(@Nullable AndroidProvider<Activity> activityProvider) {
            if (activityProvider != null) {
                return (TestDiMvpActivityPresenter.TestDiView) activityProvider.get();
            } else {
                throw new NullPointerException("Please provider activity provider when build component!");
            }
        }

        @ContributesAndroidInjector
        abstract TestDiMvpActivity contributeTestDiMvpActivity();

        @MvpScope
        @Provides
        static TestDiMvpFragmentPresenter.View bindTestTestDiMvpFragmentView(@Nullable AndroidProvider<Fragment> fragmentAndroidProvider) {
            // May delete null check to keep code clean since we provide Fragment correctly
//            if (fragmentAndroidProvider != null) {
            return (TestDiMvpFragmentPresenter.View) fragmentAndroidProvider.get();
//            } else {
//                throw new NullPointerException("Please provider Fragment provider when build component!");
//            }
        }

        /**
         * 提供 TestDiMvpFragment 的注入接口
         *
         * @return TestDiMvpFragment
         */
        @ContributesAndroidInjector
        abstract TestDiMvpFragment contributeTestDiMvpFragment();

    }


    @MvpScope
    @Subcomponent(modules = {
            AndroidInjectionModule.class,
            MvpProvider.class,
    })
    interface MvpComponent {

        MvpContainer inject(MvpContainer mvpContainer);

        @Subcomponent.Builder
        interface Builder {
            @BindsInstance
            Builder activityProvider(@Nullable AndroidProvider<Activity> activityProvider);

            @BindsInstance
            Builder fragmentProvider(@Nullable AndroidProvider<Fragment> fragmentProvider);

            MvpComponent build();
        }
    }

}

/**
 * Android 组件提供等，主要用于延迟提供
 * @param <T> 组件类型（Activity，Fragment）等
 */
public class AndroidProvider<T> implements Provider<T> {

    private final T item;

    public AndroidProvider(T item) {
        this.item = item;
    }

    @Override
    public T get() {
        return item;
    }

}
```

#### 注册到 Root Component

我们只需要这么注册一次即可，后续添加组件时无需再修改。

```java
@Singleton
@Component(
        modules = {
          			// ...
                // MVP 组件
                MvpModule.class
        }
)
public interface SdkComponent {

    // ...
    MvpModule.MvpComponent.Builder mvpComponentBuilder();

    @Component.Builder
    interface Builder {
			// ...
    }

}
```

#### 注入过程封装隐藏

在之前描述的一般的MVP Activity 的注入过程中，我们是在每个具体的MvpActivity中的onCreate 方法中进行注册的，现在我们将注入的流程隐藏起来，放置到 ActivityLifeCycleCallbacks 中。

```java
public class SdkInjector {

    private static final String TAG = "SdkInjector";

    private static SdkContainer sSdkContainer;

    public static SdkComponent getSdkComponent() {
        return sSdkContainer.getSdkComponent();
    }

    public static SdkContainer getSdkContainer() {
        return sSdkContainer;
    }

    /**
     * 初始化 DI
     *
     * @param application Application
     */
    public static void init(Application application) {
        if (sSdkContainer != null) {
            return;
        }
        SdkComponent sSdkComponent = DaggerSdkComponent.builder()
                .application(application)
                .build();
        SdkInjector.sSdkContainer = new SdkContainer(sSdkComponent);
        sSdkComponent.inject(sSdkContainer);
        sSdkContainer.testInject();
        application.registerActivityLifecycleCallbacks(new BasicActivityLifeCycleCallbacks() {
            @Override
            public void onActivityPreCreated(@NonNull Activity activity, @Nullable Bundle savedInstanceState) {
                injectActivity(activity, savedInstanceState);
                super.onActivityPreCreated(activity, savedInstanceState);
            }
        });
    }

    private static void injectActivity(@NotNull Activity activity, @Nullable Bundle savedInstanceState) {
        if (activity instanceof MvpInjectable) {
            // MVP 的 Activity 注入
            MvpModule.MvpComponent mvpActivityComponent = SdkInjector.getSdkComponent()
                    .mvpComponentBuilder().activityProvider(new AndroidProvider<>(activity)).build();
            MvpContainer mvpContainer = new MvpContainer(mvpActivityComponent);
            mvpActivityComponent.inject(mvpContainer);
            SdkAndroidInjection.inject(activity, mvpContainer);
        } else if (activity instanceof Injectable) {
            SdkAndroidInjection.inject(activity);
        } else {
            Log.w(TAG, "Warning! You Activity " + activity.getClass().getSimpleName() + "is not injectable! ");
        }
        if (activity instanceof FragmentActivity) {
            final FragmentManager.FragmentLifecycleCallbacks lifecycleCallbacks = new FragmentManager.FragmentLifecycleCallbacks() {
                @Override
                public void onFragmentAttached(@NonNull @NotNull FragmentManager fm, @NonNull @NotNull Fragment f, @NonNull @NotNull Context context) {
                    super.onFragmentAttached(fm, f, context);
                    injectFragment(f, activity);
                }
            };
            ((FragmentActivity) activity).getSupportFragmentManager()
                    .registerFragmentLifecycleCallbacks(lifecycleCallbacks, true);
        }
    }

    private static void injectFragment(@NotNull Fragment f, @NotNull Activity activity) {
        if (f instanceof Injectable) {
            SdkAndroidInjection.inject(f);
        } else if (f instanceof MvpInjectable) {
            // MVP 的 Fragment 注入
            MvpModule.MvpComponent mvpComponent = SdkInjector.getSdkComponent()
                    .mvpComponentBuilder()
                    .activityProvider(new AndroidProvider<>(activity))
                    .fragmentProvider(new AndroidProvider<>(f))
                    .build();
            MvpContainer mvpContainer = mvpComponent.inject(new MvpContainer(mvpComponent));
            SdkAndroidInjection.inject(f, mvpContainer);
        } else {
            Log.w(TAG, "Warning! You fragment  " + f.getClass().getSimpleName() + " is not injectable!");
        }
    }
}
```

### 解决方案关键点说明

我们考虑下普通的MVP注入过程中为什么需要如此多的模板代码。

1. 由于P层依赖V，而 V 层是Activity，是系统生成的，所以，我们只能在onCreate 回调中获取到Activity，然后将其塞到Dagger的依赖对象的图谱中，也就是如下代码所做的

   即，必须提**供一个Module来接收Activity**将其放入到Dagger对象Graph中，同时也必须在onCreate中你才能获取到Activity。

   ```java
   			@Module
         class MvpModule {
             TestDiMvpActivityPresenter.TestDiView testDiView;
     
             public MvpModule(TestDiMvpActivityPresenter.TestDiView testDiView) {
                 this.testDiView = testDiView;
             }
     
             @Provides
             public TestDiMvpActivityPresenter.TestDiView providerView() {
                 return testDiView;
             }
         }
   
   
   @Override
   protected void onCreate(@Nullable  Bundle savedInstanceState) {
   			SdkInjector.getSdkComponent().testDiMvpActivityMComponentBuilder()
           						// 将Activity塞进依赖Graph
                      .module(new TestDiMvpActivityModule.MvpModule(this)).build()
                      .inject(this);
   }
   ```

2. 对于无法自动注入的对象，必须要通过 Component 提供一个 **inject 方法**，然后调用inject方法完成对其的手动注入，也就是上面onCreate方法中所写的部分。



#### 注入逻辑移动到ActivityLifecycleCallback回调及遇到的问题

实际上，通过向Application注册ActivityLifecycleCallback回调，我们可以将具体MvpActivity中的onCreate里的注入代码隐藏起来，我们在仔细研究下onCreate 中的注入逻辑，考虑可能会遇到的问题：

```java
@Override
protected void onCreate(@Nullable  Bundle savedInstanceState) {
			SdkInjector.getSdkComponent()
        .testDiMvpActivityMComponentBuilder()
        // 将Activity塞进依赖Graph
        // 1⃣️  塞入
        .module(new TestDiMvpActivityModule.MvpModule(this)).build()
        // 2⃣️  注入
        .inject(this);
}
```

考虑如下两个地方：

1. 塞入：在构造TestDiMvpActivityModule.MvpModule时，我们必须要传入一个具体类型（TestDiMvpActivity），而如果我们移动到ActivityLifecycleCallback中之后，这个具体的类型信息会丢失；
2. 注入：在inject时，我们的Component中定义的方法也是需要具体类型信息（TestDiMvpActivity）的，因为这样Dagger才能根据具体类型获取其依赖哪些信息，生成正确的注入代码，而移动到 ActivityLifecycleCallback 中之后，这个信息也会丢失；

也就是说，移动到 ActivityLifecycleCallback中之后，具体的类型信息丢失了，导致我们无法正确的调用塞入方法和注入方法。

#### 使用 Dagger-Android 生成 inject 模板代码

对于inject方法来说，我们实际上可以使用 Dagger-Android 的 `@ContributesAndroidInjector` 来帮助我们解决；

#### 使用包装类型避免Dagger类型检查，使用provider方法还原类型信息

在塞入的过程中，由于丢失了Activity的具体类型信息，我们将无法通过类型检查，所以我们创建了一个名为 AndroidProvider 的包装类型，我们在构造组件时，原先需要TestDiMvpActivity这个具体类型，现在我们只需要传入我们的包装类型，可以做到代码统一。

```java
// MVP 的 Activity 注入
            MvpModule.MvpComponent mvpActivityComponent = SdkInjector.getSdkComponent()
              // TestDiMvpActivity ->  new AndroidProvider<Activity>(activity)
                    .mvpComponentBuilder().activityProvider(new AndroidProvider<>(activity)).build();
            MvpContainer mvpContainer = new MvpContainer(mvpActivityComponent);
            mvpActivityComponent.inject(mvpContainer);
            SdkAndroidInjection.inject(activity, mvpContainer);
```

那么我们何时将其还原呢？

在提供对应TestDiView时，我们直接对其进行强制转换，然后提供为 TestDiView 类型

```java
 @Module
    abstract class MvpProvider {
        @Provides
        static TestDiMvpActivityPresenter.TestDiView bindTestDiView(@Nullable AndroidProvider<Activity> activityProvider) {
            if (activityProvider != null) {
                return (TestDiMvpActivityPresenter.TestDiView) activityProvider.get();
            } else {
                throw new NullPointerException("Please provider activity provider when build component!");
            }
        }
}
```

##  示例代码
具体实施过程中还有一些细节，可以参考Github中对应示例模块的源码。
* [android-libraries/lib_di_sample at master · hanlyjiang/android-libraries (github.com)](https://github.com/hanlyjiang/android-libraries/tree/master/lib_di_sample)

