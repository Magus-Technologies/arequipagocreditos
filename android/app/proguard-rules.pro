# Keep Flutter entrypoints and plugin registrant
-keep class io.flutter.app.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }

# Keep application classes (adjust package name if you use a different one)
-keep class com.arequipago.arequipagocreditos.** { *; }

# Don't warn about missing references in plugin native code
-dontwarn io.flutter.embedding.**
-dontwarn io.flutter.plugin.**

# Remove logging from release builds
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
}

# Keep native libs loader
-keepclassmembers class * {
    native <methods>;
}
# Keep image_picker classes
-keep class io.flutter.plugins.imagepicker.** { *; }
-dontwarn io.flutter.plugins.imagepicker.**

# Keep file picker classes
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-dontwarn com.mr.flutter.plugin.filepicker.**
