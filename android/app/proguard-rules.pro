# ==========================================
# 1. ML Kit Text Recognition Rules
# ==========================================
-keep class com.google.mlkit.vision.text.** { *; }
-dontwarn com.google.mlkit.vision.text.**
-keep class com.google.mlkit.** { *; }
-keep class io.flutter.plugins.googlemlkit.** { *; }

# ==========================================
# 2. Printing & PDF Plugin Rules
# ==========================================
-keep class net.nfet.printing.** { *; }
-dontwarn net.nfet.printing.**
-keep class android.print.** { *; }
-keep class android.graphics.pdf.** { *; }

# ==========================================
# 3. Flutter Core & Platform Channel Rules
# ==========================================
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.provider.** { *; }

# ==========================================
# 4. Fix R8 Missing Play Core Classes Error
# ==========================================
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**