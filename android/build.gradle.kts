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
        resolutionStrategy {
            eachDependency {
                if (requested.group == "org.jetbrains.kotlin" && requested.name.startsWith("kotlin-stdlib")) {
                    useVersion("1.9.10")
                }
            }
        }
    }

    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
            android?.let {
                // Force compile and target SDK versions
                it.compileSdkVersion(36)
                it.defaultConfig.targetSdk = 34
                
                // Ensure namespace is set for AGP 8.0+
                if (it.namespace == null) {
                    try {
                        val manifestFile = project.file("src/main/AndroidManifest.xml")
                        if (manifestFile.exists()) {
                            val manifestXml = manifestFile.readText()
                            val packageMatch = Regex("""package\s*=\s*["'](.*?)["']""").find(manifestXml)
                            if (packageMatch != null) {
                                it.namespace = packageMatch.groupValues[1]
                            } else {
                                it.namespace = "com.example.${project.name.replace("-", "_")}"
                            }
                        } else {
                             it.namespace = "com.example.${project.name.replace("-", "_")}"
                        }
                    } catch (e: Exception) {
                        it.namespace = "com.example.${project.name.replace("-", "_")}"
                    }
                }

                it.compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
            }
        }
    }

    // Standardize JVM target across all tasks
    project.tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        kotlinOptions {
            jvmTarget = "17"
        }
    }
    project.tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = "17"
        targetCompatibility = "17"
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
