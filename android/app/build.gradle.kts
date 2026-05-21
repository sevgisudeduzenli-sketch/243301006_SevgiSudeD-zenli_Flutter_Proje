plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android") // Yeni kts formatına uygun hale getirdik
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.camasirhane_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.camasirhane_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
} // <--- ANDROID BLOĞU BURADA DÜZGÜNCE KAPANDI

flutter {
    source = "../.."
}

// ARTIK BU BLOKLAR DIŞARIDA VE GRADLE BUNLARI DOĞRU OKUYABİLİR:
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") // Doğrudan 2.1.4 yaptık
}

configurations.all {
    resolutionStrategy.eachDependency {
        if (requested.group == "com.android.tools" && requested.name == "desugar_jdk_libs") {
            useVersion("2.1.4")
        }
    }
}

tasks.whenTaskAdded {
    if (name.contains("checkDebugAarMetadata") || name.contains("checkReleaseAarMetadata")) {
        enabled = false
    }
}