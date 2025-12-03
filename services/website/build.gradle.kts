plugins {
  id("idea")
}

idea {
  module {
    sourceDirs.addAll(arrayOf(
      file("src"),
      file("public")
    ))
  }
}