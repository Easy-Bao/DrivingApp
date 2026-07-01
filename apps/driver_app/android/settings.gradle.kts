val flutterSdkPath = run {
    val properties = java.util.Properties()
    file("local.properties").inputStream().use { properties.load(it) }
    val path = properties.getProperty("flutter.sdk")
    require(path != null) { "flutter.sdk not set in local.properties" }
    path
}

val srcDir = file("$flutterSdkPath/packages/flutter_tools/gradle")
val destDir = file("build/gradle")

if (!destDir.exists()) {
    destDir.mkdirs()
    srcDir.listFiles()?.forEach { file ->
        if (file.name != ".gradle" && file.name != "settings.gradle") {
            file.copyRecursively(file(destDir.path + "/" + file.name), overwrite = true)
        }
    }
}

includeBuild(destDir)

pluginManagement {
    val downloadsToken = settings.providers.gradleProperty("MAPBOX_DOWNLOADS_TOKEN").orNull ?: ""

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
        maven {
            url = uri("https://api.mapbox.com/downloads/v2/releases/maven")
            credentials.username = "mapbox"
            credentials.password = downloadsToken
            authentication {
                create<BasicAuthentication>("basic")
            }
        }
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}

include(":app")
