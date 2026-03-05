import com.android.build.api.dsl.ApplicationExtension
import com.android.build.api.dsl.LibraryExtension

fun forceCompileSdk(extension: Any, sdk: Int) {
    val cls = extension.javaClass
    val setCompileSdk =
        cls.methods.firstOrNull { it.name == "setCompileSdk" && it.parameterCount == 1 }
    if (setCompileSdk != null) {
        setCompileSdk.invoke(extension, sdk)
        return
    }
    val compileSdkVersion =
        cls.methods.firstOrNull { it.name == "compileSdkVersion" && it.parameterCount == 1 }
    if (compileSdkVersion != null) {
        compileSdkVersion.invoke(extension, sdk)
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Some transitive Android library modules can default to old compileSdk values.
// Force a modern compileSdk across modules to avoid resource-linking failures
// like android:attr/lStar not found.
subprojects {
    plugins.withId("com.android.application") {
        extensions.configure<ApplicationExtension>("android") {
            compileSdk = 36
        }
    }
    plugins.withId("com.android.library") {
        extensions.configure<LibraryExtension>("android") {
            compileSdk = 36
        }
    }

    // Fallback for legacy plugin modules (e.g. AGP 7.x Groovy scripts in pub cache)
    // where the typed DSL extension above may not apply.
    afterEvaluate {
        extensions.findByName("android")?.let { androidExt ->
            forceCompileSdk(androidExt, 36)
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
