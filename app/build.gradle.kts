plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

// The release preserves Andrew Nakas's v0.1.19 native engine. The portable
// pocket build scripts verify and stage that binary and the Vulkan proxy;
// Gradle packages them with the matching, revision-pinned SDL Java classes.
val sdlJavaDir = rootProject.file("sdl-java").absolutePath

android {
    namespace = "com.nakas.skate3"

    // The diagnostic report names the version it was gathered from; without
    // that a report from a stranger cannot be matched to a build.
    buildFeatures {
        buildConfig = true
    }
    compileSdk = 35
    ndkVersion = "27.2.12479018"

    defaultConfig {
        applicationId = "io.github.alanconstantino.skate3pocket"
        // 28 covers ASharedMemory (26) for the guest memory mapping and AAudio
        // (27) for the audio backend, both of which the runtime needs.
        minSdk = 28
        targetSdk = 35
        versionCode = 2
        versionName = "0.1.1"
        ndk { abiFilters += "arm64-v8a" }
    }

    sourceSets["main"].java.srcDirs("src/main/java", sdlJavaDir)

    val releaseKey = System.getenv("POCKET_KEYSTORE")
    val releaseAlias = System.getenv("POCKET_KEY_ALIAS")
    val releaseStorePassword = System.getenv("POCKET_STORE_PASSWORD")
    val releaseKeyPassword = System.getenv("POCKET_KEY_PASSWORD")
    val signingValues = listOf(releaseKey, releaseAlias, releaseStorePassword, releaseKeyPassword)
    require(signingValues.all { it.isNullOrBlank() } || signingValues.all { !it.isNullOrBlank() }) {
        "Provide all four POCKET signing variables, or omit all of them for an unsigned build."
    }
    signingConfigs {
        if (!releaseKey.isNullOrBlank()) {
            create("pocketRelease") {
                storeFile = file(releaseKey)
                storePassword = releaseStorePassword
                keyAlias = releaseAlias
                keyPassword = releaseKeyPassword
            }
        }
    }
    buildTypes {
        release {
            isMinifyEnabled = false
            isDebuggable = false
            signingConfig = signingConfigs.findByName("pocketRelease")
        }
        debug {
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
        }
    }

    packaging {
        // The Vulkan proxy is explicitly loaded from nativeLibraryDir before
        // SDL loads the engine, so Android must extract these files.
        jniLibs.useLegacyPackaging = true
        // Preserve each reviewed native artifact's exact bytes; the official
        // engine is already stripped and the small support libraries stay intact.
        jniLibs.keepDebugSymbols += "**/*.so"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
    lint {
        abortOnError = true
        // Only the 29 existing findings in the untouched, revision-pinned SDL
        // Java files are baselined. All app code and new findings remain checked.
        baseline = file("lint-baseline.xml")
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.13.1")
}
