# ============================================================
# PROGUARD RULES - TRIADE APP
# Regras otimizadas para flutter_local_notifications
# ============================================================

# ============ FLUTTER LOCAL NOTIFICATIONS ============
# Mantém TODAS as classes do plugin de notificações
-keep class com.dexterous.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.** { *; }

# Receivers específicos - CRÍTICO para notificações agendadas
-keep public class com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver { *; }
-keep public class com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver { *; }
-keep public class com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver { *; }
-keep public class com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin { *; }

# Models usados para serialização de notificações
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.models.** { *; }

# ============ ANDROIDX ============
-keep class androidx.core.app.** { *; }
-keep class androidx.core.content.** { *; }
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**

# ============ GSON (serialização de notificações) ============
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class com.google.gson.stream.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# ============ TIMEZONE ============
-keep class org.threeten.** { *; }
-keep class org.threeten.bp.** { *; }
-dontwarn org.threeten.**

# ============ KOTLIN ============
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
-dontwarn kotlin.**
-dontwarn kotlinx.**
-keepclassmembers class **$WhenMappings { <fields>; }
-keepclassmembers class kotlin.Metadata { *; }

# ============ FLUTTER ============
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.app.** { *; }

# ============ ANDROID COMPONENTS ============
-keep class * extends android.app.Service
-keep class * extends android.content.BroadcastReceiver
-keep class * extends android.app.Activity
-keep class * extends android.app.Application
-keep class android.app.AlarmManager { *; }
-keep class android.app.PendingIntent { *; }
-keep class android.app.NotificationManager { *; }
-keep class android.app.NotificationChannel { *; }

# ============ AUDIOPLAYERS ============
-keep class xyz.luan.audioplayers.** { *; }

# ============ SHARED PREFERENCES ============
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# ============ SECURE STORAGE ============
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# ============ IMAGE PICKER ============
-keep class io.flutter.plugins.imagepicker.** { *; }

# ============ GOOGLE PLAY CORE ============
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# ============ REFLECTION ============
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ============ DEBUG ============
-keepnames class * extends java.lang.Exception
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
