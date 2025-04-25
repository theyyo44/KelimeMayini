plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin") // Flutter için gerekli
    id("com.google.gms.google-services")    // Firebase için gerekli
}

android {
    namespace = "com.example.kelime_mayinlari"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.kelime_mayinlari"
        minSdk = 27 // ✅ Firebase Auth için gerekli minimum SDK
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // ✅ Firebase BOM (sürüm yönetimi için)
    implementation(platform("com.google.firebase:firebase-bom:33.12.0"))

    // ✅ Kullanacağın Firebase ürünlerini buraya ekle
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")

    // Eğer ihtiyacın olursa:
    // implementation("com.google.firebase:firebase-analytics")
    // implementation("com.google.firebase:firebase-messaging")
}

flutter {
    source = "../.."
}
