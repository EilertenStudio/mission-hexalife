pluginManagement {
    resolutionStrategy {
        plugins {
            // IDE
            // ----------------------------------------------------------------
            id("idea")

            // Kotlin
            // ----------------------------------------------------------------
//            kotlin("multiplatform") version (extra["kotlin.version"] as String)

            // Game Engine

            id("com.utopia-rise.godot-kotlin-jvm") version "latest.release" //(extra["godot.kvm.version"] as String)
        }
    }
}

dependencyResolutionManagement {
    repositories {
        mavenCentral()
        google()
    }
}

rootProject.projectDir
    .listFiles()
    ?.filter { it.isDirectory
            && it.name.equals("packages")
    }
    ?.forEach { category -> category.listFiles()
        ?.filter { it.isDirectory }
        ?.forEach { module ->
//            includeBuild(module.path) {
//                name = "${category.name}:${module.name}"
//            }
            ":${category.name}:${module.name}".let {
                include(it)
                project(it).apply {
                    projectDir = module
                }
            }
        }
    }
