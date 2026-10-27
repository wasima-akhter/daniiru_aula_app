allprojects {
    repositories {
        google()
        mavenCentral()
    }

    configurations.all {
        exclude(group = "com.google.android.gms", module = "play-services-tapandpay")
    }

    tasks.configureEach {
        if (name.contains("lintVital", ignoreCase = true)) {
            enabled = false
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

gradle.taskGraph.whenReady {
    allTasks.forEach { task ->
        if (task.name.contains("lintVital", ignoreCase = true)) {
            task.enabled = false
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
