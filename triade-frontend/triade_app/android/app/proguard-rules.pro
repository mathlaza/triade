# Flutter Local Notifications
-keep class com.dexterous.** { *; }
-keep class androidx.core.app.** { *; }

# Gson (usado por flutter_local_notifications)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.stream.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Timezone
-keep class org.threeten.** { *; }

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Evita problemas com notificações em background
-keep class * extends android.app.Service
-keep class * extends android.content.BroadcastReceiver

# Google Play Core - Evita erros do R8
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
