allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// V1.8 image_picker 传递依赖 androidx.activity 1.13.0 无法从本机代理拉取，
// 全模块强制降级到本地缓存版本（API 兼容）
subprojects {
    configurations.configureEach {
        resolutionStrategy {
            force("androidx.activity:activity:1.12.4")
            force("androidx.activity:activity-ktx:1.12.4")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
