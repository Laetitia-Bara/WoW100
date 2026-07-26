package fr.cosmoslty.wow100

import android.content.Intent
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "fr.cosmoslty.wow100/deep_links"
    private var deepLinkChannel: MethodChannel? = null
    private var initialLink: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.enableEdgeToEdge(window)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        initialLink = intent?.dataString
        deepLinkChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).also { channel ->
            channel.setMethodCallHandler { call, result ->
                if (call.method == "getInitialLink") {
                    result.success(initialLink)
                } else {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)

        val link = intent.dataString ?: return
        initialLink = link
        deepLinkChannel?.invokeMethod("onLink", link)
    }
}
