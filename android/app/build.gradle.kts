import org.jetbrains.kotlin.gradle.dsl.JvmTarget

val envFile = file("${project.rootDir}/.env")
if (envFile.exists()) {
    envFile.readLines().forEach { line ->
        // Added check to prevent crashes on empty lines or comments
        if (line.contains("=")) {
            val (key, value) = line.split("=", limit = 2)
            System.setProperty(key.trim(), value.trim())
        }
    }
}

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin") // Ensure org.jetbrains.kotlin.android is applied if not already
    id("com.google.gms.google-services")
}

@Suppress("DEPRECATION")
android {
    namespace = "com.vizenture.cypride"
    compileSdk = 37

    // FIX: Explicitly set the required NDK version
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // FIX: Removed deprecated tasks.withType blocks and kotlinOptions block.
    // The compileOptions block above handles Java compatibility.

    signingConfigs {
        create("release") {
            storeFile = file(System.getenv("KEYSTORE_PATH") ?: "upload-keystore.jks")
            storePassword = System.getenv("KEYSTORE_PASSWORD")
            keyAlias = System.getenv("KEY_ALIAS") ?: "upload"
            keyPassword = System.getenv("KEY_PASSWORD")
        }
    }

    defaultConfig {
        applicationId = "com.vizenture.cypride"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 9
        versionName = "1.1.3"

        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64")
        }
    }

    lint {
        // Allow the build to continue even if Lint finds warnings
        abortOnError = false
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

// FIX: Modern Kotlin Compiler Options DSL (replaces deprecated kotlinOptions)
kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

dependencies {
    implementation("androidx.appcompat:appcompat:1.8.0")
    implementation("androidx.core:core-ktx:1.19.0")
    implementation(platform("com.google.firebase:firebase-bom:34.19.0"))
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-appcheck-playintegrity")
    implementation("com.google.android.play:feature-delivery:2.1.0")
    // implementation("com.google.android.gms:play-services-auth:22.0.0")
    implementation("com.google.android.gms:play-services-maps:20.0.0")
}

flutter {
    source = "../.."
}