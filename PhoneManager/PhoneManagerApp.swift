//
//  PhoneManagerApp.swift
//  PhoneManager
//
//  Created by gary on 2025/2/28.
//

import SwiftUI
import UIKit

@main
struct PhoneManagerApp: App {
    init() {
        // 启用电池监控
        UIDevice.current.isBatteryMonitoringEnabled = true
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
