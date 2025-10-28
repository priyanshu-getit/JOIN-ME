plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services") version "4.3.15" // ✅ Firebase plugin, applied below
    id("dev.flutter.flutter-gradle-plugin") // ✅ Flutter plugin
}

android {
    namespace = "com.priyanshu.eventapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.priyanshu.eventapp"       // ✅ Unique app ID
        minSdk = 23                 // ✅ Minimum supported Android version
        targetSdk = 34            // ✅ Target Android version
        versionCode = 1                // ✅ Internal version
        versionName = "1.0.0"                // ✅ User visible version
    }

    buildTypes {
        release {
            // Remove debug signing config for production
            // Configure proper release signing in a separate signingConfigs block
            // Example (uncomment and customize for production):
            // signingConfig = signingConfigs.release
        }
        debug {
            // Debug build can use default debug signing
        }
    }
}

flutter {
    source = "../.."
}

// Apply Firebase plugin
apply(plugin = "com.google.gms.google-services")