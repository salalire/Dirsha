plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.dirsha.dirsha_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.dirsha.dirsha_mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// Make `flutter run -d <device_id>` reach the local backend over USB without
// requiring a separate adb command. This is intentionally debug-only.
if (gradle.startParameter.taskNames.any { it.contains("Debug") }) {
    val reverseBackendPort = tasks.register("reverseBackendPort") {
        doLast {
            val adbName = if (System.getProperty("os.name").contains("Windows")) {
                "adb.exe"
            } else {
                "adb"
            }
            val adb = File(android.sdkDirectory, "platform-tools/$adbName")
            if (adb.isFile) {
                val process = ProcessBuilder(
                    adb.absolutePath,
                    "reverse",
                    "tcp:3000",
                    "tcp:3000",
                ).inheritIO().start()
                if (process.waitFor() != 0) {
                    logger.warn("adb reverse could not create the backend tunnel")
                }
            } else {
                logger.warn("adb was not found; local backend reverse tunnel was not created")
            }
        }
    }
    tasks.configureEach {
        if (name == "assembleDebug") {
            dependsOn(reverseBackendPort)
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
