#!/usr/bin/env bash
set-e

mkdir -p .github/workflows
mkdir -p app/src/main/java/com/limbus/mdtapper
mkdir -p app/src/main/res/layout
mkdir -p app/src/main/res/values
mkdir -p app/src/main/res/xml

# 1. GitHub Actions Workflow
cat << 'EOF' > .github/workflows/build.yml
name: Build Android APK

on:
  push:
    branches: [ main, master ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Setup Android SDK
        uses: android-actions/setup-android@v3

      - name: Generate Gradle Wrapper & Build Debug APK
        run: |
          gradle wrapper --gradle-version 8.5
          chmod +x gradlew
          ./gradlew assembleDebug

      - name: Upload APK Artifact
        uses: actions/upload-artifact@v4
        with:
          name: LimbusMDTapper-debug
          path: app/build/outputs/apk/debug/app-debug.apk
EOF

# 2. Root Gradle Files
cat << 'EOF' > settings.gradle.kts
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "LimbusMDTapper"
include(":app")
EOF

cat << 'EOF' > build.gradle.kts
plugins {
    id("com.android.application") version "8.2.2" apply false
    id("org.jetbrains.kotlin.android") version "1.9.22" apply false
}
EOF

# 3. App Gradle File
cat << 'EOF' > app/build.gradle.kts
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.limbus.mdtapper"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.limbus.mdtapper"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.1"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.11.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
}
EOF

# 4. AndroidManifest.xml (Includes Android 14/15 mediaProjection FGS permissions)
cat << 'EOF' > app/src/main/AndroidManifest.xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PROJECTION" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <application
        android:allowBackup="true"
        android:label="@string/app_name"
        android:supportsRtl="true"
        android:theme="@style/Theme.MaterialComponents.DayNight.DarkActionBar">

        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <service
            android:name=".OverlayService"
            android:enabled="true"
            android:exported="false"
            android:foregroundServiceType="mediaProjection" />

        <service
            android:name=".FarmAccessibilityService"
            android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE"
            android:exported="true">
            <intent-filter>
                <action android:name="android.accessibilityservice.AccessibilityService" />
            </intent-filter>
            <meta-data
                android:name="android.accessibilityservice"
                android:resource="@xml/accessibility_service_config" />
        </service>

    </application>
</manifest>
EOF

# 5. XML Resources
cat << 'EOF' > app/src/main/res/values/strings.xml
<resources>
    <string name="app_name">Limbus MD Tapper</string>
    <string name="accessibility_service_description">Automates Mirror Dungeon combat and event taps via gesture dispatch.</string>
</resources>
EOF

cat << 'EOF' > app/src/main/res/xml/accessibility_service_config.xml
<?xml version="1.0" encoding="utf-8"?>
<accessibility-service xmlns:android="http://schemas.android.com/apk/res/android"
    android:accessibilityEventTypes="typeWindowStateChanged"
    android:accessibilityFeedbackType="feedbackGeneric"
    android:accessibilityFlags="flagDefault"
    android:canPerformGestures="true"
    android:description="@string/accessibility_service_description"
    android:notificationTimeout="100" />
EOF

cat << 'EOF' > app/src/main/res/layout/activity_main.xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:gravity="center"
    android:padding="24dp">

    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="Limbus MD Auto-Tapper"
        android:textSize="22sp"
        android:textStyle="bold"
        android:layout_marginBottom="24dp" />

    <Button
        android:id="@+id/btnOverlayPermission"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="1. Grant Overlay Permission"
        android:layout_marginBottom="12dp" />

    <Button
        android:id="@+id/btnAccessibilityPermission"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="2. Enable Accessibility Service"
        android:layout_marginBottom="12dp" />

    <Button
        android:id="@+id/btnLaunchOverlay"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="3. Grant Screen Capture &amp; Launch" />

</LinearLayout>
EOF

cat << 'EOF' > app/src/main/res/layout/layout_floating_widget.xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="wrap_content"
    android:layout_height="wrap_content"
    android:orientation="horizontal"
    android:background="#CC1E1E1E"
    android:padding="8dp">

    <Button
        android:id="@+id/btnToggleMacro"
        android:layout_width="wrap_content"
        android:layout_height="40dp"
        android:text="START"
        android:textSize="12sp"
        android:backgroundTint="#2E7D32"
        android:textColor="#FFFFFF" />

    <Button
        android:id="@+id/btnCloseOverlay"
        android:layout_width="40dp"
        android:layout_height="40dp"
        android:layout_marginStart="6dp"
        android:text="X"
        android:textSize="12sp"
        android:backgroundTint="#C62828"
        android:textColor="#FFFFFF" />

</LinearLayout>
EOF

# 6. MainActivity.kt (Handles Overlay, Accessibility, and MediaProjection prompt)
cat << 'EOF' > app/src/main/java/com/limbus/mdtapper/MainActivity.kt
package com.limbus.mdtapper

import android.app.Activity
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.widget.Button
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {

    private val screenCaptureLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode == Activity.RESULT_OK && result.data != null) {
            FarmAccessibilityService.mediaProjectionResultCode = result.resultCode
            FarmAccessibilityService.mediaProjectionResultData = result.data
            startForegroundService(Intent(this, OverlayService::class.java))
            moveTaskToBack(true)
        } else {
            Toast.makeText(this, "Screen capture permission denied", Toast.LENGTH_SHORT).show()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 100)
        }

        val btnOverlay = findViewById<Button>(R.id.btnOverlayPermission)
        val btnAccessibility = findViewById<Button>(R.id.btnAccessibilityPermission)
        val btnLaunch = findViewById<Button>(R.id.btnLaunchOverlay)

        btnOverlay.setOnClickListener {
            if (!Settings.canDrawOverlays(this)) {
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:$packageName")
                )
                startActivity(intent)
            } else {
                Toast.makeText(this, "Overlay permission already granted", Toast.LENGTH_SHORT).show()
            }
        }

        btnAccessibility.setOnClickListener {
            startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
        }

        btnLaunch.setOnClickListener {
            if (!Settings.canDrawOverlays(this)) {
                Toast.makeText(this, "Grant Overlay permission first!", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            if (FarmAccessibilityService.instance == null) {
                Toast.makeText(this, "Enable Accessibility Service first!", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            val projectionManager = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
            screenCaptureLauncher.launch(projectionManager.createScreenCaptureIntent())
        }
    }
}
EOF

# 7. OverlayService.kt (Android 14/15 compatible mediaProjection foreground service)
cat << 'EOF' > app/src/main/java/com/limbus/mdtapper/OverlayService.kt
package com.limbus.mdtapper

import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.Button
import androidx.core.app.NotificationCompat

class OverlayService : Service() {

    private lateinit var windowManager: WindowManager
    private lateinit var floatingView: View
    private var isRunning = false

    override fun onBind(intent: Intent?): IBinder? = null

    @SuppressLint("ClickableViewAccessibility")
    override fun onCreate() {
        super.onCreate()
        startForegroundNotification()

        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        floatingView = LayoutInflater.from(this).inflate(R.layout.layout_floating_widget, null)

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 50
            y = 150
        }

        windowManager.addView(floatingView, params)

        val btnToggle = floatingView.findViewById<Button>(R.id.btnToggleMacro)
        val btnClose = floatingView.findViewById<Button>(R.id.btnCloseOverlay)

        floatingView.setOnTouchListener(object : View.OnTouchListener {
            private var initialX = 0
            private var initialY = 0
            private var initialTouchX = 0f
            private var initialTouchY = 0f

            override fun onTouch(v: View, event: MotionEvent): Boolean {
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        initialX = params.x
                        initialY = params.y
                        initialTouchX = event.rawX
                        initialTouchY = event.rawY
                        return true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        params.x = initialX + (event.rawX - initialTouchX).toInt()
                        params.y = initialY + (event.rawY - initialTouchY).toInt()
                        windowManager.updateViewLayout(floatingView, params)
                        return true
                    }
                }
                return false
            }
        })

        btnToggle.setOnClickListener {
            isRunning = !isRunning
            if (isRunning) {
                btnToggle.text = "STOP"
                btnToggle.setBackgroundColor(Color.parseColor("#EF6C00"))
                FarmAccessibilityService.instance?.startFarmingLoop()
            } else {
                btnToggle.text = "START"
                btnToggle.setBackgroundColor(Color.parseColor("#2E7D32"))
                FarmAccessibilityService.instance?.stopFarmingLoop()
            }
        }

        btnClose.setOnClickListener {
            FarmAccessibilityService.instance?.stopFarmingLoop()
            stopSelf()
        }
    }

    private fun startForegroundNotification() {
        val channelId = "limbus_tapper_overlay"
        val channel = NotificationChannel(
            channelId,
            "Limbus MD Tapper Overlay",
            NotificationManager.IMPORTANCE_LOW
        )
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)

        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Limbus MD Tapper Active")
            .setContentText("Screen analyzer and floating controller active.")
            .setSmallIcon(android.R.drawable.ic_media_play)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                101,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
            )
        } else {
            startForeground(101, notification)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        if (::floatingView.isInitialized) {
            windowManager.removeView(floatingView)
        }
    }
}
EOF

# 8. FarmAccessibilityService.kt (MediaProjection screen capture + pixel state analyzer)
cat << 'EOF' > app/src/main/java/com/limbus/mdtapper/FarmAccessibilityService.kt
package com.limbus.mdtapper

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.Path
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Handler
import android.os.Looper
import android.util.DisplayMetrics
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import kotlinx.coroutines.*
import java.nio.ByteBuffer

class FarmAccessibilityService : AccessibilityService() {

    companion object {
        var instance: FarmAccessibilityService? = null
        var mediaProjectionResultData: Intent? = null
        var mediaProjectionResultCode: Int = Activity.RESULT_OK
    }

    private val serviceScope = CoroutineScope(Dispatchers.Default + Job())
    private var isFarming = false

    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null
    private var screenWidth = 0
    private var screenHeight = 0
    private var screenDensity = 0

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        initializeScreenMetrics()
    }

    private fun initializeScreenMetrics() {
        val wm = getSystemService(WINDOW_SERVICE) as WindowManager
        val metrics = DisplayMetrics()
        @Suppress("DEPRECATION")
        wm.defaultDisplay.getRealMetrics(metrics)
        screenWidth = maxOf(metrics.widthPixels, metrics.heightPixels)
        screenHeight = minOf(metrics.widthPixels, metrics.heightPixels)
        screenDensity = metrics.densityDpi
    }

    fun startFarmingLoop() {
        if (isFarming) return
        val data = mediaProjectionResultData ?: return

        setupMediaProjection(data)
        isFarming = true

        serviceScope.launch {
            while (isFarming) {
                val bitmap = captureScreen()
                if (bitmap != null) {
                    analyzeAndExecuteAction(bitmap)
                    bitmap.recycle()
                }
                delay(1500L)
            }
        }
    }

    fun stopFarmingLoop() {
        isFarming = false
        tearDownMediaProjection()
    }

    private fun setupMediaProjection(data: Intent) {
        val projectionManager = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        mediaProjection = projectionManager.getMediaProjection(mediaProjectionResultCode, data)

        // Android 14+ requires registering a callback before creating VirtualDisplay
        mediaProjection?.registerCallback(object : MediaProjection.Callback() {
            override fun onStop() {
                stopFarmingLoop()
            }
        }, Handler(Looper.getMainLooper()))

        imageReader = ImageReader.newInstance(screenWidth, screenHeight, PixelFormat.RGBA_8888, 2)
        virtualDisplay = mediaProjection?.createVirtualDisplay(
            "LimbusScreenCapture",
            screenWidth,
            screenHeight,
            screenDensity,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            imageReader?.surface,
            null,
            null
        )
    }

    private fun tearDownMediaProjection() {
        virtualDisplay?.release()
        imageReader?.close()
        mediaProjection?.stop()
        virtualDisplay = null
        imageReader = null
        mediaProjection = null
    }

    private fun captureScreen(): Bitmap? {
        val image = imageReader?.acquireLatestImage() ?: return null
        val planes = image.planes
        val buffer: ByteBuffer = planes[0].buffer
        val pixelStride = planes[0].pixelStride
        val rowStride = planes[0].rowStride
        val rowPadding = rowStride - pixelStride * screenWidth

        val bitmap = Bitmap.createBitmap(
            screenWidth + rowPadding / pixelStride,
            screenHeight,
            Bitmap.Config.ARGB_8888
        )
        bitmap.copyPixelsFromBuffer(buffer)
   
