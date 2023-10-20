# JavaScript学习笔记

## 组成

* ES
* DOM
* BOM

## 事件

### touch事件

```js
for (let eKey in e.touches[0]) {
    console.log( eKey + "=" + e.touches[0][eKey]);
}

target=[object HTMLDivElement]
VM290:2 screenX=1527.4012451171875
VM290:2 screenY=379.3050537109375
VM290:2 clientX=235.4012451171875
VM290:2 clientY=202.3050537109375
VM290:2 pageX=235.4012451171875
VM290:2 pageY=202.3050537109375
VM290:2 radiusX=11.5
VM290:2 radiusY=11.5
VM290:2 rotationAngle=0
VM290:2 force=1
```

