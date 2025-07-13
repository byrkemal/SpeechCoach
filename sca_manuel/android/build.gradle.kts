allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

buildscript {
    // Groovy'deki ext {} yerine Kotlin DSL'de extra {} kullanılır
    extra["kotlin_version"] = "1.9.0" // Veya daha yeni bir sürüm (örn. "1.9.22")
    extra["agp_version"] = "8.1.1"    // <--- Bu sürümü güncelleyin. Örneğin "8.1.1"

    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Groovy'deki classpath '' yerine Kotlin DSL'de "" kullanılır
        // ve değişkenler "$()" veya "${}" ile kullanılır.
        val kotlin_version by extra("1.9.0")
        val agp_version by extra("8.1.1")

        classpath("com.android.tools.build:gradle:${extra["agp_version"]}")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:${extra["kotlin_version"]}")
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

plugins {
    id("com.google.gms.google-services") version "4.4.2" apply false
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
