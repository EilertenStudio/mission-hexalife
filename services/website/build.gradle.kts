plugins {
  id("idea")
}

idea {
  module {
    sourceDirs.addAll(arrayOf(
      file("src")
    ))
    resourceDirs.addAll(arrayOf(
      file("public")
    ))
  }
}