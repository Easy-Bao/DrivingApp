plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

fun loadDotEnvValue(name: String): String? {
    val envFile = rootProject.file("../.env")
    if (!envFile.isFile) return null

    return envFile.readLines()
        .asSequence()
        .map(String::trim)
        .filter { it.isNotEmpty() && !it.startsWith("#") }
        .mapNotNull { line ->
            val separator = line.indexOf('=')
            if (separator <= 0 || line.substring(0, separator).trim() != name) {
                null
            } else {
                line.substring(separator + 1).trim().trim('"', '\'')
            }
        }
        .firstOrNull { it.isNotEmpty() }
}

android {
    namespace = "com.zervx.easyride.passenger"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions { jvmTarget = JavaVersion.VERSION_17.toString() }

    defaultConfig {
        applicationId = "com.zervx.easyride.passenger"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["MAPBOX_PUBLIC_TOKEN"] =
                providers.gradleProperty("MAPBOX_PUBLIC_TOKEN").orNull
                    ?: System.getenv("MAPBOX_PUBLIC_TOKEN")
                    ?: loadDotEnvValue("MAPBOX_PUBLIC_TOKEN")
                    ?: ""
    }

    buildTypes { release { signingConfig = signingConfigs.getByName("debug") } }
}

flutter { source = "../.." }
