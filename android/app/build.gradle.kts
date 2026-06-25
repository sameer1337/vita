plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase (Cloud Messaging). Reads android/app/google-services.json.
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.vita"
    compileSdk = flutter.compileSdkVersion
    // ndkVersion intentionally omitted — Vita has no native C++ code, so the
    // NDK isn't needed. (Avoids a corrupt/partial NDK install + a ~1 GB
    // re-download on this connection.)

    compileOptions {
        // Required by flutter_local_notifications.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.vita"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Firebase Cloud Messaging requires API 23+.
        minSdk = maxOf(23, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Core library desugaring runtime, required by flutter_local_notifications.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
