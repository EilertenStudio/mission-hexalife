pluginManagement {
  resolutionStrategy {
    plugins {
      // ----------------------------------------------------------------
      // IDE
      // ----------------------------------------------------------------
      id("idea")

      // ----------------------------------------------------------------
      // Kotlin
      // ----------------------------------------------------------------
//      kotlin("multiplatform") version (extra["kotlin.version"] as String)
    }
  }
}

dependencyResolutionManagement {
  repositories {
    mavenCentral()
  }
}

with(rootProject) {
  fileTree(projectDir, {
    include(
      "**/build.gradle",
      "**/build.gradle.kts",
    )
  }).filter { file -> file.parentFile != projectDir }
    .forEach { file ->
      include(file.parentFile)
    }
}

fun File.toProjectPath(rootProject: ProjectDescriptor) =
  ":" + relativeTo(rootProject.projectDir)
    .path
    .replace(File.separator, ":")

fun include(
  projectDir: File,
  projectPath: String = projectDir.toProjectPath(rootProject),
  closure: Action<ProjectDescriptor>? = null
) {
  include(projectPath)
  project(projectPath).let {
    it.projectDir = projectDir
    closure?.execute(it)
  }
}