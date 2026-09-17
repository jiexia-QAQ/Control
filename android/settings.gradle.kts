pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // Control 构建补丁：AGP 9 强制 Gradle 9 双进程架构（沙箱跨进程写保护致命），降级 AGP 8.9.2 + Gradle 8.14 单进程构建
    id("com.android.application") version "8.9.2" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}

include(":app")
