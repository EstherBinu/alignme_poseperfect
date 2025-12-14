plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.yoga_correction"
    compileSdk = 36 // <-- FIX: Set a modern version
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.yoga_correction"
        minSdk = flutter.minSdkVersion
        targetSdk = 36 // <-- FIX: Set to modern version
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // *** FIX: Correct Kotlin Syntax and enable Multi-Dex ***
        multiDexEnabled = true 
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
