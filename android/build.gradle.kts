buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:9.4.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.4.10")
        classpath("com.google.gms:google-services:4.5.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

tasks.register<Delete>("clean") {
    description = "Deletes the project build directory."
    group = "build"
    delete(rootProject.layout.buildDirectory)
}
