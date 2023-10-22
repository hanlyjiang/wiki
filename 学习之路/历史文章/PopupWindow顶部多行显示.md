---
title: ' PopupWindow 顶部多行显示'
date: 2022-04-16 22:57:53
tags: []
published: true
hideInList: true
feature: 
isTop: false
---


这里我们以解决 PopupWindow 显示的一个问题作为目标来进行分析。

<!-- more -->


## 问题描述

### 想要的效果

在控件上方显示，可能是单行，也可能是多行。

<img src="https://s2.loli.net/2022/04/16/iE2q13rHFBwXWph.png" alt="image-20220416163306855" style="zoom: 33%;" />

### 实现方式

使用 `showAsDropdown` 时，可通过 yOffset 参数指定Y轴方向上的偏移量：

`偏移量 = anchorView.height + popupWindow.height`

<img src="https://s2.loli.net/2022/04/16/xaRPLy16hOUFMtN.png" alt="image-20220416200612183" style="zoom: 33%;" />

对于第 2 种单行的弹出框来说，实现起来比较简单:

```kotlin
class RawPopupWindowActivity : DemoButtonsActivity() {

    private var popupWindow: PopupWindow? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        addButton("单行Popup") { v -> showPopup(v, Constants.TEXT_SHORT) }
        addButton("多行Popup") { v -> showPopup(v, Constants.TEXT_MEDIUM) }
        addButton("多行Popup") { v -> showPopup(v, Constants.TEXT_LONG) }
    }

    private fun showPopup(anchorView: View, content: String) {
        popupWindow?.run {
            dismiss()
        }
        popupWindow = PopupWindow(applicationContext).apply {
            isOutsideTouchable = true
            PopupHelper(applicationContext).run {
                contentView = binding.root
                setText(content)
            }
            width = WindowManager.LayoutParams.WRAP_CONTENT
            height = WindowManager.LayoutParams.WRAP_CONTENT
            setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
          	// 测量高度
            contentView.measure(
                View.MeasureSpec.makeMeasureSpec(width, View.MeasureSpec.UNSPECIFIED),
                View.MeasureSpec.makeMeasureSpec(height, View.MeasureSpec.UNSPECIFIED)
            )
          	// 显示时向上移动 anchorView.height + contentView.measuredHeight 
            showAsDropDown(anchorView, 0, -(anchorView.height + contentView.measuredHeight))
        }
    }
}
```

### 实现效果及问题

最终效果如下：

<img src="https://s2.loli.net/2022/04/16/luUrbkHNxejKPva.png" alt="image-20220416181037662" style="zoom:50%;" />

可以看到垂直方向上：

- 单行的没有偏移
- 两行的有些许偏移
- 多行的偏移就非常大了

这是因为我们测量的时候并不是按照PopupWindow本身的测量方式进行测量的，所以height的值不匹配真实高度。

## Window添加过程

### showAsDropDown

```java
// android/widget/PopupWindow.java    
public void showAsDropDown(View anchor, int xoff, int yoff) {
    showAsDropDown(anchor, xoff, yoff, DEFAULT_ANCHORED_GRAVITY);
}

public void showAsDropDown(View anchor, int xoff, int yoff, int gravity) {
        if (isShowing() || !hasContentView()) {
            return;
        }
				// 关闭 mDecorView 上的动画
        TransitionManager.endTransitions(mDecorView);
				// 建下方
        attachToAnchor(anchor, xoff, yoff, gravity);

        mIsShowing = true;
        mIsDropdown = true;
				// 根据传递进来的参数，设置布局参数
        final WindowManager.LayoutParams p =
                createPopupLayoutParams(anchor.getApplicationWindowToken());
  			// 创建 DecorView BackgroundView ContentView 几个层次的包装
        preparePopup(p);

        final boolean aboveAnchor = findDropDownPosition(anchor, p, xoff, yoff,
                p.width, p.height, gravity, mAllowScrollingAnchorParent);
        updateAboveAnchor(aboveAnchor);
        p.accessibilityIdOfAnchor = (anchor != null) ? anchor.getAccessibilityViewId() : -1;

        invokePopup(p);
    }
```

### attachToAnchor

```java
    protected void attachToAnchor(View anchor, int xoff, int yoff, int gravity) {
        detachFromAnchor();

        final ViewTreeObserver vto = anchor.getViewTreeObserver();
        if (vto != null) {
            vto.addOnScrollChangedListener(mOnScrollChangedListener);
        }
        // View被添加到Window或者从Window上分离时的监听
        anchor.addOnAttachStateChangeListener(mOnAnchorDetachedListener);

        final View anchorRoot = anchor.getRootView();
        anchorRoot.addOnAttachStateChangeListener(mOnAnchorRootDetachedListener);
      	// 因为布局变化导致View的边界变化时的监听
        anchorRoot.addOnLayoutChangeListener(mOnLayoutChangeListener);
				// 存储 锚View 的一些信息
        mAnchor = new WeakReference<>(anchor);
        mAnchorRoot = new WeakReference<>(anchorRoot);
        mIsAnchorRootAttached = anchorRoot.isAttachedToWindow();
        mParentRootView = mAnchorRoot;

        mAnchorXoff = xoff;
        mAnchorYoff = yoff;
        mAnchoredGravity = gravity;
    }
```

从这里得到如下信息：

- `mAnchor`： 锚View （弱引用）
- `mAnchorRoot`： 锚View的顶层View (弱引用)
- `mParentRootView` ： mAnchorRoot （强引用）

### createPopupLayoutParams

就是 LayoutParams 设置

```java
protected final WindowManager.LayoutParams createPopupLayoutParams(IBinder token) {
        final WindowManager.LayoutParams p = new WindowManager.LayoutParams();
        p.gravity = computeGravity();
        p.flags = computeFlags(p.flags);
        p.type = mWindowLayoutType;
        p.token = token;
        p.softInputMode = mSoftInputMode;
        p.windowAnimations = computeAnimationResource();
				// 设置了背景时，从背景Drawable取像素格式
        if (mBackground != null) {
            p.format = mBackground.getOpacity();
        } else {
            p.format = PixelFormat.TRANSLUCENT;
        }
				
        if (mHeightMode < 0) {
            p.height = mLastHeight = mHeightMode;
        } else {
            p.height = mLastHeight = mHeight;
        }

        if (mWidthMode < 0) {
            p.width = mLastWidth = mWidthMode;
        } else {
            p.width = mLastWidth = mWidth;
        }

        p.privateFlags = PRIVATE_FLAG_WILL_NOT_REPLACE_ON_RELAUNCH
                | PRIVATE_FLAG_LAYOUT_CHILD_WINDOW_IN_PARENT_FRAME;

        // Used for debugging.
        p.setTitle("PopupWindow:" + Integer.toHexString(hashCode()));

        return p;
    }
```

### preparePopup

```java
private void preparePopup(WindowManager.LayoutParams p) {
        // When a background is available, we embed the content view within
        // another view that owns the background drawable.
        if (mBackground != null) {
            mBackgroundView = createBackgroundView(mContentView);
            mBackgroundView.setBackground(mBackground);
        } else {
            mBackgroundView = mContentView;
        }
        mDecorView = createDecorView(mBackgroundView);
}
```

总体就是为了创建如下层次的 View：

<img src="https://s2.loli.net/2022/04/16/QPVcIXEg1xiOC68.png" alt="image-20220416213805438" style="zoom: 50%;" />

不过， DecorView 上有附加效果，主要是事件和动画相关的。后面具体进行分析。

### findDropDownPosition

就像其注释说的，计算PopupWindow 在屏幕上面的位置：

- 如果PopupWindow太高，无法放置到anchor的下方，则会检测上层是否有可滚动的视图，并向上滚动以获取可用空间。
- 如果父布局无法滚动，**popupWindow会放置到anchor的上方**。

```java
    protected boolean findDropDownPosition(View anchor, WindowManager.LayoutParams outParams,
            int xOffset, int yOffset, int width, int height, int gravity, boolean allowScroll) {
      // 获取 anchor宽高
        final int anchorHeight = anchor.getHeight();
        final int anchorWidth = anchor.getWidth();
      // 允许重叠时，会先上移动 anchor 的高度
        if (mOverlapAnchor) {
            yOffset -= anchorHeight;
        }

        // 先尝试将位置放置在anchor的左下角并加上偏移量
      // 获取anchor的rootView在屏幕上的位置 appScreenLocation 
        final int[] appScreenLocation = mTmpAppLocation;
        final View appRootView = getAppRootView(anchor);
        appRootView.getLocationOnScreen(appScreenLocation);
			// 获取 anchor 在屏幕上的位置 screenLocation
        final int[] screenLocation = mTmpScreenLocation;
        anchor.getLocationOnScreen(screenLocation);
			
      // 计算初步的绘制位置
        final int[] drawingLocation = mTmpDrawingLocation;
        drawingLocation[0] = screenLocation[0] - appScreenLocation[0];
        drawingLocation[1] = screenLocation[1] - appScreenLocation[1];
        outParams.x = drawingLocation[0] + xOffset;
        outParams.y = drawingLocation[1] + anchorHeight + yOffset;
			
      // 如果宽高参数为 MATCH_PARENT 时，根据外层可用空间计算真正的具体宽高数值
        final Rect displayFrame = new Rect();
        appRootView.getWindowVisibleDisplayFrame(displayFrame);
        if (width == MATCH_PARENT) {
            width = displayFrame.right - displayFrame.left;
        }
        if (height == MATCH_PARENT) {
            height = displayFrame.bottom - displayFrame.top;
        }

        // Let the window manager know to align the top to y.
        outParams.gravity = computeGravity();
        outParams.width = width;
        outParams.height = height;
        // 第一阶段完成

        // 第二阶段：尝试（在不调整大小的情况下）调整Popup的垂直方向，通过返回值可以判断垂直方向上是否够用
        final boolean fitsVertical = tryFitVertical(outParams, yOffset, height,
                anchorHeight, drawingLocation[1], screenLocation[1], displayFrame.top,
                displayFrame.bottom, false);

        // 第三阶段：接下来,尝试（在不调整大小的情况下）调整Popup的水平方向，通过返回值可以判断水平方向上是否够用
        final boolean fitsHorizontal = tryFitHorizontal(outParams, xOffset, width,
                anchorWidth, drawingLocation[0], screenLocation[0], displayFrame.left,
                displayFrame.right, false);

        // 第四阶段：如果无法满足Popup的显示，则尝试滚动父View
        if (!fitsVertical || !fitsHorizontal) {
            final int scrollX = anchor.getScrollX();
            final int scrollY = anchor.getScrollY();
            final Rect r = new Rect(scrollX, scrollY, scrollX + width + xOffset,
                    scrollY + height + anchorHeight + yOffset);
            if (allowScroll && anchor.requestRectangleOnScreen(r, true)) {
                // Reset for the new anchor position.
                anchor.getLocationOnScreen(screenLocation);
                drawingLocation[0] = screenLocation[0] - appScreenLocation[0];
                drawingLocation[1] = screenLocation[1] - appScreenLocation[1];
                outParams.x = drawingLocation[0] + xOffset;
                outParams.y = drawingLocation[1] + anchorHeight + yOffset;

                // Preserve the gravity adjustment.
                if (hgrav == Gravity.RIGHT) {
                    outParams.x -= width - anchorWidth;
                }
            }

            // Try to fit the popup again and allowing resizing.
            tryFitVertical(outParams, yOffset, height, anchorHeight, drawingLocation[1],
                    screenLocation[1], displayFrame.top, displayFrame.bottom, mClipToScreen);
            tryFitHorizontal(outParams, xOffset, width, anchorWidth, drawingLocation[0],
                    screenLocation[0], displayFrame.left, displayFrame.right, mClipToScreen);
        }

        // Return whether the popup's top edge is above the anchor's top edge.
        return outParams.y < drawingLocation[1];
    }
```

第一阶段的计算过程如下，得到最后的x，y值：

<img src="https://s2.loli.net/2022/04/16/WJ4QsCUSnvOgdNk.png" alt="image-20220416224532102" style="zoom: 50%;" />

#### tryFitVertical



```java
    private boolean tryFitVertical(@NonNull LayoutParams outParams, int yOffset, int height,
            int anchorHeight, int drawingLocationY, int screenLocationY, int displayFrameTop,
            int displayFrameBottom, boolean allowResize) {
      // 计算Y方向上的 offset，screenLocationY为anchorView的Y，drawingLocationY为popup的Y
        final int winOffsetY = screenLocationY - drawingLocationY;
      // anchor 
        final int anchorTopInScreen = outParams.y + winOffsetY;
        final int spaceBelow = displayFrameBottom - anchorTopInScreen;
        if (anchorTopInScreen >= displayFrameTop && height <= spaceBelow) {
            return true;
        }

        final int spaceAbove = anchorTopInScreen - anchorHeight - displayFrameTop;
        if (height <= spaceAbove) {
            // Move everything up.
            if (mOverlapAnchor) {
                yOffset += anchorHeight;
            }
            outParams.y = drawingLocationY - height + yOffset;

            return true;
        }

        if (positionInDisplayVertical(outParams, height, drawingLocationY, screenLocationY,
                displayFrameTop, displayFrameBottom, allowResize)) {
            return true;
        }

        return false;
    }
```



#### tryFitHorizontal