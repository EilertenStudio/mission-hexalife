pluginManagement {
    resolutionStrategy {
        plugins {
            // IDE
            // ----------------------------------------------------------------
            id("idea")
        }
    }
}

dependencyResolutionManagement {
    repositories {
        mavenCentral()
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
