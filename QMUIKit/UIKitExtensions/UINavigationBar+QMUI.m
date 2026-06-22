});
}

+// 修复 Xcode26.2 下，iOS26.2 闪退的问题。
+//  terminating due to uncaught exception of type NSException
+//  *** Terminating app due to uncaught exception 'NSUnknownKeyException', reason: '[<UIKit._UINavigationBarVisualProviderModernIOSSwift 0x106533e80> valueForUndefinedKey:]: this class is not key value coding-compliant for the key contentView.' ***
+// 兼容性更强的实现：先尝试 KVC，若抛异常则回退到遍历 subviews 查找
- (UIView *)qmui_contentView {
-    return [self valueForKeyPath:@"visualProvider.contentView"];
+    UIView *contentView = nil;
+
+    if (@available(iOS 26.0, *)) {
+        contentView = nil;
+    } else {
+        // 老版本走原来的方法，但是用 try 兜底
+        @try {
+            contentView = [self valueForKeyPath:@"visualProvider.contentView"];
+        } @catch (NSException *exception) {
+            contentView = nil;
+        }
+    }
+    if (contentView) {
+        return contentView;
+    }
+
+    // 按类名查找 _UINavigationBarContentView
+    Class class__NavigationBarContentView = NSClassFromString([NSString qmui_stringByConcat:@"_", @"UINavigationBar", @"ContentView", nil]);
+    if (class__NavigationBarContentView) {
+        contentView = [self subviewWithClass:class__NavigationBarContentView];
+        if (contentView) {
+            return contentView;
+        }
+    }
+
+    // 按类名查找 UIKit.NavigationBarContentView
+    Class class_UIKit_NavigationBarContentView = NSClassFromString(@"UIKit.NavigationBarContentView");
+    if (class_UIKit_NavigationBarContentView) {
+        contentView = [self subviewWithClass:class_UIKit_NavigationBarContentView];
+        if (contentView) {
+            return contentView;
+        }
+    }
+
+    // 查找名字中包含 "ContentView" 的 view
+    NSString *classNamePart_ContentView = @"ContentView";
+    contentView = [self subviewWithClassNamePart:classNamePart_ContentView];
+    if (contentView) {
+        return contentView;
+    }
+
+    return nil;
+}
+
+- (UIView *)subviewWithClass:(Class)aClass {
+    if (aClass) {
+        for (UIView *sub in self.subviews) {
+            if ([sub isKindOfClass:aClass]) {
+                return sub;
+            }
+            // 有的系统层次里 contentView 不是直接子视图，尝试再向下查找一层
+            for (UIView *sub2 in sub.subviews) {
+                if ([sub2 isKindOfClass:aClass]) {
+                    return sub2;
+                }
+            }
+        }
+    }
+    return nil;
+}
+
+- (UIView *)subviewWithClassNamePart:(NSString *)classNamePart {
+    for (UIView *sub in self.subviews) {
+        NSString *className = NSStringFromClass(sub.class);
+        if ([className containsString:classNamePart]) {
+            return sub;
+        }
+        for (UIView *sub2 in sub.subviews) {
+            NSString *className2 = NSStringFromClass(sub2.class);
+            if ([className2 containsString:classNamePart]) {
+                return sub2;
+            }
+        }
+    }
+    return nil;
}

- (void)qmuinb_fixTitleViewLayoutInIOS16 {
