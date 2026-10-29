package com.example.winrelay

import android.content.Context
import android.view.inputmethod.InputMethodManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "winrelay/ime").setMethodCallHandler { call, result ->
            when (call.method) {
                // Lets the user switch keyboards (e.g. to a Chinese IME) without
                // leaving the control screen.
                "showPicker" -> {
                    val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
                    imm.showInputMethodPicker()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
