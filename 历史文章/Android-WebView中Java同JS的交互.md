---
title: 'Android-WebView中Java同JS的交互'
date: 2020-03-20 10:18:50
tags: [Android,WebView,Vue]
published: true
hideInList: false
feature: 
isTop: false
---
Android提供的几种JS同Java交互的方式介绍，通过一个实例介绍通过`evaluateJavascript`调用JS方法。

<!-- more -->
## Android提供的js原生交互API

### Android调用 JS 代码：

1. 通过WebView的 **loadUrl()**
2. 通过WebView的 **evaluateJavascript()** 方法

Android调用 JS 代码主要使用 第二种方法。

### JS 调用 Android 代码：

1. **通过 WebView 的 addJavascriptInterface() 进行对象映射**
2. 通过**WebChromeClient**的 **onJsAlert**() 、**onJsConfirm**()、**onJsPrompt**() 方法回调拦截JS对话框**alert**()、**confirm**()、**prompt**() 消息
3. 通过**WebViewClient**的**shouldOverrideUrlLoading()** 方法回调拦截 url

第2和第3中方式能力有限，所以主要是第一种。

**官方示例代码：**

addJavaScriptInterface 注入原生对象到JS + 原生通过loadUrl 调用JS代码

```
class JsObject {
@JavascriptInterface
public String toString() { return "injectedObject"; }
}
webview.getSettings().setJavaScriptEnabled(true);
// 注入Java对象到 JavaScript ，JS中可以通过 injectedObject 来调用原生代码
webView.addJavascriptInterface(new JsObject(), "injectedObject");
webView.loadData("", "text/html", null);
webView.loadUrl("javascript:alert(injectedObject.toString())");
```
>**注意：**
>1. Android 4.2（JELLY BEAN）及更高版本中只有被*JavascriptInterface*注解的public方法才可以在js中调用； Android4.2以下设备上，所有public方法都可以被js访问（包括继承的）
>2. 通过*addJavaScriptInterface*加入对象 ： 必须在注入对象之前启用JavaScript，并且注入的对象直到下次页面重新加载才会出现在JavaScript中。



## 应用实例：Java同Vue交互

我们需要在页面加载完毕之后更新数据，此时需要通过Java侧调用JS的方法来将数据传递给JS通知其更新；
首先，我们需要在JS侧定义一个接收数据的方法，为了能让Java侧能方便找到，我们将方法定义到window对象上。
然后在WebView中页面加载完毕（onPageFinished）后，调用 `webView.evaluateJavascript` 来调用此JS方法；

### JS侧方法注册

>注意：
>1. 需要添加到全局对象，这样才能Android侧才能调用；
>2. 由于示例中只有一个app组件，所以直接使用 vm.$children[0] 获取vue组件
>3. component.$data 获取组件的数据，并赋值，赋值后view会自动变化；
```javascript
// main.js
/* eslint-disable no-new */
let vm = new Vue({
  el: '#app',
  components: {App},
  template: '<App/>',
});
// 定义hnUpdateData方法到window全局对象
window.hnApp = {};
window.hnApp.hnUpdateData = function (data) {
  if (!data) {
    Android.alert("数据格式不正确");
    return;
  }
  console.log(data);
  const jsonData = JSON.parse(data);
  const component = vm.$children[0];
  component.$data.header = jsonData.header ? jsonData.header : {};
  component.$data.jjb = jsonData.jjb ? jsonData.jjb : {};
  component.$data.events = jsonData.events ? jsonData.events : [];
};
```
### 原生侧调用JS

#### 定义方法-调用JS方法更新数据

```java
    private void tryUpdateWebData(JSdata jSdata) {
        if (isPageLoaded && isDataReady) {
            String methodName = "window.hnApp.hnUpdateData";
            String params = new Gson().toJson(jSdata);
            String js = "javascript:" + methodName + "(" + JSONObject.quote(params) + ")";
            webView.evaluateJavascript(js, new ValueCallback<String>() {
                @Override
                public void onReceiveValue(String value) {
                }
            });
        }
    }
```
> 注意：
>
> 1.  js执行代码：javascript:methodName(参数)
> 2.  参数处理：JSONObject.quote(params) 对象转json字符串

### WebView初始化并调用JS方法

```java
public void initView() {
        webView = (WebView) findViewById(R.id.web_view);
        webView.setWebViewClient(webViewClient);
        webView.setWebChromeClient(webChromeClient);
        webView.setDownloadListener(downloadListener);
        webView.requestFocusFromTouch();
        WebSettings settings = webView.getSettings();    // Copy From Cordova SystemWebViewEngine.java
        settings.setJavaScriptEnabled(true);
        settings.setJavaScriptCanOpenWindowsAutomatically(true);
        settings.setJavaScriptEnabled(true);
    }

    private WebViewClient webViewClient = new WebViewClient() {
        @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
        @Override
        public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
            view.loadUrl(request.getUrl().toString());
            super.shouldOverrideUrlLoading(view, request);
            return true;
        }

        @Override
        public void onPageFinished(WebView view, String url) {
            super.onPageFinished(view, url);
            isPageLoaded = true;
            // 调用js更新数据
            tryUpdateWebData(mData);
        }
    };

    private WebChromeClient webChromeClient = new WebChromeClient() {
        // ...   
    }

```