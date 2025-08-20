# Flutter相关的混淆规则
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }

# Google Play Core相关
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Dart相关保护
-keep class dart.** { *; }

# SSH和加密相关库保护 
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**

# 网络相关
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }
-dontwarn okhttp3.**
-dontwarn retrofit2.**

# 保护反射使用的类
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# 保护native方法
-keepclasseswithmembernames class * {
    native <methods>;
}

# 保护Serializable类
-keepnames class * implements java.io.Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# 移除调试信息
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# 更温和的优化选项
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-dontpreverify
-verbose

# 保留所有Flutter相关的类和方法不被混淆
-dontwarn io.flutter.embedding.**
-dontwarn androidx.**