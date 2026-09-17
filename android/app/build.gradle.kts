plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// V1.8 image_picker 传递依赖 androidx.activity 1.13.0 无法从本机代理拉取，
// 强制降级到本地缓存已有版本（API 兼容，image_picker 仅用基础 ActivityResult API）
configurations.all {
    resolutionStrategy {
        force("androidx.activity:activity:1.12.4")
        force("androidx.activity:activity-ktx:1.12.4")
    }
}

android {
    namespace = "com.jiexia.control"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // V1.4 flutter_local_notifications 需要 core library desugaring
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.jiexia.control"
        // Android 8.0+（ColorOS 5.0+），保证自适应矢量图标全面覆盖
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = 18
        versionName = "1.8"
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
    // V1.4 core library desugaring（flutter_local_notifications 依赖）
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
