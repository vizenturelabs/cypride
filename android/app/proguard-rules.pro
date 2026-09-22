# Flutter Engine & Embedding
-keep class io.flutter.embedding.android.FlutterActivity { *; }
-keep class io.flutter.embedding.engine.FlutterEngine { *; }
-keep class io.flutter.embedding.engine.FlutterJNI { *; }
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# Flutter Platform Channels
-keep class io.flutter.plugin.common.MethodChannel { *; }
-keep class io.flutter.plugin.common.MethodChannel$MethodCallHandler { *; }
-keep class io.flutter.plugin.common.MethodChannel$Result { *; }
-keep class io.flutter.plugin.common.EventChannel { *; }
-keep class io.flutter.plugin.common.EventChannel$StreamHandler { *; }
-keep class io.flutter.plugin.common.EventChannel$EventSink { *; }
-keep class io.flutter.plugin.common.BasicMessageChannel { *; }
-keep class io.flutter.plugin.common.BinaryMessenger { *; }
-keep class io.flutter.plugin.common.PluginRegistry { *; }
-keep class io.flutter.plugin.common.StandardMessageCodec { *; }
-keep class io.flutter.plugin.common.StandardMethodCodec { *; }

# Google Sign-In Plugin & Native SDKs (Scoped to prevent overly broad warnings)
-keep class io.flutter.plugins.googlesignin.** { *; }
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.common.api.ApiException { *; }
-keep class com.google.android.gms.common.SignInButton { *; }
-keep class com.google.android.gms.tasks.** { *; }

# Keep Guava (often required by Google Play Services under the hood)
-dontwarn com.google.common.**

# Secure Storage & Cryptography
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-dontwarn androidx.security.crypto.**

# Firebase & Play Services:
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
-dontwarn com.google.play.core.tasks.**

# OkHttp & Gson (Safe dontwarn)
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-dontwarn com.google.gson.**

# Prevent R8 from failing on missing optional dependencies
-dontwarn java.lang.invoke.**
-dontwarn org.conscrypt.**
-dontwarn **$$Lambda$**
