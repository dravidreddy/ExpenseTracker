package com.stormbreaker.expensetracker

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Prevent recent-apps task switcher from leaking financial screenshots
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}
