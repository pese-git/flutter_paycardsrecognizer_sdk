/*
 * Copyright [2021] Sergey Penkovsky <sergey.penkovsky@gmail.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.cards.pay.paycardsrecognizer.sdk.flutter_paycardsrecognizer_sdk

import android.app.Activity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result

import cards.pay.paycardsrecognizer.sdk.ScanCardIntent

import android.content.Intent
import io.flutter.plugin.common.PluginRegistry
import android.util.Log
import cards.pay.paycardsrecognizer.sdk.Card
import cards.pay.paycardsrecognizer.sdk.ui.ScanCardActivity


/** FlutterPaycardsrecognizerSdkPlugin */
class FlutterPaycardsrecognizerSdkPlugin : FlutterPlugin,
    ActivityAware, PluginRegistry.ActivityResultListener {
    companion object {
        val REQUEST_CODE_SCAN_CARD: Int = 1
    }

    private var mResult: Result? = null

    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel =
            MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_paycardsrecognizer_sdk")

    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }


    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (mResult == null) {
            return false
        }
        if (requestCode == REQUEST_CODE_SCAN_CARD) {
            if (resultCode == Activity.RESULT_OK) {
                val card: Card? = data?.getParcelableExtra(ScanCardIntent.RESULT_PAYCARDS_CARD)
                if (card != null) {
                    val cardData = """
                Card number: ${card.cardNumberRedacted}
                Card holder: ${card.cardHolderName.toString()}
                Card expiration date: ${card.expirationDate}
                """.trimIndent()
                    Log.i("flutter_paycards", "Card info: $cardData")
                    val response: MutableMap<String, Any?> = HashMap()
                    response["cardHolderName"] = card.cardHolderName
                    response["cardNumber"] = card.cardNumber
                    if (card.expirationDate != null) {
                        response["expiryMonth"] = card.expirationDate!!.substring(0, 2)
                        response["expiryYear"] = card.expirationDate!!.substring(3, 5)
                    }
                    mResult?.success(response)
                }
            } else if (resultCode == Activity.RESULT_CANCELED) {
                mResult?.error("CANCELED", null, null)
                Log.i("flutter_paycards", "Scan canceled")
            } else {
                mResult?.error("SCAN_FAILED", null, null)
                Log.i("flutter_paycards", "Scan failed")
            }
            mResult = null
            return true
        }
        return false
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        channel.setMethodCallHandler { call: MethodCall, result: Result ->
            onMethodCall(binding.activity, call, result)
        }
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        channel.setMethodCallHandler(null)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        channel.setMethodCallHandler { call: MethodCall, result: Result ->
            onMethodCall(binding.activity, call, result)
        }
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        channel.setMethodCallHandler(null)
    }

    private fun onMethodCall(activity: Activity, call: MethodCall, result: Result) {
        if (mResult != null) {
            result.error("ALREADY_ACTIVE", "Scan card is already active", null)
            return
        }
        mResult = result
        if (call.method.equals("startRecognizer")) {
            val scanIntent = Intent(activity, ScanCardActivity::class.java)
            activity.startActivityForResult(scanIntent, REQUEST_CODE_SCAN_CARD)
        } else {
            result.notImplemented()
        }
        /*
        if (call.method == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        } else {
            result.notImplemented()
        }
        */
    }
}
