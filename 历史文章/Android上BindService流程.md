---
title: 'Android bindService流程'
date: 2021-04-12 10:18:50
tags: [Android,源码分析]
published: true
hideInList: false
feature: 
isTop: false
---



本文分析bindService的流程，首先我们通过阅读源码获取一个主线的调用地图，然后提出若干问题，包括：APP进程中如何获取AMS，AMS如何启动APP-service的进程，AMS中如何获取ApplicationThread并与之通讯，Service的启动及绑定流程；然后再通过源码一一解答。最后再整体总结梳理一下整体流程；

<!-- more -->



**预先知识：**

* Binder通信机制

## 整体分析与总结

### 主线地图与问题提出

我们从bindService一路跟踪，初步绘制了如下的调用序列图，我们可以以下面的图作为一个主线地图，避免走失，然后根据具体问题进行细节分析。


<svg width="812px" height="553px" viewBox="0 0 812 553" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
    <g id="Android源码分析" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd">
        <g id="bindService流程分析-加入启动流程" transform="translate(-94.000000, -222.000000)">
            <g id="架构图/模块-源码" transform="translate(125.000000, 273.000000)">
                <rect id="矩形" stroke="#979797" stroke-width="0.870292887" fill="#E4E4E4" x="0.435146444" y="0.435146444" width="298.528768" height="33.1297071" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="87.4814217" y="14">Context.bindService</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="33.3413714" y="30.122449">frameworks/base/core/java/android/content/Context.java</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份" transform="translate(125.000000, 322.000000)">
                <rect id="矩形" stroke="#979797" stroke-width="0.870292887" fill="#E4E4E4" x="0.435146444" y="0.435146444" width="298.528768" height="33.1297071" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="73.439246" y="14">ContextImpl.bindService</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="32.0315806" y="30.122449">frameworks/base/core/java/android/app/ContextImpl.java</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-2" transform="translate(125.000000, 373.000000)">
                <rect id="矩形" stroke="#979797" stroke-width="0.870292887" fill="#E4E4E4" x="0.435146444" y="0.435146444" width="298.528768" height="33.1297071" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="45.7569699" y="14">ContextImpl.bindServiceCommon</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="32.0315806" y="30.122449">frameworks/base/core/java/android/app/ContextImpl.java</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-3" transform="translate(125.000000, 422.000000)">
                <rect id="矩形" stroke="#979797" stroke-width="0.870292887" fill="#E4E4E4" x="0.435146444" y="0.435146444" width="298.528768" height="33.1297071" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="35.1872627" y="14">IActivityManager.bindIsolatedService</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="80.4068108" y="30.122449">android/app/IActivityManager.java</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-4" transform="translate(523.000000, 273.000000)">
                <rect id="矩形" stroke="#979797" fill="#D5FFA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="14.2367021" y="14">ActivityManagerService.bindIsolatedService</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="44.0851371" y="30.122449">com/android/server/am/ActivityManagerService.java</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-5" transform="translate(523.000000, 322.000000)">
                <rect id="矩形" stroke="#979797" fill="#D5FFA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="45.2025933" y="14">ActiveServices.bindServiceLocked</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="62.0131706" y="30.122449">com/android/server/am/ActiveServices.java</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-16" transform="translate(523.000000, 422.000000)">
                <rect id="矩形" stroke="#979797" fill="#D5FFA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="25.0439991" y="14">IApplicationThread.scheduleBindService</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="75.1632961" y="30.122449">android/app/IApplicationThread.java</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-17" transform="translate(523.000000, 482.000000)">
                <rect id="矩形" stroke="#979797" fill="#FFED99" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="102.802928" y="14">Binder.transact</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="136.553756" y="30.122449">binder</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-18" transform="translate(440.000000, 273.000000)">
                <rect id="矩形" stroke="#979797" fill="#FFED99" x="0.5" y="0.5" width="63.3004695" height="182" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="10.224946" y="14">Binder.</tspan>
                    <tspan x="6.77075357" y="32">transact</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="19.0044607" y="118.306122">binder</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-18" transform="translate(440.000000, 537.000000)">
                <rect id="矩形" stroke="#979797" fill="#FFED99" x="0.5" y="0.5" width="63.3004695" height="182" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="10.224946" y="14">Binder.</tspan>
                    <tspan x="6.77075357" y="32">transact</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="19.0044607" y="118.306122">binder</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-10" transform="translate(522.000000, 537.000000)">
                <rect id="矩形" stroke="#979797" fill="#FFBBA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="27.1213883" y="14">ApplicationThread.scheduleBindService</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="28.0238818" y="30.122449">frameworks/base/core/java/android/app/ActivityThread.java</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-12" transform="translate(522.000000, 587.000000)">
                <rect id="矩形" stroke="#979797" fill="#FFBBA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="43.344518" y="14">ActivityThread#handleBindService</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="28.0238818" y="30.122449">frameworks/base/core/java/android/app/ActivityThread.java</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-19" transform="translate(522.000000, 637.000000)">
                <rect id="矩形" stroke="#979797" fill="#FFBBA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="63.1680494" y="14">IBinder = Service.onBinder()</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="104.313756" y="30.122449">自定义的Service实现类</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-20" transform="translate(522.000000, 686.000000)">
                <rect id="矩形" stroke="#979797" fill="#FFBBA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="48.7055222" y="14">IActivityManager#publishService</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="80.4068108" y="30.122449">android/app/IActivityManager.java</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-21" transform="translate(125.000000, 537.000000)">
                <rect id="矩形" stroke="#979797" fill="#D5FFA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="28.303246" y="14">ActivityManagerService#publishService</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="80.4068108" y="30.122449">android/app/IActivityManager.java</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-23" transform="translate(125.000000, 587.000000)">
                <rect id="矩形" stroke="#979797" fill="#D5FFA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="34.5841498" y="14">ActiveServices#publishServiceLocked</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="62.0131706" y="30.122449">com/android/server/am/ActiveServices.java</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-51" transform="translate(125.000000, 638.000000)">
                <rect id="矩形" stroke="#979797" fill="#D5FFA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="54.5477983" y="14">IServiceConnection#connected</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="148.202627" y="30.122449">-</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-8" transform="translate(523.000000, 373.000000)">
                <rect id="矩形" stroke="#979797" fill="#D5FFA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="12.0131038" y="14">ActiveServices.requestServiceBindingLocked</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="62.0131706" y="30.122449">com/android/server/am/ActiveServices.java</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-13" transform="translate(347.000000, 222.000000)">
                <rect id="矩形" stroke="#979797" stroke-width="0.870292887" fill="#E4E4E4" x="0.435146444" y="0.435146444" width="74.4818198" height="33.1297071" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="5.9181986" y="14">APP-client</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="20.8532948" y="30.122449">APP进程</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-14" transform="translate(830.000000, 222.000000)">
                <rect id="矩形" stroke="#979797" fill="#D5FFA2" x="0.5" y="0.5" width="74.3521127" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="2.77470069" y="14">AMS-server</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="5.78852492" y="30.122449">system_process</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-14" transform="translate(347.000000, 740.000000)">
                <rect id="矩形" stroke="#979797" fill="#D5FFA2" x="0.5" y="0.5" width="74.3521127" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="2.77470069" y="14">AMS-server</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="5.78852492" y="30.122449">system_process</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-15" transform="translate(830.000000, 741.000000)">
                <rect id="矩形" stroke="#979797" fill="#FFBBA2" x="0.5" y="0.5" width="74.3521127" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="4.04184714" y="14">APP:server</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="5.24894333" y="30.122449">APP Service进程</tspan>
                </text>
            </g>
            <path id="直线-16" d="M811.41934,230.797071 C811.613811,230.797071 811.805612,230.843224 811.979552,230.931875 L811.979552,230.931875 L830.473932,240.357781 C831.092725,240.673158 831.343541,241.440147 831.034144,242.0709 C830.912931,242.318011 830.716358,242.518383 830.473932,242.641939 L830.473932,242.641939 L811.979552,252.067845 C811.360759,252.383221 810.608312,252.127558 810.298915,251.496806 C810.211945,251.319504 810.166667,251.123996 810.166667,250.925766 L810.166667,250.925766 L810.166,243.24 L423,243.240586 C422.038701,243.240586 421.259414,242.461299 421.259414,241.5 C421.259414,240.586766 421.962721,239.837798 422.857245,239.765184 L423,239.759414 L810.166,239.759 L810.166667,232.073954 C810.166667,231.412826 810.659593,230.869053 811.291261,230.803664 Z" fill-opacity="0.56105479" fill="#C9C9C9" fill-rule="nonzero"></path>
            <path id="直线-16备份-2" d="M441.58066,746.797071 C442.272493,746.797071 442.833333,747.368751 442.833333,748.073954 L442.833333,748.073954 L442.833,755.759 L830,755.759414 C830.961299,755.759414 831.740586,756.538701 831.740586,757.5 C831.740586,758.413234 831.037279,759.162202 830.142755,759.234816 L830,759.240586 L442.833,759.24 L442.833333,766.925766 C442.833333,767.074439 442.807864,767.22158 442.758439,767.360657 L442.701085,767.496806 C442.391688,768.127558 441.639241,768.383221 441.020448,768.067845 L441.020448,768.067845 L422.526068,758.641939 C422.283642,758.518383 422.087069,758.318011 421.965856,758.0709 C421.656459,757.440147 421.907275,756.673158 422.526068,756.357781 L422.526068,756.357781 L441.020448,746.931875 C441.194388,746.843224 441.386189,746.797071 441.58066,746.797071 Z" fill-opacity="0.56105479" fill="#C9C9C9" fill-rule="nonzero"></path>
            <path id="直线-16备份" d="M871.5,255.259414 C872.413234,255.259414 873.162202,255.962721 873.234816,256.857245 L873.240586,257 L873.24,721.166 L880.926046,721.166667 C881.587174,721.166667 882.130947,721.659593 882.196336,722.291261 L882.202929,722.41934 C882.202929,722.613811 882.156776,722.805612 882.068125,722.979552 L882.068125,722.979552 L872.642219,741.473932 C872.326842,742.092725 871.559853,742.343541 870.9291,742.034144 C870.681989,741.912931 870.481617,741.716358 870.358061,741.473932 L870.358061,741.473932 L860.932155,722.979552 C860.616779,722.360759 860.872442,721.608312 861.503194,721.298915 C861.680496,721.211945 861.876004,721.166667 862.074234,721.166667 L862.074234,721.166667 L869.759,721.166 L869.759414,257 C869.759414,256.038701 870.538701,255.259414 871.5,255.259414 Z" fill-opacity="0.56105479" fill="#C9C9C9" fill-rule="nonzero"></path>
            <path id="直线" d="M272.935146,307.012222 L272.935,315.997 L276.675732,315.997076 L272.5,323.997076 L268.324268,315.997076 L272.064,315.997 L272.064854,307.012222 L272.935146,307.012222 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-2" d="M272.935146,356.012222 L272.935,364.997 L276.675732,364.997076 L272.5,372.997076 L268.324268,364.997076 L272.064,364.997 L272.064854,356.012222 L272.935146,356.012222 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-3" d="M272.935146,405.012222 L272.935,413.997 L276.675732,413.997076 L272.5,421.997076 L268.324268,413.997076 L272.064,413.997 L272.064854,405.012222 L272.935146,405.012222 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-17" d="M433.019444,433.324268 L441.019444,437.5 L433.019444,441.675732 L433.019,437.935 L423.989854,437.935146 L423.989854,437.064854 L433.019,437.064 L433.019444,433.324268 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-4" d="M516.989899,284.324268 L524.989899,288.5 L516.989899,292.675732 L516.989,288.935 L505.019399,288.935146 L505.019399,288.064854 L516.989,288.064 L516.989899,284.324268 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-5" d="M671.935146,307.012222 L671.935,315.997 L675.675732,315.997076 L671.5,323.997076 L667.324268,315.997076 L671.064,315.997 L671.064854,307.012222 L671.935146,307.012222 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-6" d="M671.935146,356.012222 L671.935,364.997 L675.675732,364.997076 L671.5,372.997076 L667.324268,364.997076 L671.064,364.997 L671.064854,356.012222 L671.935146,356.012222 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-7" d="M671.935146,405.012222 L671.935,413.997 L675.675732,413.997076 L671.5,421.997076 L667.324268,413.997076 L671.064,413.997 L671.064854,405.012222 L671.935146,405.012222 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-8" d="M671.935146,454.998187 L671.935,473.011 L675.675732,473.011111 L671.5,481.011111 L667.324268,473.011111 L671.064,473.011 L671.064854,454.998187 L671.935146,454.998187 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-9" d="M671.935146,514.990779 L671.935,530.018 L675.675732,530.018519 L671.5,538.018519 L667.324268,530.018519 L671.064,530.018 L671.064854,514.990779 L671.935146,514.990779 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-10" d="M671.935146,571.012222 L671.935,579.997 L675.675732,579.997076 L671.5,587.997076 L667.324268,579.997076 L671.064,579.997 L671.064854,571.012222 L671.935146,571.012222 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-18" d="M671.935146,621.012222 L671.935,629.997 L675.675732,629.997076 L671.5,637.997076 L667.324268,629.997076 L671.064,629.997 L671.064854,621.012222 L671.935146,621.012222 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-11" d="M671.935146,671.012222 L671.935,679.997 L675.675732,679.997076 L671.5,687.997076 L667.324268,679.997076 L671.064,679.997 L671.064854,671.012222 L671.935146,671.012222 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-19" d="M511.984127,699.324268 L511.984,703.064 L522.006575,703.064854 L522.006575,703.935146 L511.984,703.935 L511.984127,707.675732 L503.984127,703.5 L511.984127,699.324268 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-20" d="M431.980556,550.324268 L431.98,554.064 L441.010146,554.064854 L441.010146,554.935146 L431.98,554.935 L431.980556,558.675732 L423.980556,554.5 L431.980556,550.324268 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-12" d="M272.935146,571.012222 L272.935,579.997 L276.675732,579.997076 L272.5,587.997076 L268.324268,579.997076 L272.064,579.997 L272.064854,571.012222 L272.935146,571.012222 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-12备份" d="M272.935146,621.012222 L272.935,629.997 L276.675732,629.997076 L272.5,637.997076 L268.324268,629.997076 L272.064,629.997 L272.064854,621.012222 L272.935146,621.012222 Z" fill="#979797" fill-rule="nonzero"></path>
            <g id="序号" transform="translate(94.000000, 400.000000)">
                <circle id="椭圆形" stroke="#888888" stroke-width="1.3" fill-opacity="0.5" fill="#E4E4E4" cx="13" cy="13" r="12.35"></circle>
                <text id="1" font-family="NotoSansCJKsc-Black, Noto Sans CJK SC" font-size="13" font-weight="800" letter-spacing="0.143000009" fill="#020202" fill-opacity="0.88378138">
                    <tspan x="8.97" y="17.6">1</tspan>
                </text>
            </g>
            <g id="序号备份" transform="translate(825.000000, 400.000000)">
                <circle id="椭圆形" stroke="#888888" stroke-width="1.3" fill-opacity="0.5" fill="#E4E4E4" cx="13" cy="13" r="12.35"></circle>
                <text id="2" font-family="NotoSansCJKsc-Black, Noto Sans CJK SC" font-size="13" font-weight="800" letter-spacing="0.143000009" fill="#020202" fill-opacity="0.88378138">
                    <tspan x="8.97" y="17.6">2</tspan>
                </text>
            </g>
        </g>
    </g>
</svg>



从上图中，我们提出如下问题：

1. bindServiceCommon到IActivityManager的调用中，是如何获取到ActivityManagerService的？
2. AMS中如何获取ApplicationThread并与之通讯？
   * ApplicatoinThread的用途？ApplicationThread运行的进程是哪个？
3. 进程如何启动-即AMS如何创建APP:server进程？
4. Service如何启动？
5. Service如何绑定？
   * ServiceConnection 的回调方法何时使用？

### 问题解答汇总

我们将相关问题的结论提前到此小节，便于后续从比较抽象的层次上来进行复习及预览；

#### APP进程如何获取AMS？

* APP进程中通过 `ServiceManager.getService(Context.ACTIVITY_SERVICE)` 获取的ActivityManagerService的客户端操作代理对象（Proxy）。

  > 该对象位于APP进程中，可以使用此对象（通过Binder进程间通信）来要求（位于system_process中）的ActivityManagerService进行对应的服务操作； 

#### AMS如何获取ApplicationThread？

* APP进程在binderSerice时，将自己进程中的ApplicationThread取出，通过Binder机制传递给AMS进程，传递过程中会转换成一个Proxy对象；

  ```java
  ActivityManager.getService().bindIsolatedService(
              mMainThread.getApplicationThread(), getActivityToken(), service,
              service.resolveTypeIfNeeded(getContentResolver()),
              sd, flags, instanceName, getOpPackageName(), user.getIdentifier());
  ```

#### 服务如何绑定？服务如何启动？进程如何启动？

* **进程启动**：
  * 在独立的进程中运行的服务需要先将进程启动，进程的启动是通过APP进程，请求系统进程中的AMS来执行，通过AMS的`startProcessLocked`方法启动进程，最终会通过socket接口请求zygote进程来启动进程。
  * 在启动时会指定java的入口点为ActivityThread，即进程启动后会运行ActivityThread的main方法；
  * AMS中会记录启动的进程记录（ProcessRecord），对应的ProcessRecord中会记录进程对应的ApplicationThread；
* **服务启动**：
  * 服务的启动需要请求AMS来完成
  * 启动时需要先通过PID获取要启动到的ProcessRecord，通过ProcessRecord中记录的ApplicationThread来与对应的进程通信。
  * AMS通过ApplicationThread来通知对应的进程创建服务，ApplicationThread作为通信的接口，实际上最终会通过ActivityThread的handleCreateService来创建服务的实例；
  * 服务创建时，是在APP进程（可能是独立的进程）中进行的，需要通过类加载器加载对应的Service的类，同时构造相应的上下文及资源对象等，然后构造对应的实例；
  * 服务创建成功后，会记录到ActivityThread的一个Service列表中，以便后续管理；
* **服务绑定**：
  * 服务绑定先在APP进程中，通过AMS代理对象发起请求，由AMS来安排bind（**ActivityManagerService.bindIsolatedService**）;
  * 然后具体的绑定动作还是通过IApplicationThread安排到APP的Service进程中，最终执行的`ActivityThread#handleBindService`;
  * 在APP进程中，会将Service取出，然后调用其onBind方法来获取IBinder远程操作对象；
  * 之后再通过AMS调用 `ActivityManagerService#publishService` 来通知绑定成功的通知到对应的需要绑定服务的APP进程；
  * publishService中会调用ServiceConnection的onServiceConnected方法通知服务连接了；

### 整体流程总结

> 待补充

## 详细分析解答问题

### APP进程中如何获取AMS？

> 说明：
>
> * 第一次先逐项查看各个小节，最后再看此处的总结；
>
> * 后续直接查看总结来快速获取结论；

==总结：==

* APP进程中通过 `ServiceManager.getService(Context.ACTIVITY_SERVICE)` 获取的`ActivityManagerService`的客户端操作代理对象（Proxy）。
* 该对象位于APP进程中，可以使用此对象（通过Binder进程间通信）来要求（位于`system_process`中）的`ActivityManagerService`进行对应的服务操作； 

具体查看如下代码：

#### ContextImpl.bindServiceCommon

我们看 `ContextImpl.bindServiceCommon` 方法的实现，可以看到是调用了 `ActivityManager.getService()` 获取的；

`frameworks/base/core/java/android/app/ContextImpl.java`: 

```java
private boolean bindServiceCommon(Intent service, ServiceConnection conn, int flags,
            String instanceName, Handler handler, Executor executor, UserHandle user) {
        // Keep this in sync with DevicePolicyManager.bindDeviceAdminServiceAsUser.
        IServiceConnection sd;
        
        if (executor != null) {
            sd = mPackageInfo.getServiceDispatcher(conn, getOuterContext(), executor, flags);
        } else {
            sd = mPackageInfo.getServiceDispatcher(conn, getOuterContext(), handler, flags);
        }
	    //
        int res = ActivityManager.getService().bindIsolatedService(
            mMainThread.getApplicationThread(), getActivityToken(), service,
            service.resolveTypeIfNeeded(getContentResolver()),
            sd, flags, instanceName, getOpPackageName(), user.getIdentifier());

}
```

#### `ActivityManager.getService()`

如下代码，getService实际上是从ServiceManager获取一个ActivityService的Binder远程服务接口对象，并且这个会被设置为单例模式；

`frameworks/base/core/java/android/app/ActivityManager.java`:

```java
private static final Singleton<IActivityManager> IActivityManagerSingleton =
    new Singleton<IActivityManager>() {
    @Override
    protected IActivityManager create() {
        // 直接通过 ServiceManager.getService 获取一个IBinder对象
        final IBinder b = ServiceManager.getService(Context.ACTIVITY_SERVICE);
        final IActivityManager am = IActivityManager.Stub.asInterface(b);
        return am;
    }
};

public static IActivityManager getService() {
    // 直接从IActivityManagerSingleton获取实例
    return IActivityManagerSingleton.get();
}
```

### AMS如何获取到 ApplicatoinThread？

首先，AMS实际上位于系统进程（system_process)，而ApplicationThread则位于我们的APP进程，那么为什么需要这个跨进程的操作呢？

* Service的创建需要经过系统的管理，比方说鉴权及其他管理需要；
* 而开发者定义的Service的实例的创建逻辑也还是需要开发者来实现，Service对应的类也应该只加载在开发者自己的进程之中，Service使用方实际上还是开发者自己，所以服务的真实实例的创建过程要在应用的进程中；

那么，系统进程（中的AMS）如何获取ApplicationThread呢？

#### ApplicationThread的来源？

查看 **ContextImpl.bindServiceCommon** 的代码，可以看到，是在调用AMS的bindService方法时，将自己进程中的`ApplicationThread`及`ActivityToken`取出传递给了AMS服务；

```java
// frameworks/base/core/java/android/app/ContextImpl.java
final @NonNull ActivityThread mMainThread;
private final @Nullable IBinder mToken;

public IBinder getActivityToken() {
    return mToken;
}

private boolean bindServiceCommon(Intent service, ServiceConnection conn, int flags,
            String instanceName, Handler handler, Executor executor, UserHandle user) {
        // Keep this in sync with DevicePolicyManager.bindDeviceAdminServiceAsUser.
        IServiceConnection sd;
        try {
            service.prepareToLeaveProcess(this);
            // 调用时传递了ApplicationThread和IBinder
            int res = ActivityManager.getService().bindIsolatedService(
                mMainThread.getApplicationThread(), getActivityToken(), service,
                service.resolveTypeIfNeeded(getContentResolver()),
                sd, flags, instanceName, getOpPackageName(), user.getIdentifier());
            if (res < 0) {
                throw new SecurityException(
                        "Not allowed to bind to service " + service);
            }
            return res != 0;
        } catch (RemoteException e) {
            throw e.rethrowFromSystemServer();
        }
    }
```

实际上，上面的`mMainThread.getApplicationThread()`取出的是我们的APP进程中的ApplicationThread的服务端对象，然后经过IActivityManager进行binder传输（transact）前，会将其转换为一个Proxy代理对象，用于在AMS中请求我们进程的ApplicationThread来提供服务； 

```java
// android.app.IActivityManager.Stub#TRANSACTION_bindIsolatedService 
case TRANSACTION_bindIsolatedService:
        {
          data.enforceInterface(descriptor);
          android.app.IApplicationThread _arg0;
          // 这里将IApplicationThread的服务对象转换成一个Proxy代理对象
          _arg0 = android.app.IApplicationThread.Stub.asInterface(data.readStrongBinder());
          android.os.IBinder _arg1;
          _arg1 = data.readStrongBinder();
          android.content.Intent _arg2;
          if ((0!=data.readInt())) {
            _arg2 = android.content.Intent.CREATOR.createFromParcel(data);
          }
          else {
            _arg2 = null;
          }
          java.lang.String _arg3;
          _arg3 = data.readString();
          android.app.IServiceConnection _arg4;
          // 同理，这里将IServiceConnection的服务对象也转换成一个Proxy代理对象
          _arg4 = android.app.IServiceConnection.Stub.asInterface(data.readStrongBinder());
          int _arg5;
          _arg5 = data.readInt();
          java.lang.String _arg6;
          _arg6 = data.readString();
          java.lang.String _arg7;
          _arg7 = data.readString();
          int _arg8;
          _arg8 = data.readInt();
          int _result = this.bindIsolatedService(_arg0, _arg1, _arg2, _arg3, _arg4, _arg5, _arg6, _arg7, _arg8);
          reply.writeNoException();
          reply.writeInt(_result);
          return true;
        }
        
// android.app.IApplicationThread.Stub
 /** Local-side IPC implementation stub class. */
  public static abstract class Stub extends android.os.Binder implements android.app.IApplicationThread
  {
    private static final java.lang.String DESCRIPTOR = "android.app.IApplicationThread";
    /** Construct the stub at attach it to the interface. */
    public Stub()
    {
      this.attachInterface(this, DESCRIPTOR);
    }
    /**
     * Cast an IBinder object into an android.app.IApplicationThread interface,
     * generating a proxy if needed.
     */
    public static android.app.IApplicationThread asInterface(android.os.IBinder obj)
    {
      if ((obj==null)) {
        return null;
      }
      android.os.IInterface iin = obj.queryLocalInterface(DESCRIPTOR);
      if (((iin!=null)&&(iin instanceof android.app.IApplicationThread))) {
        return ((android.app.IApplicationThread)iin);
      }
      // 这里构造成了Proxy
      return new android.app.IApplicationThread.Stub.Proxy(obj);
    }
  }
```


> 这里我们暂不考虑ApplicationThread由何处而来，每个进程中都对应一个ActivityThread，ActivityThread中有一个ApplicationThread对象。

#### ApplicationThread在bind流程中的使用

我们发现，最终是使用 `ApplicationThread`的 `requestServiceBindingLocked` 方法来绑定服务的（`r.app.thread.scheduleBindService`），我们先梳理一下ServiceRecord类同ApplicationThread的关系；

```java
// frameworks/base/services/core/java/com/android/server/am/ActiveServices.java
// com.android.server.am.ActiveServices#requestServiceBindingLocked
private final boolean requestServiceBindingLocked(ServiceRecord r, IntentBindRecord i,
            boolean execInFg, boolean rebind) throws TransactionTooLargeException {
        if (r.app == null || r.app.thread == null) {
            // If service is not currently running, can't yet bind.
            return false;
        }
	    // 调用ApplicationThread的绑定方法来进行绑定
        r.app.thread.scheduleBindService(r, i.intent.getIntent(), rebind,
                                         r.app.getReportedProcState());
        return true;
    }

// frameworks/base/services/core/java/com/android/server/am/ServiceRecord.java
ProcessRecord app;          // where this service is running or null.

// frameworks/base/services/core/java/com/android/server/am/ProcessRecord.java
IApplicationThread thread;  // the actual proc...  may be null only if
                            // 'persistent' is true (in which case we
                            // are in the process of launching the app)
```

其中 `ServiceRecord.app` 的类型为 `ProcessRecord` ，`ServiceRecord.app.thread` 的类型为 `IApplicationThread`，我们梳理下对应的几个类的关系，如下图：


<svg width="772px" height="493px" viewBox="0 0 772 493" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
    <g id="Android源码分析" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd">
        <g id="ServiceRecord类图" transform="translate(-31.000000, -33.000000)">
            <g id="UML/类图/类模块" transform="translate(32.000000, 34.000000)">
                <g id="名称" transform="translate(-0.284133, 0.000000)">
                    <path d="M214.320588,-0.5 C215.563229,-0.5 216.688229,0.00367965644 217.502569,0.818019485 C218.316909,1.63235931 218.820588,2.75735931 218.820588,4 L218.820588,4 L218.820588,27.4753086 L-0.179411765,27.4753086 L-0.179411765,4 C-0.179411765,2.75735931 0.324267892,1.63235931 1.13860772,0.818019485 C1.95294755,0.00367965644 3.07794755,-0.5 4.32058824,-0.5 L4.32058824,-0.5 Z" id="标题" stroke="#979797" fill="#F4F4F4"></path>
                    <text id="Class-Name" font-family="NotoSansCJKsc-Medium, Noto Sans CJK SC" font-size="14" font-weight="400" letter-spacing="0.154000005" fill="#020202" fill-opacity="0.88378138">
                        <tspan x="60.4815882" y="16">ServiceRecord</tspan>
                    </text>
                </g>
                <g id="属性" transform="translate(0.036455, 26.975309)">
                    <rect stroke="#979797" fill="#F6FFDF" x="-0.5" y="-0.5" width="219" height="45.0123457"></rect>
                    <text id="Properties" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="14" font-weight="300" letter-spacing="0.154000005" fill="#020202" fill-opacity="0.88378138">
                        <tspan x="6" y="17">app:ProcessRecord </tspan>
                        <tspan x="6" y="37">isolatedProc: ProcessRecord</tspan>
                    </text>
                </g>
                <g id="方法" transform="translate(0.036455, 70.987654)">
                    <path d="M218.5,-0.5 L218.5,40.0123457 C218.5,41.2549864 217.99632,42.3799864 217.181981,43.1943262 C216.367641,44.008666 215.242641,44.5123457 214,44.5123457 L214,44.5123457 L4,44.5123457 C2.75735931,44.5123457 1.63235931,44.008666 0.818019485,43.1943262 C0.00367965644,42.3799864 -0.5,41.2549864 -0.5,40.0123457 L-0.5,40.0123457 L-0.5,-0.5 L218.5,-0.5 Z" stroke="#979797" fill="#FFDFDF"></path>
                    <text id="Methods" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="14" font-weight="300" letter-spacing="0.154000005" fill="#020202" fill-opacity="0.88378138">
                        <tspan x="5" y="16">+ setProcess(ProcessRecord)</tspan>
                    </text>
                </g>
            </g>
            <g id="UML/类图/类模块备份-3" transform="translate(310.000000, 34.000000)">
                <g id="名称" transform="translate(-0.639952, 0.000000)">
                    <path d="M487.722059,-0.5 C488.9647,-0.5 490.0897,0.00367965644 490.904039,0.818019485 C491.718379,1.63235931 492.222059,2.75735931 492.222059,4 L492.222059,4 L492.222059,39.9074074 L0.222058824,39.9074074 L0.222058824,4 C0.222058824,2.75735931 0.72573848,1.63235931 1.54007831,0.818019485 C2.35441814,0.00367965644 3.47941814,-0.5 4.72205882,-0.5 L4.72205882,-0.5 Z" id="标题" stroke="#979797" fill="#F4F4F4"></path>
                    <text id="Class-Name" font-family="NotoSansCJKsc-Medium, Noto Sans CJK SC" font-size="14" font-weight="400" letter-spacing="0.154000005" fill="#020202" fill-opacity="0.88378138">
                        <tspan x="181.017059" y="16">IApplicationThread</tspan>
                    </text>
                </g>
                <g id="属性" transform="translate(0.082107, 39.407407)">
                    <rect stroke="#979797" fill="#F6FFDF" x="-0.5" y="-0.5" width="492" height="65.2962963"></rect>
                    <text id="Properties" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="14" font-weight="300" letter-spacing="0.154000005"></text>
                </g>
                <g id="方法" transform="translate(0.082107, 103.703704)">
                    <path d="M491.5,-0.5 L491.5,60.2962963 C491.5,61.538937 490.99632,62.663937 490.181981,63.4782768 C489.367641,64.2926166 488.242641,64.7962963 487,64.7962963 L487,64.7962963 L4,64.7962963 C2.75735931,64.7962963 1.63235931,64.2926166 0.818019485,63.4782768 C0.00367965644,62.663937 -0.5,61.538937 -0.5,60.2962963 L-0.5,60.2962963 L-0.5,-0.5 L491.5,-0.5 Z" stroke="#979797" fill="#FFDFDF"></path>
                    <text id="Methods" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="14" font-weight="300" letter-spacing="0.154000005" fill="#020202" fill-opacity="0.88378138">
                        <tspan x="5" y="16">+ scheduleBindService(IBinder, Intent, boolean rebind, int processState) </tspan>
                        <tspan x="5" y="36">+ scheduleCreateService(IBinder, ServiceInfo info,… ) </tspan>
                        <tspan x="5" y="56">+ bindApplication(…)</tspan>
                    </text>
                </g>
            </g>
            <g id="UML/类图/类模块备份-4" transform="translate(310.000000, 264.000000)">
                <g id="名称" transform="translate(-0.311504, 0.000000)">
                    <path d="M235.351471,-0.5 C236.594111,-0.5 237.719111,0.00367965644 238.533451,0.818019485 C239.347791,1.63235931 239.851471,2.75735931 239.851471,4 L239.851471,4 L239.851471,25.3641975 L-0.148529412,25.3641975 L-0.148529412,4 C-0.148529412,2.75735931 0.355150245,1.63235931 1.16949007,0.818019485 C1.9838299,0.00367965644 3.1088299,-0.5 4.35147059,-0.5 L4.35147059,-0.5 Z" id="标题" stroke="#979797" fill="#F4F4F4"></path>
                    <text id="Class-Name" font-family="NotoSansCJKsc-Medium, Noto Sans CJK SC" font-size="14" font-weight="400" letter-spacing="0.154000005" fill="#020202" fill-opacity="0.88378138">
                        <tspan x="36.6004705" y="16">IApplicationThread.Stub</tspan>
                    </text>
                </g>
                <g id="属性" transform="translate(0.039967, 24.864198)">
                    <rect stroke="#979797" fill="#F6FFDF" x="-0.5" y="-0.5" width="240" height="41.5679012"></rect>
                    <text id="Properties" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="14" font-weight="300" letter-spacing="0.154000005"></text>
                </g>
                <g id="方法" transform="translate(0.039967, 65.432099)">
                    <path d="M239.5,-0.5 L239.5,36.5679012 C239.5,37.8105419 238.99632,38.9355419 238.181981,39.7498817 C237.367641,40.5642216 236.242641,41.0679012 235,41.0679012 L235,41.0679012 L4,41.0679012 C2.75735931,41.0679012 1.63235931,40.5642216 0.818019485,39.7498817 C0.00367965644,38.9355419 -0.5,37.8105419 -0.5,36.5679012 L-0.5,36.5679012 L-0.5,-0.5 L239.5,-0.5 Z" stroke="#979797" fill="#FFDFDF"></path>
                    <text id="Methods" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="14" font-weight="300" letter-spacing="0.154000005"></text>
                </g>
            </g>
            <g id="UML/类图/类模块备份-5" transform="translate(310.000000, 419.000000)">
                <g id="名称" transform="translate(-0.311504, 0.000000)">
                    <path d="M235.351471,-0.5 C236.594111,-0.5 237.719111,0.00367965644 238.533451,0.818019485 C239.347791,1.63235931 239.851471,2.75735931 239.851471,4 L239.851471,4 L239.851471,25.3641975 L-0.148529412,25.3641975 L-0.148529412,4 C-0.148529412,2.75735931 0.355150245,1.63235931 1.16949007,0.818019485 C1.9838299,0.00367965644 3.1088299,-0.5 4.35147059,-0.5 L4.35147059,-0.5 Z" id="标题" stroke="#979797" fill="#F4F4F4"></path>
                    <text id="Class-Name" font-family="NotoSansCJKsc-Medium, Noto Sans CJK SC" font-size="14" font-weight="400" letter-spacing="0.154000005" fill="#020202" fill-opacity="0.88378138">
                        <tspan x="56.8864705" y="16">ApplicationThread</tspan>
                    </text>
                </g>
                <g id="属性" transform="translate(0.039967, 24.864198)">
                    <rect stroke="#979797" fill="#F6FFDF" x="-0.5" y="-0.5" width="240" height="41.5679012"></rect>
                    <text id="Properties" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="14" font-weight="300" letter-spacing="0.154000005"></text>
                </g>
                <g id="方法" transform="translate(0.039967, 65.432099)">
                    <path d="M239.5,-0.5 L239.5,36.5679012 C239.5,37.8105419 238.99632,38.9355419 238.181981,39.7498817 C237.367641,40.5642216 236.242641,41.0679012 235,41.0679012 L235,41.0679012 L4,41.0679012 C2.75735931,41.0679012 1.63235931,40.5642216 0.818019485,39.7498817 C0.00367965644,38.9355419 -0.5,37.8105419 -0.5,36.5679012 L-0.5,36.5679012 L-0.5,-0.5 L239.5,-0.5 Z" stroke="#979797" fill="#FFDFDF"></path>
                    <text id="Methods" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="14" font-weight="300" letter-spacing="0.154000005"></text>
                </g>
            </g>
            <g id="UML/类图/类模块备份" transform="translate(32.000000, 183.000000)">
                <g id="名称" transform="translate(-0.284133, 0.000000)">
                    <path d="M214.320588,-0.5 C215.563229,-0.5 216.688229,0.00367965644 217.502569,0.818019485 C218.316909,1.63235931 218.820588,2.75735931 218.820588,4 L218.820588,4 L218.820588,27.4753086 L-0.179411765,27.4753086 L-0.179411765,4 C-0.179411765,2.75735931 0.324267892,1.63235931 1.13860772,0.818019485 C1.95294755,0.00367965644 3.07794755,-0.5 4.32058824,-0.5 L4.32058824,-0.5 Z" id="标题" stroke="#979797" fill="#F4F4F4"></path>
                    <text id="Class-Name" font-family="NotoSansCJKsc-Medium, Noto Sans CJK SC" font-size="14" font-weight="400" letter-spacing="0.154000005" fill="#020202" fill-opacity="0.88378138">
                        <tspan x="59.2005882" y="16">ProcessRecord</tspan>
                    </text>
                </g>
                <g id="属性" transform="translate(0.036455, 26.975309)">
                    <rect stroke="#979797" fill="#F6FFDF" x="-0.5" y="-0.5" width="219" height="45.0123457"></rect>
                    <text id="Properties" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="14" font-weight="300" letter-spacing="0.154000005" fill="#020202" fill-opacity="0.88378138">
                        <tspan x="6" y="17">thread:IApplicationThread </tspan>
                        <tspan x="6" y="37">pid: int</tspan>
                    </text>
                </g>
                <g id="方法" transform="translate(0.036455, 70.987654)">
                    <path d="M218.5,-0.5 L218.5,40.0123457 C218.5,41.2549864 217.99632,42.3799864 217.181981,43.1943262 C216.367641,44.008666 215.242641,44.5123457 214,44.5123457 L214,44.5123457 L4,44.5123457 C2.75735931,44.5123457 1.63235931,44.008666 0.818019485,43.1943262 C0.00367965644,42.3799864 -0.5,41.2549864 -0.5,40.0123457 L-0.5,40.0123457 L-0.5,-0.5 L218.5,-0.5 Z" stroke="#979797" fill="#FFDFDF"></path>
                    <text id="Methods" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="14" font-weight="300" letter-spacing="0.154000005"></text>
                </g>
            </g>
            <g id="UML/类图/类模块备份-2" transform="translate(32.000000, 332.000000)">
                <g id="名称" transform="translate(-0.284133, 0.000000)">
                    <path d="M214.320588,-0.5 C215.563229,-0.5 216.688229,0.00367965644 217.502569,0.818019485 C218.316909,1.63235931 218.820588,2.75735931 218.820588,4 L218.820588,4 L218.820588,27.4753086 L-0.179411765,27.4753086 L-0.179411765,4 C-0.179411765,2.75735931 0.324267892,1.63235931 1.13860772,0.818019485 C1.95294755,0.00367965644 3.07794755,-0.5 4.32058824,-0.5 L4.32058824,-0.5 Z" id="标题" stroke="#979797" fill="#F4F4F4"></path>
                    <text id="Class-Name" font-family="NotoSansCJKsc-Medium, Noto Sans CJK SC" font-size="14" font-weight="400" letter-spacing="0.154000005" fill="#020202" fill-opacity="0.88378138">
                        <tspan x="59.6275882" y="16">ActivityThread</tspan>
                    </text>
                </g>
                <g id="属性" transform="translate(0.036455, 26.975309)">
                    <rect stroke="#979797" fill="#F6FFDF" x="-0.5" y="-0.5" width="219" height="45.0123457"></rect>
                    <text id="Properties" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="14" font-weight="300" letter-spacing="0.154000005" fill="#020202" fill-opacity="0.88378138">
                        <tspan x="6" y="17">mAppThread:ApplicationThread</tspan>
                    </text>
                </g>
                <g id="方法" transform="translate(0.036455, 70.987654)">
                    <path d="M218.5,-0.5 L218.5,40.0123457 C218.5,41.2549864 217.99632,42.3799864 217.181981,43.1943262 C216.367641,44.008666 215.242641,44.5123457 214,44.5123457 L214,44.5123457 L4,44.5123457 C2.75735931,44.5123457 1.63235931,44.008666 0.818019485,43.1943262 C0.00367965644,42.3799864 -0.5,41.2549864 -0.5,40.0123457 L-0.5,40.0123457 L-0.5,-0.5 L218.5,-0.5 Z" stroke="#979797" fill="#FFDFDF"></path>
                    <text id="Methods" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="14" font-weight="300" letter-spacing="0.154000005"></text>
                </g>
            </g>
            <g id="UML/类图/线条/聚合" transform="translate(132.000000, 149.000000)">
                <path id="直线-24" d="M4.01066824,9.66098325 L5.01044532,9.68209681 L4.99988854,10.1819853 L4.65783637,26.3789701 L4.529,32.448 L8.22683349,26.1900249 L8.4811105,25.7595099 L9.34214059,26.2680639 L9.08786358,26.6985789 L4.41995827,34.6017846 L3.96791026,35.3671447 L3.54857702,34.5833825 L-0.781511421,26.4901549 L-1.01738637,26.0492887 L-0.135653962,25.5775388 L0.100220985,26.018405 L3.529,32.428 L3.65805929,26.3578565 L4.00011146,10.1608718 L4.01066824,9.66098325 Z" fill="#979797" fill-rule="nonzero"></path>
                <path d="M4.5065476,0.824414956 L8.13197663,5.5 L4.5065476,10.175585 L0.998600008,5.5 L4.5065476,0.824414956 Z" id="多边形" stroke="#979797"></path>
            </g>
            <g id="编组" transform="translate(277.500000, 162.500000)" fill="#979797">
                <g id="UML/类图/线条/组合" transform="translate(2.500000, 29.500000) rotate(-90.000000) translate(-2.500000, -29.500000) ">
                    <path id="直线-24" d="M2.00288144,9.84713507 L3.00286493,9.85288144 L2.99999174,10.3528732 L2.76527988,51.1974318 L2.73,57.282 L6.33087375,50.9672406 L6.57850452,50.5328687 L7.44724844,51.0281302 L7.19961767,51.4625022 L2.653721,59.4365114 L2.21348852,60.2087282 L1.78215985,59.431503 L-2.67179488,51.4057764 L-2.91441726,50.9685872 L-2.04003889,50.4833425 L-1.79741651,50.9205317 L1.73,57.276 L1.76529639,51.1916854 L2.00000826,10.3471268 L2.00288144,9.84713507 Z" fill-rule="nonzero"></path>
                    <polygon id="多边形" stroke="#979797" points="2.46928974 0 6.73396667 5.5 2.46928974 11 -1.65719103 5.5"></polygon>
                </g>
            </g>
            <g id="编组" transform="translate(278.500000, 402.500000)" fill="#979797">
                <g id="UML/类图/线条/组合" transform="translate(2.500000, 29.500000) rotate(-90.000000) translate(-2.500000, -29.500000) ">
                    <path id="直线-24" d="M2.00288144,9.84713507 L3.00286493,9.85288144 L2.99999174,10.3528732 L2.76527988,51.1974318 L2.73,57.282 L6.33087375,50.9672406 L6.57850452,50.5328687 L7.44724844,51.0281302 L7.19961767,51.4625022 L2.653721,59.4365114 L2.21348852,60.2087282 L1.78215985,59.431503 L-2.67179488,51.4057764 L-2.91441726,50.9685872 L-2.04003889,50.4833425 L-1.79741651,50.9205317 L1.73,57.276 L1.76529639,51.1916854 L2.00000826,10.3471268 L2.00288144,9.84713507 Z" fill-rule="nonzero"></path>
                    <polygon id="多边形" stroke="#979797" points="2.46928974 0 6.73396667 5.5 2.46928974 11 -1.65719103 5.5"></polygon>
                </g>
            </g>
            <g id="UML/类图/线条/实现" transform="translate(425.000000, 202.000000)" stroke="#979797">
                <line x1="4.5" y1="61.6653117" x2="4.5" y2="7.44579946" id="直线-24" stroke-linecap="square" stroke-dasharray="2"></line>
                <path d="M4.5,0.218033989 L7.69098301,6.6 L1.30901699,6.6 L4.5,0.218033989 Z" id="三角形"></path>
            </g>
            <g id="UML/类图/线条/继承" transform="translate(430.000000, 370.000000)" stroke="#979797">
                <line x1="4.5" y1="48.7469136" x2="4.5" y2="8" id="直线-24" stroke-linecap="square"></line>
                <path d="M4.5,1.11803399 L7.69098301,7.5 L1.30901699,7.5 L4.5,1.11803399 Z" id="三角形"></path>
            </g>
        </g>
    </g>
</svg>


现在我们看下 ServiceRecord 是何时构造的，首先，根据方法的调用层次，我们可以看到：

* `ActiveServices.bindServiceLocked` 方法中，参数中没有ServiceRecord，有的是IApplicationThread及一个IBinder。
* `ActiveServices.requestServiceBindingLocked` 方法中，则变成了ServiceRecord类型。

![image-20210410215833909](https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20210410215833.png)

> 提示：上述调用层次可以在IDEA中选中`ActiveServices.requestServiceBindingLocked`方法，然后通过“**Navigate｜Call Hierarchy**”（快捷键为==ctrl+opt+H==）弹出。



所以，接下来我们看下 `ActiveServices.bindServiceLocked` 方法如何将`ApplicationThread`存入到`ServiceRecord`对象中。

##### ActiveServices.bindServiceLocked

```java
    int bindServiceLocked(IApplicationThread caller, IBinder token, Intent service,
            String resolvedType, final IServiceConnection connection, int flags,
            String instanceName, String callingPackage, final int userId)
            throws TransactionTooLargeException {
        final int callingPid = Binder.getCallingPid();
        final int callingUid = Binder.getCallingUid();
        // 这里获取了 ProcessRecord
        final ProcessRecord callerApp = mAm.getRecordForAppLocked(caller);

        final boolean callerFg = callerApp.setSchedGroup != ProcessList.SCHED_GROUP_BACKGROUND;
        final boolean isBindExternal = (flags & Context.BIND_EXTERNAL_SERVICE) != 0;
        final boolean allowInstant = (flags & Context.BIND_ALLOW_INSTANT) != 0;

        // 将IApplicationThread及IBinder放入到ServiceRecord中的过程在retrieveServiceLocked中
        ServiceLookupResult res =
            retrieveServiceLocked(service, instanceName, resolvedType, callingPackage,
                    callingPid, callingUid, userId, true,
                    callerFg, isBindExternal, allowInstant);
        // 此处获取ServiceRecord，故在上面
        ServiceRecord s = res.record;
        if (s.app != null && b.intent.received) {
            requestServiceBindingLocked(s, b.intent, callerFg, true);
        } else if (!b.intent.requested) {
            requestServiceBindingLocked(s, b.intent, callerFg, false);
        }
        return 1;
    }
```

到这里，我们可以发现ServiceRecord是通过`retrieveServiceLocked`方法获取到的`ServiceLookupResult`获取到的。

==粗略看了下这个`retrieveServiceLocked`方法，其中逻辑比较多，我们这里转换下思路，直接查找 `ServiceRecord.app` 的赋值操作==。

##### `ServiceRecord.app` 的赋值

我们可以找到ServiceRecord.app（ProcessRecord）的赋值操作的调用方法为：`com.android.server.am.ActiveServices#realStartServiceLocked`

```java
private final void realStartServiceLocked(ServiceRecord r,
            ProcessRecord app, boolean execInFg) throws RemoteException {
        if (app.thread == null) {
            throw new RemoteException();
        }
    	// 在此处赋值
        r.setProcess(app);
	    // ...
}
```

查看 `realStartServiceLocked` 的调用序列：

<img src="https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20210410224824.png" alt="image-20210410224824691" style="zoom:50%;" />

也就是又回到了我们的 `bindServiceLocked` 方法，其中有一段逻辑是，如果需要创建服务，就执行 `bringUpServiceLocked` 方法。

```java
// com.android.server.am.ActiveServices#bindServiceLocked   
int bindServiceLocked(IApplicationThread caller, IBinder token, Intent service,
            String resolvedType, final IServiceConnection connection, int flags,
            String instanceName, String callingPackage, final int userId)
            throws TransactionTooLargeException {   
        // ... 
			if ((flags&Context.BIND_AUTO_CREATE) != 0) {
                s.lastActivity = SystemClock.uptimeMillis();
                if (bringUpServiceLocked(s, service.getFlags(), callerFg, false,
                        permissionsReviewRequired) != null) {
                    return 0;
                }
            }
        // ... 
    }
```

也就是说，在绑定服务的时候，如果服务没有创建，就先使用`bringUpServiceLocked`-`realStartServiceLocked` 进行创建，创建过程中会将ServiceRecord中的app赋值，然后存储起来；

> 提示：我们可以通过如下IDEA操作来查找赋值操作
>
> 1. 选中成员（这里是 app）；
>
> 2. ==Ctrl+B== 或者 ==Command+鼠标单击==，弹出使用列表弹窗；
>
> 3. 然后在弹窗中设置仅查看write访问操作的；然后我们可以找到对应的赋值代码行；
>
>    <img src="https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20210410223230.png" alt="image-20210410223230694" style="zoom:50%;" />
>
> 4. 通过勾选其中的方法图标，我们可以显示赋值的代码行所在的方法（这里是setProcess）；
>
>    <img src="https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20210410223820.png" alt="image-20210410223820657" style="zoom:50%;" />
>
> 5. 然后我们继续在方法上执行上述操作，可以获取到更加上一步的赋值调用在哪；
>
>    <img src="https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20210410224023.png" alt="image-20210410224023641" style="zoom:50%;" />

### 服务如何绑定？服务如何启动？进程如何启动？

1. **bringUpServiceLocked(ServiceRecord r,...)** 第一个参数为ServiceRecord，其中的app属性可存储一个进程记录； 
2. 如传入的ServiceRecord参数中表明服务已经启动过，`r.app(ProcessRecord)` 不为null，且`r.app.thread(IApplicationThread)`也不为null，则不创建，直接更新参数；
3. 结下来，则分为两种情况，1）服务为声明单独的进程，则可直接在当前进程中启动；2）服务声明了单独的进程，则需要先启动进程，然后再启动服务；
4. **非单独进程**：
   * 进程记录获取：通过AMS直接查询，并未创建，因为进程已经存在了，具体代码为 `app = mAm.getProcessRecordLocked(procName, r.appInfo.uid, false)`
   * 服务启动：使用 `realStartServiceLocked(r, app, execInFg);` 方法启动
5. **单独进程**：
   * 进程记录获取： 通过AMS.mAm.startProcessLocked 方法启动一个新的进程； 
     * `app=mAm.startProcessLocked(procName, r.appInfo, true, intentFlags,
                           hostingRecord, ZYGOTE_POLICY_FLAG_EMPTY, false, isolated, false)`
   * 服务启动：未在此方法中直接调用 `realStartServiceLocked`

这里我们可以看到，在**单独进程**的服务启动流程中，并没有即时调用`realStartServiceLocked`来启动服务，那么这里就又个问题，独立进程情况下服务何时启动？

6. **单独进程服务启动：** 将待启动的服务加入到`mPendingServices(ArrayList<ServiceRecord>)`，在启动进程后再从此列表中读取需要启动的服务，然后启动；



**总结：** 

1. 进程记录如何获取？

   * 通过AMS的 `startProcessLocked` 方法创建（非独立进程的也应该是通过此方法创建，只是创建时机不是这里）

2. 服务如何启动？

   * 通过 `realStartServiceLocked` 方法启动（独立进程的应该也是此方法启动，会等到进程启动之后再启动）

   * > `realStartServiceLocked` 中通过 `IApplicationThread` 执行 `scheduleCreateService` 来启动服务，最终调用 `android.app.ActivityThread.ApplicationThread#scheduleCreateService`来启动；

### 进程创建

> 问题：
>
> 1. 进程何时创建？- 已解决
> 2. ApplicationThread（代理）对象何时设置到ProcessRecord中? - 已解决
> 3. ActivityThread#main的入口点中，如何获取之前的结果？ - 已解决

下面为创建进程的调用序列，注意如下序列中只是创建了一个ProcessRecord的对象，对应于Linux上的进程创建我们再起文章进行分析，对于我们的Service来说，拿到ProcessRecord对象即可供我们来创建服务；


<svg width="684px" height="748px" viewBox="0 0 684 748" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
    <g id="Android源码分析" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd">
        <g id="bindService流程分析-加入启动流程" transform="translate(-923.000000, -331.000000)">
            <g id="架构图/模块-源码备份-25" transform="translate(925.000000, 417.000000)">
                <rect id="矩形" stroke="#979797" fill="#D5FFA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="13.8711791" y="14">ActivityManagerService#startProcessLocked</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="44.0851371" y="30.122449">com/android/server/am/ActivityManagerService.java</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-37" transform="translate(1254.000000, 417.000000)">
                <rect id="矩形" stroke="#979797" fill="#D5FFA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="13.8711791" y="14">ActivityManagerService#startProcessLocked</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="37.0705764" y="30.122449">startProcessLocked(hostingRecord, entryPoint) 带入口点</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-38" transform="translate(1232.000000, 473.000000)">
                <rect id="矩形" stroke="#979797" fill="#D5FFA2" x="0.5" y="0.5" width="173.816901" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="11.1847185" y="14">ProcessList#startProcess</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="14.2951452" y="30.122449">带入口类 android.app.ActivityThread</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-49" transform="translate(1423.000000, 473.000000)">
                <rect id="矩形" stroke="#979797" fill="#D5FFA2" x="0.5" y="0.5" width="182.859155" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="2.72977831" y="14">handleProcessStartedLocked</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="29.1292427" y="30.122449">记录ProcessRecord（通过PID）</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-39" transform="translate(1254.000000, 529.000000)">
                <rect id="矩形" stroke="#979797" fill="#D5FFA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="22.2538402" y="14">android.os.ZygoteProcess#startViaZygote</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="76.586225" y="30.122449">带入口类 android.app.ActivityThread</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-40" transform="translate(1254.000000, 585.000000)">
                <rect id="矩形" stroke="#979797" fill="#D5FFA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="11.0871121" y="14">ZygoteProcess#zygoteSendArgsAndGetResult</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="76.586225" y="30.122449">带入口类 android.app.ActivityThread</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-41" transform="translate(1254.000000, 647.000000)">
                <rect id="矩形" stroke="#979797" fill="#FFED99" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="129.589673" y="14">zygote</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="110.270911" y="30.122449">zygote创建新的进程</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-42" transform="translate(1254.000000, 703.000000)">
                <rect id="矩形" stroke="#979797" fill="#FFBBA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="80.8715473" y="14">ActivityThread#main()</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="101.306895" y="30.122449">进程创建后执行入口函数</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-44" transform="translate(1254.000000, 758.000000)">
                <rect id="矩形" stroke="#979797" fill="#FFBBA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="81.6756979" y="14">ActivityThread#attach</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="134.190911" y="30.122449">module</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-26" transform="translate(925.000000, 477.000000)">
                <rect id="矩形" stroke="#979797" fill="#D5FFA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="46.9144594" y="14">ProcessList#startProcessLocked()</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="67.9050534" y="30.122449">com/android/server/am/ProcessList.java</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-11" transform="translate(923.000000, 532.000000)">
                <rect id="矩形" stroke="#979797" fill="#D5FFA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="31.8488192" y="14">ProcessList#newProcessRecordLocked</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="67.9050534" y="30.122449">com/android/server/am/ProcessList.java</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-27" transform="translate(923.000000, 582.000000)">
                <rect id="矩形" stroke="#979797" fill="#D5FFA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="31.8488192" y="14">ProcessList#newProcessRecordLocked</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="69.8066434" y="30.122449">new ProcessRecord(ams, info, proc, uid)</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-9" transform="translate(923.000000, 368.000000)">
                <rect id="矩形" stroke="#979797" fill="#D5FFA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="32.543313" y="14">ActiveServices#bringUpServiceLocked</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="62.0131706" y="30.122449">com/android/server/am/ActiveServices.java</tspan>
                </text>
            </g>
            <path id="直线-7备份" d="M1073.93515,400.012222 L1073.935,408.997 L1077.67573,408.997076 L1073.5,416.997076 L1069.32427,408.997076 L1073.064,408.997 L1073.06485,400.012222 L1073.93515,400.012222 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-8备份" d="M1073.93515,449.998187 L1073.935,468.011 L1077.67573,468.011111 L1073.5,476.011111 L1069.32427,468.011111 L1073.064,468.011 L1073.06485,449.998187 L1073.93515,449.998187 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-9备份" d="M1073.93515,508.990779 L1073.935,524.018 L1077.67573,524.018519 L1073.5,532.018519 L1069.32427,524.018519 L1073.064,524.018 L1073.06485,508.990779 L1073.93515,508.990779 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-10备份" d="M1073.93515,565.012222 L1073.935,573.997 L1077.67573,573.997076 L1073.5,581.997076 L1069.32427,573.997076 L1073.064,573.997 L1073.06485,565.012222 L1073.93515,565.012222 Z" fill="#979797" fill-rule="nonzero"></path>
            <text id="创建进程" font-family="NotoSansCJKsc-Black, Noto Sans CJK SC" font-size="18.2" font-weight="800" letter-spacing="0.200199999" fill="#020202" fill-opacity="0.88378138">
                <tspan x="1223.1996" y="347">创建进程</tspan>
            </text>
            <line x1="1222.66" y1="434.5" x2="1254.34" y2="434.5" id="直线-23" stroke="#979797" stroke-width="1.3" stroke-linecap="square"></line>
            <path id="直线-13" d="M1353.15,450.007895 L1353.15,463.953 L1357.75,463.953216 L1352.5,474.953216 L1347.25,463.953216 L1351.85,463.953 L1351.85,450.007895 L1353.15,450.007895 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-14" d="M1372.15,505.988889 L1372.15,517.972 L1376.75,517.972222 L1371.5,528.972222 L1366.25,517.972222 L1370.85,517.972 L1370.85,505.988889 L1372.15,505.988889 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-14备份" d="M1505.15,449.988889 L1505.15,461.972 L1509.75,461.972222 L1504.5,472.972222 L1499.25,461.972222 L1503.85,461.972 L1503.85,449.988889 L1505.15,449.988889 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-15" d="M1403.15,562.988889 L1403.15,574.972 L1407.75,574.972222 L1402.5,585.972222 L1397.25,574.972222 L1401.85,574.972 L1401.85,562.988889 L1403.15,562.988889 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-24" d="M1403.15,619.002174 L1403.15,637.958 L1407.75,637.958937 L1402.5,648.958937 L1397.25,637.958937 L1401.85,637.958 L1401.85,619.002174 L1403.15,619.002174 Z" fill="#979797" fill-rule="nonzero"></path>
            <text id="socket" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="10.4" font-weight="300" letter-spacing="0.114399999" fill="#020202" fill-opacity="0.88378138">
                <tspan x="1406.4208" y="634">socket</tspan>
            </text>
            <path id="直线-25" d="M1403.15,680.988889 L1403.15,692.972 L1407.75,692.972222 L1402.5,703.972222 L1397.25,692.972222 L1401.85,692.972 L1401.85,680.988889 L1403.15,680.988889 Z" fill="#979797" fill-rule="nonzero"></path>
            <line x1="1572.5" y1="503.649733" x2="1572.5" y2="988.350267" id="直线-26" stroke="#979797" stroke-width="1.3" stroke-linecap="square" stroke-dasharray="3.9"></line>
            <g id="架构图/模块-源码备份-45" transform="translate(1254.000000, 816.000000)">
                <rect id="矩形" stroke="#979797" fill="#FFBBA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="39.6222753" y="14">IActivityManager#attachApplication</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="134.190911" y="30.122449">module</tspan>
                </text>
            </g>
            <path id="直线-27" d="M1403.15,735.988889 L1403.15,747.972 L1407.75,747.972222 L1402.5,758.972222 L1397.25,747.972222 L1401.85,747.972 L1401.85,735.988889 L1403.15,735.988889 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-28" d="M1403.15,792 L1403.15,806.961 L1407.75,806.961111 L1402.5,817.961111 L1397.25,806.961111 L1401.85,806.961 L1401.85,792 L1403.15,792 Z" fill="#979797" fill-rule="nonzero"></path>
            <g id="架构图/模块-源码备份-46" transform="translate(1254.000000, 929.000000)">
                <rect id="矩形" stroke="#979797" fill="#D5FFA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="19.2199992" y="14">ActivityManagerService#attachApplication</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="134.190911" y="30.122449">module</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-47" transform="translate(1218.000000, 989.000000)">
                <rect id="矩形" stroke="#979797" fill="#D5FFA2" x="0.5" y="0.5" width="368.7277" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="32.5625946" y="14">ActivityManagerService#attachApplicationLocked</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="113.952385" y="30.122449">获取之前缓存的ProcessRecord(app)</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-50" transform="translate(1218.000000, 1045.000000)">
                <rect id="矩形" stroke="#979797" fill="#D5FFA2" x="0.5" y="0.5" width="368.7277" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="100.665624" y="14">ProcessRecord#makeActive</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="67.8834312" y="30.122449">app.makeActive(thread, mProcessStats) ; thread = _thread;</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-36" transform="translate(1254.000000, 870.000000)">
                <rect id="矩形" stroke="#979797" fill="#FFED99" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="124.320049" y="14">transact</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="136.553756" y="30.122449">binder</tspan>
                </text>
            </g>
            <path id="直线-29" d="M1403.15,848.997059 L1403.15,859.964 L1407.75,859.964052 L1402.5,870.964052 L1397.25,859.964052 L1401.85,859.964 L1401.85,848.997059 L1403.15,848.997059 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-30" d="M1403.15,902.992857 L1403.15,918.968 L1407.75,918.968254 L1402.5,929.968254 L1397.25,918.968254 L1401.85,918.968 L1401.85,902.992857 L1403.15,902.992857 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-31" d="M1403.15,962.992857 L1403.15,978.968 L1407.75,978.968254 L1402.5,989.968254 L1397.25,978.968254 L1401.85,978.968 L1401.85,962.992857 L1403.15,962.992857 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-32" d="M1403.15,1022.98889 L1403.15,1034.972 L1407.75,1034.97222 L1402.5,1045.97222 L1397.25,1034.97222 L1401.85,1034.972 L1401.85,1022.98889 L1403.15,1022.98889 Z" fill="#979797" fill-rule="nonzero"></path>
        </g>
    </g>
</svg>



* 进程创建的执行位于AMS所在的系统进程之中；
* （AMS进程）首先，构建一个ProcessRecord记录，并将其记录到AMS中；
* （AMS进程）AMS通过socket通信，通知zygote来创建一个新的进程，同时指定入口点为 `android.app.ActivityThread` ;
* （APP进程）新的进程启动后，执行ActivityThread中的方法，通知AMS来执行attachApplication；
* （AMS进程）AMS中，通过PID获取之前存储的ProcessRecord，然后将ApplicationThread（代理对象）赋值给ProcessRecord的成员变量thread；
* 支持完成了关联；

#### 构造ProcessRecord实例

`com.android.server.am.ProcessList#startProcessLocked`，简化下来就两句：

* 构造ProcessRecord对象： `app = newProcessRecordLocked(info, processName, isolated, isolatedUid, hostingRecord)`
* 启动进程：`startProcessLocked(app, hostingRecord, zygotePolicyFlags, abiOverride)`

```java
// com.android.server.am.ProcessList#newProcessRecordLocked
// frameworks/base/services/core/java/com/android/server/am/ProcessList.java
final ProcessRecord startProcessLocked(String processName, ApplicationInfo info,
            boolean knownToBeDead, int intentFlags, HostingRecord hostingRecord,
            int zygotePolicyFlags, boolean allowWhileBooting, boolean isolated, int isolatedUid,
            boolean keepIfLarge, String abiOverride, String entryPoint, String[] entryPointArgs,
            Runnable crashHandler) {
        long startTime = SystemClock.uptimeMillis();
        ProcessRecord app;
        if (app == null) {
            // 构造ProcessRecord对象
            app = newProcessRecordLocked(info, processName, isolated, isolatedUid, hostingRecord);
            app.crashHandler = crashHandler;
            app.isolatedEntryPoint = entryPoint;
            app.isolatedEntryPointArgs = entryPointArgs;
        } else {
            // If this is a new package in the process, add the package to the list
            app.addPackage(info.packageName, info.longVersionCode, mService.mProcessStats);
        }
	    // 启动进程
        final boolean success =
                startProcessLocked(app, hostingRecord, zygotePolicyFlags, abiOverride);
        checkSlow(startTime, "startProcess: done starting proc!");
        return success ? app : null;
    }
```

#### 启动进程 

`startProcessLocked`: 启动了一个进程，并指定了入口点为 ==android.app.ActivityThread==，也就是进程启动后将会执行 ==android.app.ActivityThread==的main方法。

```java
// frameworks/base/services/core/java/com/android/server/am/ProcessList.java
// com.android.server.am.ProcessList#startProcessLocked(com.android.server.am.ProcessRecord, com.android.server.am.HostingRecord, int, boolean, boolean, boolean, java.lang.String)
boolean startProcessLocked(ProcessRecord app, HostingRecord hostingRecord,
            int zygotePolicyFlags, boolean disableHiddenApiChecks, boolean disableTestApiChecks,
            boolean mountExtStorageFull, String abiOverride) {
        if (app.pendingStart) {
            return true;
        }
        long startTime = SystemClock.uptimeMillis();
        try {
            try {
                final int userId = UserHandle.getUserId(app.uid);
                AppGlobals.getPackageManager().checkPackageStartable(app.info.packageName, userId);
            } catch (RemoteException e) {
                throw e.rethrowAsRuntimeException();
            }

            int uid = app.uid;
            int[] gids = null;
            // ... 
            
            app.mountMode = mountExternal;
            app.gids = gids;
            app.setRequiredAbi(requiredAbi);
            app.instructionSet = instructionSet;

            final String seInfo = app.info.seInfo
                    + (TextUtils.isEmpty(app.info.seInfoUser) ? "" : app.info.seInfoUser);
            // Start the process.  It will either succeed and return a result containing
            // the PID of the new process, or else throw a RuntimeException.
            // 指定入口点为ActivityThread，启动进程
            final String entryPoint = "android.app.ActivityThread";
            return startProcessLocked(hostingRecord, entryPoint, app, uid, gids,
                    runtimeFlags, zygotePolicyFlags, mountExternal, seInfo, requiredAbi,
                    instructionSet, invokeWith, startTime);
        } catch (RuntimeException e) {
            return false;
        }
    }


boolean startProcessLocked(HostingRecord hostingRecord, String entryPoint, ProcessRecord app,
            int uid, int[] gids, int runtimeFlags, int zygotePolicyFlags, int mountExternal,
            String seInfo, String requiredAbi, String instructionSet, String invokeWith,
            long startTime) {
        app.pendingStart = true;
        app.killedByAm = false;
        app.removed = false;
        app.killed = false;
        final long startSeq = app.startSeq = ++mProcStartSeqCounter;
        app.setStartParams(uid, hostingRecord, seInfo, startTime);
        app.setUsingWrapper(invokeWith != null
                || Zygote.getWrapProperty(app.processName) != null);
        mPendingStarts.put(startSeq, app);

        if (mService.mConstants.FLAG_PROCESS_START_ASYNC) {
            return true;
        } else {
            try {
                // 启动进程，并传入entrypoint
                final Process.ProcessStartResult startResult = startProcess(hostingRecord,
                        entryPoint, app,
                        uid, gids, runtimeFlags, zygotePolicyFlags, mountExternal, seInfo,
                        requiredAbi, instructionSet, invokeWith, startTime);
                // 做启动后的操作
                handleProcessStartedLocked(app, startResult.pid, startResult.usingWrapper,
                        startSeq, false);
            } catch (RuntimeException e) {
                
            }
            return app.pid > 0;
        }
    }
```

这里我们省略其他更加底层的步骤的分析，我们只需要知道到了这里之后，会启动一个进程，进程启动后会执行 ==android.app.ActivityThread#main== 方法；

#### 记录进程记录到AMS

`ProcessList#handleProcessStartedLocked(com.android.server.am.ProcessRecord, int, boolean, long, boolean)`

==这个地方有个关键的代码将之前创建的进程记录存储到了AMS的进程记录表中。==

```java
// com.android.server.am.ProcessList#handleProcessStartedLocked(com.android.server.am.ProcessRecord, int, boolean, long, boolean)
// frameworks/base/services/core/java/com/android/server/am/ProcessList.java
ActivityManagerService mService = null;
boolean handleProcessStartedLocked(ProcessRecord app, int pid, boolean usingWrapper,
            long expectedStartSeq, boolean procAttached) {
    // 将ProcessRecord 存储到AMS中
    mService.addPidLocked(app);
}
  
// frameworks/base/services/core/java/com/android/server/am/ActivityManagerService.java
void addPidLocked(ProcessRecord app) {
    synchronized (mPidsSelfLocked) {
        // 将进程记录添加到一个记录表中
        mPidsSelfLocked.doAddInternal(app);
    }
    synchronized (sActiveProcessInfoSelfLocked) {
        if (app.processInfo != null) {
            sActiveProcessInfoSelfLocked.put(app.pid, app.processInfo);
        } else {
            sActiveProcessInfoSelfLocked.remove(app.pid);
        }
    }
    mAtmInternal.onProcessMapped(app.pid, app.getWindowProcessController());
}
```
```java
// 完整代码
// com.android.server.am.ProcessList#handleProcessStartedLocked(com.android.server.am.ProcessRecord, int, boolean, long, boolean)
// frameworks/base/services/core/java/com/android/server/am/ProcessList.java
boolean handleProcessStartedLocked(ProcessRecord app, int pid, boolean usingWrapper,
            long expectedStartSeq, boolean procAttached) {
        mPendingStarts.remove(expectedStartSeq);
        final String reason = isProcStartValidLocked(app, expectedStartSeq);
        if (reason != null) {
            Slog.w(TAG_PROCESSES, app + " start not valid, killing pid=" +
                    pid
                    + ", " + reason);
            app.pendingStart = false;
            killProcessQuiet(pid);
            Process.killProcessGroup(app.uid, app.pid);
            noteAppKill(app, ApplicationExitInfo.REASON_OTHER,
                    ApplicationExitInfo.SUBREASON_INVALID_START, reason);
            return false;
        }
        mService.mBatteryStatsService.noteProcessStart(app.processName, app.info.uid);
        checkSlow(app.startTime, "startProcess: done updating battery stats");

        EventLog.writeEvent(EventLogTags.AM_PROC_START,
                UserHandle.getUserId(app.startUid), pid, app.startUid,
                app.processName, app.hostingRecord.getType(),
                app.hostingRecord.getName() != null ? app.hostingRecord.getName() : "");

        try {
            AppGlobals.getPackageManager().logAppProcessStartIfNeeded(app.processName, app.uid,
                    app.seInfo, app.info.sourceDir, pid);
        } catch (RemoteException ex) {
            // Ignore
        }

        Watchdog.getInstance().processStarted(app.processName, pid);

        checkSlow(app.startTime, "startProcess: building log message");
        StringBuilder buf = mStringBuilder;
        buf.setLength(0);
        buf.append("Start proc ");
        buf.append(pid);
        buf.append(':');
        buf.append(app.processName);
        buf.append('/');
        UserHandle.formatUid(buf, app.startUid);
        if (app.isolatedEntryPoint != null) {
            buf.append(" [");
            buf.append(app.isolatedEntryPoint);
            buf.append("]");
        }
        buf.append(" for ");
        buf.append(app.hostingRecord.getType());
        if (app.hostingRecord.getName() != null) {
            buf.append(" ");
            buf.append(app.hostingRecord.getName());
        }
        mService.reportUidInfoMessageLocked(TAG, buf.toString(), app.startUid);
        app.setPid(pid);
        app.setUsingWrapper(usingWrapper);
        app.pendingStart = false;
        checkSlow(app.startTime, "startProcess: starting to update pids map");
        ProcessRecord oldApp;
        synchronized (mService.mPidsSelfLocked) {
            oldApp = mService.mPidsSelfLocked.get(pid);
        }
        // If there is already an app occupying that pid that hasn't been cleaned up
        if (oldApp != null && !app.isolated) {
            // Clean up anything relating to this pid first
            Slog.wtf(TAG, "handleProcessStartedLocked process:" + app.processName
                    + " startSeq:" + app.startSeq
                    + " pid:" + pid
                    + " belongs to another existing app:" + oldApp.processName
                    + " startSeq:" + oldApp.startSeq);
            mService.cleanUpApplicationRecordLocked(oldApp, false, false, -1,
                    true /*replacingPid*/);
        }
    // 注意这里 
        mService.addPidLocked(app);
        synchronized (mService.mPidsSelfLocked) {
            if (!procAttached) {
                Message msg = mService.mHandler.obtainMessage(PROC_START_TIMEOUT_MSG);
                msg.obj = app;
                mService.mHandler.sendMessageDelayed(msg, usingWrapper
                        ? PROC_START_TIMEOUT_WITH_WRAPPER : PROC_START_TIMEOUT);
            }
        }
        checkSlow(app.startTime, "startProcess: done updating pids map");
        return true;
    }
```

#### 写入thread值到ProcessRecord

从上面的流程中，我们发现构造出来的ProcessRecord的thread（ApplicationThread）成员变量还是没有被赋值，那么这个thread何时被赋值呢？

> 查找`ProcessRecord`中`thread`赋值的入口：
>
> 1. 通过查找`thread`成员的赋值写入方法，可以确定起始点是，`com.android.server.am.ProcessRecord#makeActive` ，接下来查看调用这个方法的列表：
> 2. ![image-20210411172323572](https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20210411172323.png)
>
> 3. 这里我们显然选择 `com.android.server.am.ActivityManagerService#attachApplicationLocked`
>
> 4. `android.app.ActivityThread#attach`
>
> 5. 这里我们遇到两个选择：
>
>    <img src="https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20210411172524.png" alt="image-20210411172524831" style="zoom:50%;" />
>
> 6. 显然，应该选择第二个：`android.app.ActivityThread#main`
>
> 7. 这里我们却无法直接通过IDEA的调用层次功能找到任何调用方法，说明可能是通过反射来调用的，所以直接通过全局字符串搜索==android.app.ActivityThread==，可以找到在 `ProcessList.startProcessLocked` 中调用的。

通过上面的分析，这里我们从ActivityThread的main函数开始。

#####  ActivityThread#main

```java
    public static void main(String[] args) {
        Trace.traceBegin(Trace.TRACE_TAG_ACTIVITY_MANAGER, "ActivityThreadMain");

        // Install selective syscall interception
        AndroidOs.install();

        // CloseGuard defaults to true and can be quite spammy.  We
        // disable it here, but selectively enable it later (via
        // StrictMode) on debug builds, but using DropBox, not logs.
        CloseGuard.setEnabled(false);

        Environment.initForCurrentUser();

        // Make sure TrustedCertificateStore looks in the right place for CA certificates
        final File configDir = Environment.getUserConfigDirectory(UserHandle.myUserId());
        TrustedCertificateStore.setDefaultUserDirectory(configDir);

        // Call per-process mainline module initialization.
        initializeMainlineModules();

        Process.setArgV0("<pre-initialized>");

        Looper.prepareMainLooper();

        // Find the value for {@link #PROC_START_SEQ_IDENT} if provided on the command line.
        // It will be in the format "seq=114"
        long startSeq = 0;
        if (args != null) {
            for (int i = args.length - 1; i >= 0; --i) {
                if (args[i] != null && args[i].startsWith(PROC_START_SEQ_IDENT)) {
                    startSeq = Long.parseLong(
                            args[i].substring(PROC_START_SEQ_IDENT.length()));
                }
            }
        }
        // 直接构造一个ActivityThread对象
        ActivityThread thread = new ActivityThread();
        // 执行attach方法
        thread.attach(false, startSeq);

        if (sMainThreadHandler == null) {
            sMainThreadHandler = thread.getHandler();
        }

        if (false) {
            Looper.myLooper().setMessageLogging(new
                    LogPrinter(Log.DEBUG, "ActivityThread"));
        }

        // End of event ActivityThreadMain.
        Trace.traceEnd(Trace.TRACE_TAG_ACTIVITY_MANAGER);
        Looper.loop();

        throw new RuntimeException("Main thread loop unexpectedly exited");
    }
```

##### ActivityThread#attach

```java
 private void attach(boolean system, long startSeq) {
        sCurrentActivityThread = this;
        mSystemThread = system;
        if (!system) {
            android.ddm.DdmHandleAppName.setAppName("<pre-initialized>",
                                                    UserHandle.myUserId());
            // 将当前ApplicationThread的Binder对象保存为一个静态成员
            RuntimeInit.setApplicationObject(mAppThread.asBinder());
            // 获取AMS
            final IActivityManager mgr = ActivityManager.getService();
            try {
                // 通知AMS来 attachApplication
                mgr.attachApplication(mAppThread, startSeq);
            } catch (RemoteException ex) {
                throw ex.rethrowFromSystemServer();
            }
        } else {
            
        }
}
```

##### **ActivityManagerService#attachApplication** & attachApplicationLocked

```java
    @Override
    public final void attachApplication(IApplicationThread thread, long startSeq) {
        if (thread == null) {
            throw new SecurityException("Invalid application interface");
        }
        synchronized (this) {
            int callingPid = Binder.getCallingPid();
            final int callingUid = Binder.getCallingUid();
            final long origId = Binder.clearCallingIdentity();
            attachApplicationLocked(thread, callingPid, callingUid, startSeq);
            Binder.restoreCallingIdentity(origId);
        }
    }

```
上面的方法只是调用了 attachApplicationLocked：

==有个关键的步骤是，从 AMS的进程记录表中根据PID取出一个 ProcessRecord: `app = mPidsSelfLocked.get(pid)`==

```java
private boolean attachApplicationLocked(@NonNull IApplicationThread thread,
            int pid, int callingUid, long startSeq) {
        // Find the application record that is being attached...  either via
        // the pid if we are running in multiple processes, or just pull the
        // next app record if we are emulating process with anonymous threads.
        ProcessRecord app;
        long startTime = SystemClock.uptimeMillis();
        long bindApplicationTimeMillis;
        if (pid != MY_PID && pid >= 0) {
            synchronized (mPidsSelfLocked) {
                // 从进程记录中获取
                app = mPidsSelfLocked.get(pid);
            }
        }
        // Make app active after binding application or client may be running requests (e.g
        // starting activities) before it is ready.
        // 关联thread到app（ProcessRecord）
        app.makeActive(thread, mProcessStats);
        return true;
    }
```

经过上面的步骤，即完成了ProcessRecord到进程的ApplicationThread的关联。

### 启动服务

从AMS中调用ApplicationThread的方法来在Service自己应该所属的进程中创建Service对象的实例。


<svg width="723px" height="508px" viewBox="0 0 723 508" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
    <g id="Android源码分析" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd">
        <g id="bindService流程分析-加入启动流程" transform="translate(-1687.000000, -331.000000)">
            <g id="架构图/模块-源码备份-42" transform="translate(2075.000000, 429.000000)">
                <rect id="矩形" stroke="#979797" fill="#FFBBA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="80.8715473" y="14">ActivityThread#main()</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="101.306895" y="30.122449">进程创建后执行入口函数</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-57" transform="translate(2075.000000, 370.000000)">
                <rect id="矩形" stroke="#979797" fill="#FFBBA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="96.4245514" y="14">独立进程的Service</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="132.102208" y="30.122449">启动进程</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-53" transform="translate(2075.000000, 483.000000)">
                <rect id="矩形" stroke="#979797" fill="#FFBBA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="81.6756979" y="14">ActivityThread#attach</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="148.202627" y="30.122449">-</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-28" transform="translate(1688.000000, 476.000000)">
                <rect id="矩形" stroke="#979797" fill="#D5FFA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="17.7639992" y="14">IApplicationThread#scheduleCreateService</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="75.1632961" y="30.122449">android/app/IApplicationThread.java</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-36" transform="translate(1688.000000, 535.000000)">
                <rect id="矩形" stroke="#979797" fill="#FFED99" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="124.320049" y="14">transact</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="136.553756" y="30.122449">binder</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-36" transform="translate(1687.000000, 750.000000)">
                <rect id="矩形" stroke="#979797" fill="#FFED99" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="124.320049" y="14">transact</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="136.553756" y="30.122449">binder</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-30" transform="translate(1687.000000, 590.000000)">
                <rect id="矩形" stroke="#979797" fill="#FFBBA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="19.8413883" y="14">ApplicationThread#scheduleCreateService</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="84.8453045" y="30.122449">android/app/ActivityThread.java</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-31" transform="translate(1687.000000, 641.000000)">
                <rect id="矩形" stroke="#979797" fill="#FFBBA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="37.6728192" y="14">ActivityThread#handleCreateService</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="84.8453045" y="30.122449">android/app/ActivityThread.java</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-33" transform="translate(1688.000000, 695.000000)">
                <rect id="矩形" stroke="#979797" fill="#FFBBA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="26.5913799" y="14">IActivityManager#serviceDoneExecuting</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="84.8453045" y="30.122449">android/app/ActivityThread.java</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-34" transform="translate(1687.000000, 805.000000)">
                <rect id="矩形" stroke="#979797" fill="#D5FFA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="6.18910375" y="14">ActivityManagerService#serviceDoneExecuting</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="84.8453045" y="30.122449">android/app/ActivityThread.java</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-9" transform="translate(1688.000000, 373.000000)">
                <rect id="矩形" stroke="#979797" fill="#D5FFA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="32.543313" y="14">ActiveServices#bringUpServiceLocked</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="62.0131706" y="30.122449">com/android/server/am/ActiveServices.java</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-43" transform="translate(1687.000000, 422.000000)">
                <rect id="矩形" stroke="#979797" fill="#D5FFA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="30.4598318" y="14">ActiveServices#realStartServiceLocked</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="62.0131706" y="30.122449">com/android/server/am/ActiveServices.java</tspan>
                </text>
            </g>
            <path id="直线-7备份-2" d="M1837.93515,405.012222 L1837.935,413.997 L1841.67573,413.997076 L1837.5,421.997076 L1833.32427,413.997076 L1837.064,413.997 L1837.06485,405.012222 L1837.93515,405.012222 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-8备份-2" d="M1836.93515,507.998187 L1836.935,526.011 L1840.67573,526.011111 L1836.5,534.011111 L1832.32427,526.011111 L1836.064,526.011 L1836.06485,507.998187 L1836.93515,507.998187 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-9备份-2" d="M1836.93515,567.990779 L1836.935,583.018 L1840.67573,583.018519 L1836.5,591.018519 L1832.32427,583.018519 L1836.064,583.018 L1836.06485,567.990779 L1836.93515,567.990779 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-10备份-2" d="M1836.93515,624.012222 L1836.935,632.997 L1840.67573,632.997076 L1836.5,640.997076 L1832.32427,632.997076 L1836.064,632.997 L1836.06485,624.012222 L1836.93515,624.012222 Z" fill="#979797" fill-rule="nonzero"></path>
            <text id="启动服务" font-family="NotoSansCJKsc-Black, Noto Sans CJK SC" font-size="18.2" font-weight="800" letter-spacing="0.200199999" fill="#020202" fill-opacity="0.88378138">
                <tspan x="1802.1996" y="347">启动服务</tspan>
            </text>
            <path id="直线-22" d="M1836.15,674.997059 L1836.15,685.964 L1840.75,685.964052 L1835.5,696.964052 L1830.25,685.964052 L1834.85,685.964 L1834.85,674.997059 L1836.15,674.997059 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-22备份" d="M1836.15,728.997059 L1836.15,739.964 L1840.75,739.964052 L1835.5,750.964052 L1830.25,739.964052 L1834.85,739.964 L1834.85,728.997059 L1836.15,728.997059 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-22备份-2" d="M1836.15,783.997059 L1836.15,794.964 L1840.75,794.964052 L1835.5,805.964052 L1830.25,794.964052 L1834.85,794.964 L1834.85,783.997059 L1836.15,783.997059 Z" fill="#979797" fill-rule="nonzero"></path>
            <g id="架构图/模块-源码备份-54" transform="translate(2075.000000, 542.000000)">
                <rect id="矩形" stroke="#979797" fill="#FFBBA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="39.6222753" y="14">IActivityManager#attachApplication</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="148.202627" y="30.122449">-</tspan>
                </text>
            </g>
            <path id="直线-27备份" d="M2224.15,460.988889 L2224.15,472.972 L2228.75,472.972222 L2223.5,483.972222 L2218.25,472.972222 L2222.85,472.972 L2222.85,460.988889 L2224.15,460.988889 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-28备份" d="M2224.15,517 L2224.15,531.961 L2228.75,531.961111 L2223.5,542.961111 L2218.25,531.961111 L2222.85,531.961 L2222.85,517 L2224.15,517 Z" fill="#979797" fill-rule="nonzero"></path>
            <g id="架构图/模块-源码备份-55" transform="translate(2075.000000, 655.000000)">
                <rect id="矩形" stroke="#979797" fill="#D5FFA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="19.2199992" y="14">ActivityManagerService#attachApplication</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="148.202627" y="30.122449">-</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-48" transform="translate(2040.000000, 711.000000)">
                <rect id="矩形" stroke="#979797" fill="#D5FFA2" x="0.5" y="0.5" width="368.7277" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="32.5625946" y="14">ActivityManagerService#attachApplicationLocked</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="77.2564856" y="30.122449">获取之前存储的 mPendingServices - 待启动的服务列表</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-36" transform="translate(2075.000000, 595.000000)">
                <rect id="矩形" stroke="#979797" fill="#FFED99" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="124.320049" y="14">transact</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="136.553756" y="30.122449">binder</tspan>
                </text>
            </g>
            <path id="直线-29备份" d="M2224.15,573.997059 L2224.15,584.964 L2228.75,584.964052 L2223.5,595.964052 L2218.25,584.964052 L2222.85,584.964 L2222.85,573.997059 L2224.15,573.997059 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-30备份" d="M2224.15,628.992857 L2224.15,644.968 L2228.75,644.968254 L2223.5,655.968254 L2218.25,644.968254 L2222.85,644.968 L2222.85,628.992857 L2224.15,628.992857 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-33" d="M1838.15,454.997059 L1838.15,465.964 L1842.75,465.964052 L1837.5,476.964052 L1832.25,465.964052 L1836.85,465.964 L1836.85,454.997059 L1838.15,454.997059 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-34" d="M2224.15,688.997059 L2224.15,699.964 L2228.75,699.964052 L2223.5,710.964052 L2218.25,699.964052 L2222.85,699.964 L2222.85,688.997059 L2224.15,688.997059 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-35" d="M1996.38889,444.25 L1985.38889,439 L1996.38889,433.75 L1996.388,438.35 L2024.46863,438.35 L2024.468,727.35 L2040.65,727.35 L2040.65,728.65 L2023.16863,728.65 L2023.168,439.65 L1996.388,439.65 L1996.38889,444.25 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-36" d="M2224.15,403 L2224.15,417.961 L2228.75,417.961111 L2223.5,428.961111 L2218.25,417.961111 L2222.85,417.961 L2222.85,403 L2224.15,403 Z" fill="#979797" fill-rule="nonzero"></path>
        </g>
    </g>
</svg>

#### ActiveServices#bringUpServiceLocked

```java
// com.android.server.am.ActiveServices#bringUpServiceLocked
// frameworks/base/services/core/java/com/android/server/am/ActiveServices.java
private String bringUpServiceLocked(ServiceRecord r, int intentFlags, boolean execInFg,
            boolean whileRestarting, boolean permissionsReviewRequired)
            throws TransactionTooLargeException {
        // 已经存在进程记录，并且进程记录中的IApplicationThread已经存在，则不创建服务，仅发送参数
        if (r.app != null && r.app.thread != null) {
            sendServiceArgsLocked(r, execInFg, false);
            return null;
        }
        final boolean isolated = (r.serviceInfo.flags&ServiceInfo.FLAG_ISOLATED_PROCESS) != 0;
        final String procName = r.processName;
        HostingRecord hostingRecord = new HostingRecord("service", r.instanceName);
        ProcessRecord app;
		// 非独立的进程，则直接获取当前启动进程的进程信息
        if (!isolated) {
            app = mAm.getProcessRecordLocked(procName, r.appInfo.uid, false);
             if (app != null && app.thread != null) {
                try {
                    app.addPackage(r.appInfo.packageName, r.appInfo.longVersionCode, mAm.mProcessStats);
                    // 非独立进程中，直接启动服务
                    realStartServiceLocked(r, app, execInFg);
                    // 调用启动方法后直接返回
                    return null;
                } catch (TransactionTooLargeException e) {
                    throw e;
                } catch (RemoteException e) {
                    Slog.w(TAG, "Exception when starting service " + r.shortInstanceName, e);
                }

                // If a dead object exception was thrown -- fall through to
                // restart the application.
            }
        } else {
            // 独立进程则先尝试使用之前保存的
            app = r.isolatedProc;
        }

        // 之前没有启动对应的进程，则开始创建，启动了，则无需进行赋值操作，因为ServiceRecord中已经有了
        if (app == null && !permissionsReviewRequired) {
            if ((app=mAm.startProcessLocked(procName, r.appInfo, true, intentFlags,
                    hostingRecord, ZYGOTE_POLICY_FLAG_EMPTY, false, isolated, false)) == null) {
                String msg = "Unable to launch app "
                        + r.appInfo.packageName + "/"
                        + r.appInfo.uid + " for service "
                        + r.intent.getIntent() + ": process is bad";
                Slog.w(TAG, msg);
                bringDownServiceLocked(r);
                // 进程启动失败，返回错误消息
                return msg;
            }
            if (isolated) {
                // 独立进程，缓存进程信息到传入的ServiceRecord参数中，以便后续直接使用
                r.isolatedProc = app;
            }
        }
        // 将服务记录加入的mPendingServices中，由于非独立进程创建后已经直接返回，所以这里适用于独立进程的
        if (!mPendingServices.contains(r)) {
            mPendingServices.add(r);
        }
	    // 创建成功或者之前已经又了缓存，则返回null
        return null;
    }
```

#### 独立进程何时启动服务？

* 一般来说，封装较好的代码会保证入口统一，如果非独立进程情况下服务的启动使用的是 `realStartServiceLocked` 方法来启动服务，那么独立进程情况下，服务的启动也应该使用此方法，所以我们查看 `realStartServiceLocked` 方法的调用层次，如下：

  **图片版本:**

  ![image-20210411112439961](https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20210411112440.png)

  **详细调用序列:**

  * `ActiveServices.attachApplicationLocked`(ProcessRecord, String)  (com.android.server.am)
    * ActivityManagerService.attachApplicationLocked(IApplicationThread, int, int, long)  (com.android.server.am)
      * ActivityManagerService.attachApplication(IApplicationThread, long)  (com.android.server.am)
  * `ActiveServices.bringUpServiceLocked`(ServiceRecord, int, boolean, boolean, boolean)  (com.android.server.am)
    * ActiveServices.startServiceInnerLocked(ServiceMap, Intent, ServiceRecord, boolean, boolean)  (com.android.server.am)
    * ActiveServices.bindServiceLocked(IApplicationThread, IBinder, Intent, String, IServiceConnection, int, String, ...)  (com.android.server.am)
    * ActiveServices.performServiceRestartLocked(ServiceRecord)  (com.android.server.am)

  也就是调用了 `ActiveServices.attachApplicationLocked` ,最终是通过AMS的`ActivityManagerService.attachApplication`来触发的;也就是只要找到`mAm.startProcessLocked`到`ActivityManagerService.attachApplication`的调用序列即可证明此猜想;

  我们可以找到如下调用序列，即最终实际上是从ActivityThread的main函数进入的，所以做出以下猜想：**进程启动后，创建ActivityThread时，如果有需要创建的服务，就启动服务；**

  <img src="https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20210411114715.png" alt="image-20210411114715216" style="zoom:50%;" />

  我们再看`attachApplicationLocked` 的逻辑，可以发现，会检查`mPendingServices`中是否有待启动的服务，然后逐一处理，如果有需要启动的服务，则会调用`realStartServiceLocked(sr, proc, sr.createdFromFg)`来启动服务。

  ```java
  // com.android.server.am.ActiveServices#attachApplicationLocked
  // frameworks/base/services/core/java/com/android/server/am/ActiveServices.java
  boolean attachApplicationLocked(ProcessRecord proc, String processName)
              throws RemoteException {
          boolean didSomething = false;
          // Collect any services that are waiting for this process to come up.
          if (mPendingServices.size() > 0) {
              ServiceRecord sr = null;
              try {
                  for (int i=0; i<mPendingServices.size(); i++) {
                      sr = mPendingServices.get(i);
                      // 排除非独立Service
                      if (proc != sr.isolatedProc && (proc.uid != sr.appInfo.uid
                              || !processName.equals(sr.processName))) {
                          continue;
                      }
  
                      mPendingServices.remove(i);
                      i--;
                      proc.addPackage(sr.appInfo.packageName, sr.appInfo.longVersionCode,
                              mAm.mProcessStats);
                      // 启动服务
                      realStartServiceLocked(sr, proc, sr.createdFromFg);
                  }
              } catch (RemoteException e) {
                  Slog.w(TAG, "Exception in new application when starting service "
                          + sr.shortInstanceName, e);
                  throw e;
              }
          }
  }
  ```

#### ActivityThread#handleCreateService

这里我们省略`bringUpServiceLocked`方法及下方的几个中间步骤，直接查看`android.app.ActivityThread#handleCreateService`方法：

1. 通过ClassLoader加载并实例化了对应的Service对象；
2. 将Service存储到ActivityThread中的一个ArrayMap中；

```java
// android/app/ActivityThread.java
// android.app.ActivityThread#handleCreateService

final ArrayMap<IBinder, Service> mServices = new ArrayMap<>();
private void handleCreateService(CreateServiceData data) {
        // If we are getting ready to gc after going to the background, well
        // we are back active so skip it.
        unscheduleGcIdler();

        LoadedApk packageInfo = getPackageInfoNoCheck(
                data.info.applicationInfo, data.compatInfo);
        Service service = null;
        try {
            if (localLOGV) Slog.v(TAG, "Creating service " + data.info.name);

            ContextImpl context = ContextImpl.createAppContext(this, packageInfo);
            Application app = packageInfo.makeApplication(false, mInstrumentation);
            java.lang.ClassLoader cl = packageInfo.getClassLoader();
            // 创建对应的Service实例
            service = packageInfo.getAppFactory()
                    .instantiateService(cl, data.info.name, data.intent);
            // Service resources must be initialized with the same loaders as the application
            // context.
            context.getResources().addLoaders(
                    app.getResources().getLoaders().toArray(new ResourcesLoader[0]));

            context.setOuterContext(service);
            service.attach(context, this, data.info.name, data.token, app,
                    ActivityManager.getService());
            service.onCreate();
            mServices.put(data.token, service);
            try {
                ActivityManager.getService().serviceDoneExecuting(
                        data.token, SERVICE_DONE_EXECUTING_ANON, 0, 0);
            } catch (RemoteException e) {
                throw e.rethrowFromSystemServer();
            }
        } catch (Exception e) {
            if (!mInstrumentation.onException(service, e)) {
                throw new RuntimeException(
                    "Unable to create service " + data.info.name
                    + ": " + e.toString(), e);
            }
        }
    }
```

### 绑定服务


<svg width="698px" height="447px" viewBox="0 0 698 447" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
    <g id="Android源码分析" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd">
        <g id="bindService流程分析-加入启动流程" transform="translate(-125.000000, -273.000000)">
            <g id="架构图/模块-源码备份-4" transform="translate(523.000000, 273.000000)">
                <rect id="矩形" stroke="#979797" fill="#D5FFA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="14.2367021" y="14">ActivityManagerService.bindIsolatedService</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="44.0851371" y="30.122449">com/android/server/am/ActivityManagerService.java</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-5" transform="translate(523.000000, 322.000000)">
                <rect id="矩形" stroke="#979797" fill="#D5FFA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="45.2025933" y="14">ActiveServices.bindServiceLocked</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="62.0131706" y="30.122449">com/android/server/am/ActiveServices.java</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-16" transform="translate(523.000000, 422.000000)">
                <rect id="矩形" stroke="#979797" fill="#D5FFA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="25.0439991" y="14">IApplicationThread.scheduleBindService</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="75.1632961" y="30.122449">android/app/IApplicationThread.java</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-17" transform="translate(523.000000, 482.000000)">
                <rect id="矩形" stroke="#979797" fill="#FFED99" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="102.802928" y="14">Binder.transact</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="136.553756" y="30.122449">binder</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-18" transform="translate(440.000000, 537.000000)">
                <rect id="矩形" stroke="#979797" fill="#FFED99" x="0.5" y="0.5" width="63.3004695" height="182" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="10.224946" y="14">Binder.</tspan>
                    <tspan x="6.77075357" y="32">transact</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="19.0044607" y="118.306122">binder</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-10" transform="translate(522.000000, 537.000000)">
                <rect id="矩形" stroke="#979797" fill="#FFBBA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="27.1213883" y="14">ApplicationThread.scheduleBindService</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="28.0238818" y="30.122449">frameworks/base/core/java/android/app/ActivityThread.java</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-12" transform="translate(522.000000, 587.000000)">
                <rect id="矩形" stroke="#979797" fill="#FFBBA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="43.344518" y="14">ActivityThread#handleBindService</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="28.0238818" y="30.122449">frameworks/base/core/java/android/app/ActivityThread.java</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-19" transform="translate(522.000000, 637.000000)">
                <rect id="矩形" stroke="#979797" fill="#FFBBA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="63.1680494" y="14">IBinder = Service.onBinder()</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="104.313756" y="30.122449">自定义的Service实现类</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-20" transform="translate(522.000000, 686.000000)">
                <rect id="矩形" stroke="#979797" fill="#FFBBA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="48.7055222" y="14">IActivityManager#publishService</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="80.4068108" y="30.122449">android/app/IActivityManager.java</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-21" transform="translate(125.000000, 537.000000)">
                <rect id="矩形" stroke="#979797" fill="#D5FFA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="28.303246" y="14">ActivityManagerService#publishService</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="80.4068108" y="30.122449">android/app/IActivityManager.java</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-23" transform="translate(125.000000, 587.000000)">
                <rect id="矩形" stroke="#979797" fill="#D5FFA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="34.5841498" y="14">ActiveServices#publishServiceLocked</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="62.0131706" y="30.122449">com/android/server/am/ActiveServices.java</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-51" transform="translate(125.000000, 638.000000)">
                <rect id="矩形" stroke="#979797" fill="#D5FFA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="54.5477983" y="14">IServiceConnection#connected</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="148.202627" y="30.122449">-</tspan>
                </text>
            </g>
            <g id="架构图/模块-源码备份-8" transform="translate(523.000000, 373.000000)">
                <rect id="矩形" stroke="#979797" fill="#D5FFA2" x="0.5" y="0.5" width="298.399061" height="33" rx="6.9623431"></rect>
                <text id="方法过程" font-family="NotoSansCJKsc-Bold, Noto Sans CJK SC" font-size="12.1841004" font-weight="bold" letter-spacing="0.134025104" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="12.0131038" y="14">ActiveServices.requestServiceBindingLocked</tspan>
                </text>
                <text id="代码地址" font-family="NotoSansCJKsc-Light, Noto Sans CJK SC" font-size="8.70292887" font-weight="300" letter-spacing="0.0957322235" fill="#151515" fill-opacity="0.88378138">
                    <tspan x="62.0131706" y="30.122449">com/android/server/am/ActiveServices.java</tspan>
                </text>
            </g>
            <path id="直线-5" d="M671.935146,307.012222 L671.935,315.997 L675.675732,315.997076 L671.5,323.997076 L667.324268,315.997076 L671.064,315.997 L671.064854,307.012222 L671.935146,307.012222 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-6" d="M671.935146,356.012222 L671.935,364.997 L675.675732,364.997076 L671.5,372.997076 L667.324268,364.997076 L671.064,364.997 L671.064854,356.012222 L671.935146,356.012222 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-7" d="M671.935146,405.012222 L671.935,413.997 L675.675732,413.997076 L671.5,421.997076 L667.324268,413.997076 L671.064,413.997 L671.064854,405.012222 L671.935146,405.012222 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-8" d="M671.935146,454.998187 L671.935,473.011 L675.675732,473.011111 L671.5,481.011111 L667.324268,473.011111 L671.064,473.011 L671.064854,454.998187 L671.935146,454.998187 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-9" d="M671.935146,514.990779 L671.935,530.018 L675.675732,530.018519 L671.5,538.018519 L667.324268,530.018519 L671.064,530.018 L671.064854,514.990779 L671.935146,514.990779 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-10" d="M671.935146,571.012222 L671.935,579.997 L675.675732,579.997076 L671.5,587.997076 L667.324268,579.997076 L671.064,579.997 L671.064854,571.012222 L671.935146,571.012222 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-18" d="M671.935146,621.012222 L671.935,629.997 L675.675732,629.997076 L671.5,637.997076 L667.324268,629.997076 L671.064,629.997 L671.064854,621.012222 L671.935146,621.012222 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-11" d="M671.935146,671.012222 L671.935,679.997 L675.675732,679.997076 L671.5,687.997076 L667.324268,679.997076 L671.064,679.997 L671.064854,671.012222 L671.935146,671.012222 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-19" d="M511.984127,699.324268 L511.984,703.064 L522.006575,703.064854 L522.006575,703.935146 L511.984,703.935 L511.984127,707.675732 L503.984127,703.5 L511.984127,699.324268 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-20" d="M431.980556,550.324268 L431.98,554.064 L441.010146,554.064854 L441.010146,554.935146 L431.98,554.935 L431.980556,558.675732 L423.980556,554.5 L431.980556,550.324268 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-12" d="M272.935146,571.012222 L272.935,579.997 L276.675732,579.997076 L272.5,587.997076 L268.324268,579.997076 L272.064,579.997 L272.064854,571.012222 L272.935146,571.012222 Z" fill="#979797" fill-rule="nonzero"></path>
            <path id="直线-12备份" d="M272.935146,621.012222 L272.935,629.997 L276.675732,629.997076 L272.5,637.997076 L268.324268,629.997076 L272.064,629.997 L272.064854,621.012222 L272.935146,621.012222 Z" fill="#979797" fill-rule="nonzero"></path>
        </g>
    </g>
</svg>

我们的问题是：

1. 绑定服务时，传入的ServiceConnection对象，如何被调用来通知？
2. 还做了些什么？

#### 连接对象去哪里了？

查看`ContextImpl.bindServiceCommon`方法可以看到，传入了参数 `ServiceConnection conn`，然后方法中这个conn放入到了一个 `ServiceDispatcher` 中.

* IServiceConnection 包含两个接口：
  * connected(): 连接到服务
  * asBinder()： 服务转Binder
* 这里会将我们自行编写的ServiceConnection对象构造出一个ServiceDispatcher对象，然后将ServiceDispatcher提供一个IServiceconnection接口（`ServiceDispatcher$InnerConnection`类），用于提供服务；
* 这个`ServiceDispatcher$InnerConnection`类的connect方法会调用sd的connect方法，最终会调用我们提供的ServiceConnection的回调方法：`mConnection.onServiceConnected(name, service)`

也就是说，使用`sd.connect()`就可以触发我们的连接对象的`onServiceConnected`回调方法；

```java
final @NonNull LoadedApk mPackageInfo;

private boolean bindServiceCommon(Intent service, ServiceConnection conn, int flags,
            String instanceName, Handler handler, Executor executor, UserHandle user) {
        // Keep this in sync with DevicePolicyManager.bindDeviceAdminServiceAsUser.
	    // 这个IServiceConnection 实际上就是持有ServiceDispatcher的弱引用对象，然后将ServiceDispatcher的少量方法暴露出去
        IServiceConnection sd;
        if (mPackageInfo != null) {
            if (executor != null) {
                // mPackageInfo 是一个 LoadedApk 对象
                sd = mPackageInfo.getServiceDispatcher(conn, getOuterContext(), executor, flags);
            } else {
                sd = mPackageInfo.getServiceDispatcher(conn, getOuterContext(), handler, flags);
            }
        } else {
            
        }
    	int res = ActivityManager.getService().bindIsolatedService(
                mMainThread.getApplicationThread(), getActivityToken(), service,
                service.resolveTypeIfNeeded(getContentResolver()),
	            // 调用AMS的服务式这里传入了sd
                sd, flags, instanceName, getOpPackageName(), user.getIdentifier());
        //... 
    }

// com.android.server.am.ActiveServices#bindServiceLocked
AppBindRecord b = s.retrieveAppBindingLocked(service, callerApp);
            ConnectionRecord c = new ConnectionRecord(b, activity,
                    connection, flags, clientLabel, clientIntent,
                    callerApp.uid, callerApp.processName, callingPackage);
            // 提供 IBinder 
            IBinder binder = connection.asBinder();
            s.addConnection(binder, c);
            b.connections.add(c);
```

ServiceDispatcher类位于 `android.app.LoadedApk.ServiceDispatcher`：

```java
// frameworks/base/core/java/android/app/LoadedApk.java
	public final IServiceConnection getServiceDispatcher(ServiceConnection c,
            Context context, Executor executor, int flags) {
        return getServiceDispatcherCommon(c, context, null, executor, flags);
    }

    private IServiceConnection getServiceDispatcherCommon(ServiceConnection c,
            Context context, Handler handler, Executor executor, int flags) {
        synchronized (mServices) {
            LoadedApk.ServiceDispatcher sd = null;
            ArrayMap<ServiceConnection, LoadedApk.ServiceDispatcher> map = mServices.get(context);
            if (map != null) {
                if (DEBUG) Slog.d(TAG, "Returning existing dispatcher " + sd + " for conn " + c);
                sd = map.get(c);
            }
            if (sd == null) {
                if (executor != null) {
                    sd = new ServiceDispatcher(c, context, executor, flags);
                } else {
                    sd = new ServiceDispatcher(c, context, handler, flags);
                }
                if (DEBUG) Slog.d(TAG, "Creating new dispatcher " + sd + " for conn " + c);
                if (map == null) {
                    map = new ArrayMap<>();
                    mServices.put(context, map);
                }
                map.put(c, sd);
            } else {
                sd.validate(context, handler, executor);
            }
            return sd.getIServiceConnection();
        }
    }


static final class ServiceDispatcher {
    private final ServiceDispatcher.InnerConnection mIServiceConnection;
    @UnsupportedAppUsage
    private final ServiceConnection mConnection;
    @UnsupportedAppUsage(maxTargetSdk = Build.VERSION_CODES.P, trackingBug = 115609023)
    private final Context mContext;
    private final Handler mActivityThread;
    private final Executor mActivityExecutor;
    private final ServiceConnectionLeaked mLocation;
    private final int mFlags;

    private static class InnerConnection extends IServiceConnection.Stub {
        @UnsupportedAppUsage
        final WeakReference<LoadedApk.ServiceDispatcher> mDispatcher;

        InnerConnection(LoadedApk.ServiceDispatcher sd) {
            mDispatcher = new WeakReference<LoadedApk.ServiceDispatcher>(sd);
        }

        public void connected(ComponentName name, IBinder service, boolean dead)
                throws RemoteException {
            LoadedApk.ServiceDispatcher sd = mDispatcher.get();
            if (sd != null) {
                sd.connected(name, service, dead);
            }
        }
    }

    @UnsupportedAppUsage
    ServiceDispatcher(ServiceConnection conn,
                      Context context, Handler activityThread, int flags) {
        mIServiceConnection = new InnerConnection(this);
        mConnection = conn;
        mContext = context;
        mActivityThread = activityThread;
        mActivityExecutor = null;
        mLocation = new ServiceConnectionLeaked(null);
        mLocation.fillInStackTrace();
        mFlags = flags;
    }

    ServiceConnection getServiceConnection() {
        return mConnection;
    }

    // SD中提供了connected方法
    public void connected(ComponentName name, IBinder service, boolean dead) {
        if (mActivityExecutor != null) {
            mActivityExecutor.execute(new RunConnection(name, service, 0, dead));
        } else if (mActivityThread != null) {
            mActivityThread.post(new RunConnection(name, service, 0, dead));
        } else {
            doConnected(name, service, dead);
        }
    }

    public void doConnected(ComponentName name, IBinder service, boolean dead) {
        ServiceDispatcher.ConnectionInfo old;
        ServiceDispatcher.ConnectionInfo info;

        synchronized (this) {
            if (mForgotten) {
                // We unbound before receiving the connection; ignore
                // any connection received.
                return;
            }
            old = mActiveConnections.get(name);
            if (old != null && old.binder == service) {
                // Huh, already have this one.  Oh well!
                return;
            }

            if (service != null) {
                // A new service is being connected... set it all up.
                info = new ConnectionInfo();
                info.binder = service;
                info.deathMonitor = new DeathMonitor(name, service);
                try {
                    service.linkToDeath(info.deathMonitor, 0);
                    mActiveConnections.put(name, info);
                } catch (RemoteException e) {
                    // This service was dead before we got it...  just
                    // don't do anything with it.
                    mActiveConnections.remove(name);
                    return;
                }

            } else {
                // The named service is being disconnected... clean up.
                mActiveConnections.remove(name);
            }

            if (old != null) {
                old.binder.unlinkToDeath(old.deathMonitor, 0);
            }
        }

        // If there was an old service, it is now disconnected.
        if (old != null) {
            mConnection.onServiceDisconnected(name);
        }
        if (dead) {
            mConnection.onBindingDied(name);
        }
        // If there is a new viable service, it is now connected.
        if (service != null) {
            mConnection.onServiceConnected(name, service);
        } else {
            // The binding machinery worked, but the remote returned null from onBind().
            mConnection.onNullBinding(name);
        }
    }

}
```

#### IServiceConnection说明

>  服务绑定时，IServiceConnection的用途？如何实现在APP的Activity进程中调用ServiceConnection的onServiceConnected方法？

* IServiceConnect的服务端位于APP进程中，在ContextImpl的binderServiceCommon方法中初始化，也就是LoadApk类中的ServiceDispatcher类。
* 传递给AMS的实际上是一个Binder的远程代理对象；

```java
// android.app.IActivityManager.Stub#TRANSACTION_bindService
// android/app/IActivityManager.java
case TRANSACTION_bindService:
{
          data.enforceInterface(descriptor);
          android.app.IApplicationThread _arg0;
          _arg0 = android.app.IApplicationThread.Stub.asInterface(data.readStrongBinder());
          android.os.IBinder _arg1;
          _arg1 = data.readStrongBinder();
          android.content.Intent _arg2;
          if ((0!=data.readInt())) {
            _arg2 = android.content.Intent.CREATOR.createFromParcel(data);
          }
          else {
            _arg2 = null;
          }
          java.lang.String _arg3;
          _arg3 = data.readString();
          android.app.IServiceConnection _arg4;
    // 这里可以看到，是在这个地方见IServiceConnection的服务端对象转换成客户端代理对象的
          _arg4 = android.app.IServiceConnection.Stub.asInterface(data.readStrongBinder());
          int _arg5;
          _arg5 = data.readInt();
          java.lang.String _arg6;
          _arg6 = data.readString();
          int _arg7;
          _arg7 = data.readInt();
          int _result = this.bindService(_arg0, _arg1, _arg2, _arg3, _arg4, _arg5, _arg6, _arg7);
          reply.writeNoException();
          reply.writeInt(_result);
          return true;
}
    
```

asInterface 中： `new android.app.IServiceConnection.Stub.Proxy(obj)` 即是将Stub转换为Proxy对象；

```java
  /** Local-side IPC implementation stub class. */
  public static abstract class Stub extends android.os.Binder implements android.app.IServiceConnection
  {
    private static final java.lang.String DESCRIPTOR = "android.app.IServiceConnection";
    /** Construct the stub at attach it to the interface. */
    public Stub()
    {
      this.attachInterface(this, DESCRIPTOR);
    }
    /**
     * Cast an IBinder object into an android.app.IServiceConnection interface,
     * generating a proxy if needed.
     */
    public static android.app.IServiceConnection asInterface(android.os.IBinder obj)
    {
      if ((obj==null)) {
        return null;
      }
      android.os.IInterface iin = obj.queryLocalInterface(DESCRIPTOR);
      if (((iin!=null)&&(iin instanceof android.app.IServiceConnection))) {
        return ((android.app.IServiceConnection)iin);
      }
      return new android.app.IServiceConnection.Stub.Proxy(obj);
    }
  }
```

也就是说，ActivityManagerService.bindService方法中的IServiceConnection参数实际上是一个Proxy对象；

```java
// 这里的Connection是一个代理对象
public int bindService(IApplicationThread caller, IBinder token, Intent service,
            String resolvedType, IServiceConnection connection, int flags,
            String callingPackage, int userId) throws TransactionTooLargeException {
        return bindIsolatedService(caller, token, service, resolvedType, connection, flags,
                null, callingPackage, userId);
}
```

#### ActivityThread#handleBindService

实际上就做了两件事情

```java
// android.app.ActivityThread#handleBindService
// frameworks/base/core/java/android/app/ActivityThread.java
private void handleBindService(BindServiceData data) {
        // 获取之前创建的服务
        Service s = mServices.get(data.token);
        if (s != null) { // 找不到之前创建的服务，则什么都不做
            try {
                data.intent.setExtrasClassLoader(s.getClassLoader());
                data.intent.prepareToEnterProcess();
                try {
                    if (!data.rebind) {
                        // 调用Service的onBind接口获取IBinder对象
                        IBinder binder = s.onBind(data.intent);
                        // 通知AMS来publicService
                        ActivityManager.getService().publishService(
                                data.token, data.intent, binder);
                    } else {
                        s.onRebind(data.intent);
                        ActivityManager.getService().serviceDoneExecuting(
                                data.token, SERVICE_DONE_EXECUTING_ANON, 0, 0);
                    }
                } catch (RemoteException ex) {
                    throw ex.rethrowFromSystemServer();
                }
            } catch (Exception e) {
            }
        }
    }
```

#### ActivityManagerService#publishService

```java
// com.android.server.am.ActivityManagerService#publishService
// frameworks/base/services/core/java/com/android/server/am/ActivityManagerService.java
public void publishService(IBinder token, Intent intent, IBinder service) {
        // Refuse possible leaked file descriptors
        if (intent != null && intent.hasFileDescriptors() == true) {
            throw new IllegalArgumentException("File descriptors passed in Intent");
        }

        synchronized(this) {
            if (!(token instanceof ServiceRecord)) {
                throw new IllegalArgumentException("Invalid service token");
            }
            // com.android.server.am.ActiveServices#publishServiceLocked
            mServices.publishServiceLocked((ServiceRecord)token, intent, service);
        }
    }
```

#### ActiveServices#publishServiceLocked

下面我们可以看到，在publishServiceLocked方法中，取出了一个连接记录列表，然后循环的调用了其中的IServiceConnection的connected方法，也就是会调用到我们自行定义的ServiceConnnection对象的connected方法。

不过我们有个问题，就是这个ConnectionRecord对象是何时构造的？

```java
// com.android.server.am.ConnectionRecord
// frameworks/base/services/core/java/com/android/server/am/ConnectionRecord.java
final class ConnectionRecord {
    final AppBindRecord binding;    // The application/service binding.
    final ActivityServiceConnectionsHolder<ConnectionRecord> activity;  // If non-null, the owning activity.
    final IServiceConnection conn;  // The client connection.
}

// com.android.server.am.ActiveServices#publishServiceLocked
// frameworks/base/services/core/java/com/android/server/am/ActiveServices.java
void publishServiceLocked(ServiceRecord r, Intent intent, IBinder service) {
        final long origId = Binder.clearCallingIdentity();
        try {
            // 如果服务记录为null，就什么都不做
            if (r != null) {
                Intent.FilterComparison filter
                        = new Intent.FilterComparison(intent);
                IntentBindRecord b = r.bindings.get(filter);
                if (b != null && !b.received) {
                    b.binder = service;
                    b.requested = true;
                    b.received = true;
                    // 取出连接记录ConnectionRecord
                    ArrayMap<IBinder, ArrayList<ConnectionRecord>> connections = r.getConnections();
                    for (int conni = connections.size() - 1; conni >= 0; conni--) {
                        ArrayList<ConnectionRecord> clist = connections.valueAt(conni);
                        for (int i = 0; i < clist.size(); i++) {
                            ConnectionRecord c = clist.get(i);
                            try {
                                // 调用IServiceConnection的connected方法
                                c.conn.connected(r.name, service, false);
                            } catch (Exception e) {
                               
                            }
                        }
                    }
                }
                serviceDoneExecutingLocked(r, mDestroyingServices.contains(r), false);
            }
        } finally {
        }
    }

```

#### 构造 ConnectionRecord - bindServiceLocked

实际上这个构建ConnectRecord的过程位于bindServiceLocked方法中。

```java
int bindServiceLocked(IApplicationThread caller, IBinder token, Intent service,
                          String resolvedType, final IServiceConnection connection, int flags,
                          String instanceName, String callingPackage, final int userId)
            throws TransactionTooLargeException {
        final int callingPid = Binder.getCallingPid();
        final int callingUid = Binder.getCallingUid();

        ActivityServiceConnectionsHolder<ConnectionRecord> activity = null;
        if (token != null) {
            activity = mAm.mAtmInternal.getServiceConnectionsHolder(token);
            if (activity == null) {
                Slog.w(TAG, "Binding with unknown activity: " + token);
                return 0;
            }
        }
        ServiceLookupResult res = retrieveServiceLocked(service, instanceName, resolvedType, callingPackage,
                        callingPid, callingUid, userId, true,
                        callerFg, isBindExternal, allowInstant);
        ServiceRecord s = res.record;
        try {
            AppBindRecord b = s.retrieveAppBindingLocked(service, callerApp);
            // 构造连接记录对象
            ConnectionRecord c = new ConnectionRecord(b, activity,
                    connection, flags, clientLabel, clientIntent,
                    callerApp.uid, callerApp.processName, callingPackage);

            IBinder binder = connection.asBinder();
            // 添加到ServiceRecord对象中
            s.addConnection(binder, c);
            b.connections.add(c);
            if (activity != null) {
                activity.addConnection(c);
            }
            b.client.connections.add(c);
            c.startAssociationIfNeeded();
        } finally {
        }
        return 1;
    }
```



## 部分方法的源码

### ContextImpl.`bindService`

* `bindService` : (`frameworks/base/core/java/android/app/ContextImpl.java`)

  ```java
      @Override
      public boolean bindService(Intent service, ServiceConnection conn, int flags) {
          warnIfCallingFromSystemProcess();
          return bindServiceCommon(service, conn, flags, null, mMainThread.getHandler(), null,
                  getUser());
      }
  
      @Override
      public boolean bindService(
              Intent service, int flags, Executor executor, ServiceConnection conn) {
          warnIfCallingFromSystemProcess();
          return bindServiceCommon(service, conn, flags, null, null, executor, getUser());
      }
  
  ```

### ContextImpl.bindServiceCommon

* `bindServiceCommon`:  (`frameworks/base/core/java/android/app/ContextImpl.java`)

  ```java
  private boolean bindServiceCommon(Intent service, ServiceConnection conn, int flags,
              String instanceName, Handler handler, Executor executor, UserHandle user) {
          // Keep this in sync with DevicePolicyManager.bindDeviceAdminServiceAsUser.
          IServiceConnection sd;
          if (conn == null) {
              throw new IllegalArgumentException("connection is null");
          }
          if (handler != null && executor != null) {
              throw new IllegalArgumentException("Handler and Executor both supplied");
          }
          if (mPackageInfo != null) {
              if (executor != null) {
                  sd = mPackageInfo.getServiceDispatcher(conn, getOuterContext(), executor, flags);
              } else {
                  sd = mPackageInfo.getServiceDispatcher(conn, getOuterContext(), handler, flags);
              }
          } else {
              throw new RuntimeException("Not supported in system context");
          }
          validateServiceIntent(service);
          try {
              // WindowContext构造函数中的 WindowTokenClient
              IBinder token = getActivityToken();
              if (token == null && (flags&BIND_AUTO_CREATE) == 0 && mPackageInfo != null
                      && mPackageInfo.getApplicationInfo().targetSdkVersion
                      < android.os.Build.VERSION_CODES.ICE_CREAM_SANDWICH) {
                  flags |= BIND_WAIVE_PRIORITY;
              }
              service.prepareToLeaveProcess(this);
              int res = ActivityManager.getService().bindIsolatedService(
                  mMainThread.getApplicationThread(), getActivityToken(), service,
                  service.resolveTypeIfNeeded(getContentResolver()),
                  sd, flags, instanceName, getOpPackageName(), user.getIdentifier());
              if (res < 0) {
                  throw new SecurityException(
                          "Not allowed to bind to service " + service);
              }
              return res != 0;
          } catch (RemoteException e) {
              throw e.rethrowFromSystemServer();
          }
      }
  ```

### ActivityManagerService.bindIsolatedService

从这里开始，实际上位于AMS的Server端了，即我们的Activity所在的进程发送了一个启动服务的IPC请求给AMS（sysmte_server进程中）。

* ActivityManagerService.java : (frameworks/base/services/core/java/com/android/server/am/ActivityManagerService.java)

  ```java
  public int bindIsolatedService(IApplicationThread caller, IBinder token, Intent service,
              String resolvedType, IServiceConnection connection, int flags, String instanceName,
              String callingPackage, int userId) throws TransactionTooLargeException {
  		// .... 
          synchronized(this) {
              // 调用Binder接口
              return mServices.bindServiceLocked(caller, token, service,
                      resolvedType, connection, flags, instanceName, callingPackage, userId);
          }
      }
  ```

![image-20210409144356311](https://gitee.com/hanlyjiang/image-repo/raw/master/imgs/20210409144356.png)

### ActiveServices.bindServiceLocked

*  `ActiveServices.bindServiceLocked`: (`frameworks/base/services/core/java/com/android/server/am/ActiveServices.java`)

  * 这个方法有点长，我们截取重要部分

  ```java
  int bindServiceLocked(IApplicationThread caller, IBinder token, Intent service,
              String resolvedType, final IServiceConnection connection, int flags,
              String instanceName, String callingPackage, final int userId)
              throws TransactionTooLargeException {
      // 获取调用方的权限
          final int callingPid = Binder.getCallingPid();
          final int callingUid = Binder.getCallingUid();
          final ProcessRecord callerApp = mAm.getRecordForAppLocked(caller);
          if (callerApp == null) {
              throw new SecurityException(
                      "Unable to find app for caller " + caller
                      + " (pid=" + callingPid
                      + ") when binding service " + service);
          }
  
          ActivityServiceConnectionsHolder<ConnectionRecord> activity = null;
          if (token != null) {
              activity = mAm.mAtmInternal.getServiceConnectionsHolder(token);
              if (activity == null) {
                  Slog.w(TAG, "Binding with unknown activity: " + token);
                  return 0;
              }
          }
  
          int clientLabel = 0;
          PendingIntent clientIntent = null;
          final boolean isCallerSystem = callerApp.info.uid == Process.SYSTEM_UID;
         
  
          final boolean callerFg = callerApp.setSchedGroup != ProcessList.SCHED_GROUP_BACKGROUND;
          final boolean isBindExternal = (flags & Context.BIND_EXTERNAL_SERVICE) != 0;
          final boolean allowInstant = (flags & Context.BIND_ALLOW_INSTANT) != 0;
  
          ServiceLookupResult res =
              retrieveServiceLocked(service, instanceName, resolvedType, callingPackage,
                      callingPid, callingUid, userId, true,
                      callerFg, isBindExternal, allowInstant);
          if (res == null) {
              return 0;
          }
          if (res.record == null) {
              return -1;
          }
          ServiceRecord s = res.record;
  
          try {
              if (unscheduleServiceRestartLocked(s, callerApp.info.uid, false)) {
                  if (DEBUG_SERVICE) Slog.v(TAG_SERVICE, "BIND SERVICE WHILE RESTART PENDING: "
                          + s);
              }
  
              if ((flags&Context.BIND_AUTO_CREATE) != 0) {
                  s.lastActivity = SystemClock.uptimeMillis();
                  if (!s.hasAutoCreateConnections()) {
                      // This is the first binding, let the tracker know.
                      ServiceState stracker = s.getTracker();
                      if (stracker != null) {
                          stracker.setBound(true, mAm.mProcessStats.getMemFactorLocked(),
                                  s.lastActivity);
                      }
                  }
              }
  
              if ((flags & Context.BIND_RESTRICT_ASSOCIATIONS) != 0) {
                  mAm.requireAllowedAssociationsLocked(s.appInfo.packageName);
              }
  
              mAm.startAssociationLocked(callerApp.uid, callerApp.processName,
                      callerApp.getCurProcState(), s.appInfo.uid, s.appInfo.longVersionCode,
                      s.instanceName, s.processName);
              // Once the apps have become associated, if one of them is caller is ephemeral
              // the target app should now be able to see the calling app
              mAm.grantImplicitAccess(callerApp.userId, service,
                      callerApp.uid, UserHandle.getAppId(s.appInfo.uid));
  
              AppBindRecord b = s.retrieveAppBindingLocked(service, callerApp);
              ConnectionRecord c = new ConnectionRecord(b, activity,
                      connection, flags, clientLabel, clientIntent,
                      callerApp.uid, callerApp.processName, callingPackage);
  
              IBinder binder = connection.asBinder();
              s.addConnection(binder, c);
              b.connections.add(c);
              if (activity != null) {
                  activity.addConnection(c);
              }
              b.client.connections.add(c);
              if (s.app != null) {
                  updateServiceClientActivitiesLocked(s.app, c, true);
              }
              ArrayList<ConnectionRecord> clist = mServiceConnections.get(binder);
              if (clist == null) {
                  clist = new ArrayList<>();
                  mServiceConnections.put(binder, clist);
              }
              clist.add(c);
  
              if ((flags&Context.BIND_AUTO_CREATE) != 0) {
                  s.lastActivity = SystemClock.uptimeMillis();
                  if (bringUpServiceLocked(s, service.getFlags(), callerFg, false,
                          permissionsReviewRequired) != null) {
                      return 0;
                  }
              }
  
              if (s.app != null && b.intent.received) {
                  // Service is already running, so we can immediately
                  // publish the connection.
                  try {
                      c.conn.connected(s.name, b.intent.binder, false);
                  } catch (Exception e) {
                      Slog.w(TAG, "Failure sending service " + s.shortInstanceName
                              + " to connection " + c.conn.asBinder()
                              + " (in " + c.binding.client.processName + ")", e);
                  }
              } else if (!b.intent.requested) {
                  requestServiceBindingLocked(s, b.intent, callerFg, false);
              }
          } finally {
          }
          return 1;
      }
  ```
  
  ### ActiveServices.realStartServiceLocked
```java
 /**
     * Note the name of this method should not be confused with the started services concept.
     * The "start" here means bring up the instance in the client, and this method is called
     * from bindService() as well.
     */
    private final void realStartServiceLocked(ServiceRecord r,
            ProcessRecord app, boolean execInFg) throws RemoteException {
        if (app.thread == null) {
            throw new RemoteException();
        }
        r.setProcess(app);
        r.restartTime = r.lastActivity = SystemClock.uptimeMillis();
		// 创建服务
        final boolean newService = app.startService(r);
        bumpServiceExecutingLocked(r, execInFg, "create");
        mAm.updateLruProcessLocked(app, false, null);
        updateServiceForegroundLocked(r.app, /* oomAdj= */ false);
        mAm.updateOomAdjLocked(app, OomAdjuster.OOM_ADJ_REASON_START_SERVICE);

        boolean created = false;
        try {
            app.forceProcessStateUpTo(ActivityManager.PROCESS_STATE_SERVICE);
            // 创建服务
            app.thread.scheduleCreateService(r, r.serviceInfo,
                    mAm.compatibilityInfoForPackage(r.serviceInfo.applicationInfo),
                    app.getReportedProcState());
            r.postNotification();
            created = true;
        } catch (DeadObjectException e) {
            Slog.w(TAG, "Application dead when creating service " + r);
            mAm.appDiedLocked(app, "Died when creating service");
            throw e;
        } finally {
            // 
        }

        // 绑定服务
        requestServiceBindingsLocked(r, execInFg);

        updateServiceClientActivitiesLocked(app, null, true);

        if (newService && created) {
            app.addBoundClientUidsOfNewService(r);
        }

        // If the service is in the started state, and there are no
        // pending arguments, then fake up one so its onStartCommand() will
        // be called.
        if (r.startRequested && r.callStart && r.pendingStarts.size() == 0) {
            r.pendingStarts.add(new ServiceRecord.StartItem(r, false, r.makeNextStartId(),
                    null, null, 0));
        }
        sendServiceArgsLocked(r, execInFg, true);
    }
```

