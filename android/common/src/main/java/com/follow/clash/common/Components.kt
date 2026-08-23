package com.follow.clash.common

import android.content.ComponentName

object Components {
    const val CHANNEL_PREFIX = "com.yucloud.clash"
    private const val COMPONENT_PACKAGE_NAME = "com.follow.clash"

    val mainActivity =
        ComponentName(GlobalState.packageName, "${COMPONENT_PACKAGE_NAME}.MainActivity")

    val quickActionActivity =
        ComponentName(GlobalState.packageName, "${COMPONENT_PACKAGE_NAME}.QuickActionActivity")

    val serviceBroadcastReceiver =
        ComponentName(GlobalState.packageName, "${COMPONENT_PACKAGE_NAME}.ServiceBroadcastReceiver")
}
