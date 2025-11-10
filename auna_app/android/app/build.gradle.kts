plugins {
    id("com.android.application")
    id("kotlin-android")
    // El plugin de Flutter siempre va después de Android/Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.auna_app"

    // ✅ Android 14 APIs (recomendado para BLE moderno)
    compileSdk = 34

    // (opcional) si usas NDK, puedes dejar el que trae Flutter:
    // ndkVersion = "26.1.10909125"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.auna_app"

        // ✅ Mínimo soportado por Flutter + permission_handler
        minSdk = 21
        // ✅ Target 34 para permisos BLUETOOTH_SCAN/CONNECT
        targetSdk = 34

        // Puedes mantener los de Flutter si los manejas desde pubspec:
        // versionCode = flutter.versionCode
        // versionName = flutter.versionName

        // O fijarlos manualmente:
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            // Firma de ejemplo. Cambia a tu config de release cuando corresponda.
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
        }
        debug {
            // Sin cambios
        }
    }
}

flutter {
    source = "../.."
}
