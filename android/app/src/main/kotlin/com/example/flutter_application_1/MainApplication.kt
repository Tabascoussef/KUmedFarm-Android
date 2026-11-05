package com.example.flutter_application_1

import android.app.Application
import com.yandex.mapkit.MapKitFactory

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        MapKitFactory.setApiKey("2f1a4c00-a64f-405d-b77c-3900a5a793ff")
    }
}
