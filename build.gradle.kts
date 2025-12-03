import org.gradle.plugins.ide.idea.model.IdeaLanguageLevel

plugins {
  id("idea")
}


idea {
  project {
    languageLevel = IdeaLanguageLevel(extra["jdk.language.level"])
  }
  module {
    isDownloadJavadoc = true
    isDownloadSources = true
  }
}

// FIXME: issue on my local Gradle cache?
task("generateGdIgnoreFiles") {}
