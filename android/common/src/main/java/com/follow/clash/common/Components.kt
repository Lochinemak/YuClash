package com.follow.clash.common

import android.content.ComponentName

object Components {
    const val PACKAGE_NAME = "com.follow.clash"

    // The Flutter side names its MethodChannels after the app's real
    // applicationId (`packageName` in lib/common/constant.dart), which is
    // independent of this Kotlin source tree's package name above.
    const val FLUTTER_CHANNEL_NAMESPACE = "com.yucloud.clash"

    val mainActivity =
        ComponentName(GlobalState.packageName, "${PACKAGE_NAME}.MainActivity")

    val quickActionActivity =
        ComponentName(GlobalState.packageName, "${PACKAGE_NAME}.QuickActionActivity")

    val serviceBroadcastReceiver =
        ComponentName(GlobalState.packageName, "${PACKAGE_NAME}.ServiceBroadcastReceiver")
}
