plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("org.jetbrains.kotlin.android") version "1.9.22"
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.telegram"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.telegram"
        minSdk = 23
        targetSdk = 36
        versionCode = flutter.versionCode ?: 1
        versionName = flutter.versionName ?: "1.0.0"

        // MultiDex support untuk app besar
        multiDexEnabled = true

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    signingConfigs {
        create("release") {
            // Gunakan local.properties atau environment variables untuk keamanan
            keyAlias = project.findProperty("KEY_ALIAS") as String? ?: "debug"
            keyPassword = project.findProperty("KEY_PASSWORD") as String? ?: "android"
            storeFile = project.findProperty("STORE_FILE") as String? 
                ?.let { file(it) } 
                ?: file("debug.keystore")
            storePassword = project.findProperty("STORE_PASSWORD") as String? ?: "android"
        }
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".debug"
            debuggable = true
            minifyEnabled = false
        }

        profile {
            applicationIdSuffix = ".profile"
            debuggable = false
            minifyEnabled = false
        }

        release {
            signingConfig = signingConfigs.getByName("release")
            
            minifyEnabled = true
            shrinkResources = true
            
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    // Split APK per ABI untuk ukuran lebih kecil
    splits {
        abi {
            isEnable = true
            reset()
            include("armeabi-v7a", "arm64-v8a", "x86_64")
            isUniversalApk = true
        }
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
            excludes += "META-INF/versions/9/OSGI-INF/MANIFEST.MF"
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation("androidx.multidex:multidex:2.0.1")
    
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test:runner:1.5.2")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
}

flutter {
    source = "../.."
}