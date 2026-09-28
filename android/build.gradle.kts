allprojects {
    repositories {
        google()
        mavenCentral()
        maven("https://jcenter.bintray.com")
    }
    // Force all subprojects to use mavenCentral instead of the removed jcenter() method
    configurations.all {
        resolutionStrategy.eachDependency {
            // no-op: repository override handled above
        }
    }
}


val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
