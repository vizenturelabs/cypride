# Flutter: Scoped rules to avoid overly broad warnings
# Keep only the essential activity and plugin communication classes
-keep class io.flutter.embedding.android.FlutterActivity { *; }
-keep class io.flutter.plugin.common.** { *; }
-keep class io.flutter.embedding.engine.FlutterEngine { *; }
-keep class io.flutter.embedding.engine.FlutterJNI { *; }
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# Firebase & Play Services:
# Broad rules removed. The SDKs include their own consumer proguard rules.
# Only add -dontwarn if you see missing class errors during build.
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Play Core: legacy task API referenced by Flutter's deferred components manager
# (classes no longer exist in the new feature-delivery artifact; safe to ignore
#  unless you actually use deferred components/dynamic features)
-dontwarn com.google.play.core.tasks.**

# OkHttp & Gson (Safe dontwarn)
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-dontwarn com.google.gson.**

# Prevent R8 from failing on missing optional dependencies
-dontwarn java.lang.invoke.**
-dontwarn **$LambdaLambdaLambda**
