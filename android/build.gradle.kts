allprojects {
    repositories {
        google()
        mavenCentral()
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
    project.configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group.startsWith("androidx.activity")) {
                useVersion("1.9.1")
            }
            if (requested.group.startsWith("androidx.core")) {
                useVersion("1.13.1")
            }
        }
    }
}

subprojects {
    afterEvaluate {
        val android = project.extensions.findByType<com.android.build.gradle.BaseExtension>()
        android?.apply {
            compileSdkVersion(35)
            buildToolsVersion("35.0.0")
            ndkVersion = "25.1.8937393"
            
            defaultConfig {
                minSdkVersion(24)
                targetSdkVersion(35)
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
