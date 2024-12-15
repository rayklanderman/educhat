package com.example.educhat

import io.flutter.app.FlutterApplication
import androidx.multidex.MultiDex
import android.content.Context

class Application : FlutterApplication() {
    override fun attachBaseContext(base: Context) {
        super.attachBaseContext(base)
        MultiDex.install(this)
    }
}
