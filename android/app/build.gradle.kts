plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter plugin MUST be after Android & Kotlin plugins
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase Google Services
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.iic_attendance_app_v2"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.iic_attendance_app_v2"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName
}

    buildTypes {
        release {
            // Debug signing for now
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Firebase BOM (manages Firebase SDK versions)
    implementation(platform("com.google.firebase:firebase-bom:33.7.0"))
}

flutter {
    source = "../.."
}
