pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // Coborâte de la AGP 9.0.1 / Kotlin 2.3.20 (versiunile implicite ale
    // template-ului Flutter la data creării proiectului) la o combinație
    // stabilă, larg compatibilă cu pluginuri — AGP 9+ obligă la alegerea
    // built-in Kotlin (android.builtInKotlin=true/false) pentru TOT
    // proiectul deodată, dar unele pluginuri (file_picker) presupun deja
    // built-in Kotlin activat, iar altele (add_2_calendar) încă aplică
    // manual `org.jetbrains.kotlin.android` — combinație imposibil de
    // satisfăcut simultan sub AGP 9. AGP 8.11.1/Kotlin 2.2.20 (minimul
    // recomandat chiar de Flutter tool în avertismentele de build) nu au
    // această problemă (ambele stiluri de plugin funcționează normal).
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
