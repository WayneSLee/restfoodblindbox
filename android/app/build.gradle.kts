import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// 函式：讀取 local.properties 檔案
fun localProperties(): Properties {
    val properties = Properties()
    val localPropertiesFile = rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        properties.load(FileInputStream(localPropertiesFile))
    }
    return properties
}

// 在頂部讀取 Flutter 相關設定，並提供預設值
val localProperties = localProperties()
val flutterCompileSdk = localProperties.getProperty("flutter.compileSdkVersion")?.toIntOrNull() ?: 34
val flutterTargetSdk = localProperties.getProperty("flutter.targetSdkVersion")?.toIntOrNull() ?: 34
val flutterVersionCode = localProperties.getProperty("flutter.versionCode")?.toIntOrNull() ?: 1
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0"

android {
    namespace = "com.kuanxing.co.restfoodblindbox"
    compileSdk = 35 // 使用從 local.properties 讀取的值
    ndkVersion = "27.0.12077973" // 您的 ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // 簽章設定區塊
    val keyPropertiesFile = rootProject.file("key.properties")
    val keyProperties = Properties()
    if (keyPropertiesFile.exists()) {
        keyProperties.load(FileInputStream(keyPropertiesFile))
    }

    buildFeatures {
        buildConfig = true
    }

    signingConfigs {
        create("release") {
            keyAlias = keyProperties["keyAlias"] as String?
            keyPassword = keyProperties["keyPassword"] as String?
            storeFile = if (keyProperties["storeFile"] != null) file(keyProperties["storeFile"] as String) else null
            storePassword = keyProperties["storePassword"] as String?
        }
    }

    defaultConfig {
        applicationId = "com.kuanxing.co.restfoodblindbox"
        minSdk = 23
        targetSdk = 35 // 使用從 local.properties 讀取的值
        versionCode = flutterVersionCode // 使用從 pubspec.yaml 讀取的值
        versionName = flutterVersionName // 使用從 pubspec.yaml 讀取的值
    }

    buildTypes {
        release {
            // 指向您的 release 簽章設定
            signingConfig = signingConfigs.getByName("release")
        }
        debug {
            // 使 debug 版本的 applicationId 加上 .dev 後綴，以利於和正式版共存於手機上
            applicationIdSuffix = ".dev"
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // 您可以在這裡加入其他 Android 相關的依賴
}