plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.tvplus.stream"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    signingConfigs {
        create("release") {
            val keystoreFile = file("keystore/my_release_key.jks")
            if (keystoreFile.exists()) {
                storeFile = keystoreFile
                storePassword = "Haider1122"
                keyAlias = "my_key_alias"
                keyPassword = "Haider1122"
            }
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID.
        applicationId = "com.tvplus.stream"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            val keystoreFile = file("keystore/my_release_key.jks")
            if (keystoreFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                signingConfig = signingConfigs.getByName("debug")
            }
            // minifyEnabled false // optional
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
