//
//  ContentView.swift
//  PhoneManager
//
//  Created by gary on 2025/2/28.
//

import SwiftUI
import UIKit
import CoreMotion

struct DeviceInfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.green)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                if !value.isEmpty {
                    Text(value)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct ContentView: View {
    @StateObject private var deviceManager = DeviceManager.shared
    
    // 获取电池信息
    private var batteryInfo: String {
        let batteryLevel = Int(deviceManager.batteryLevel * 100)
        let batteryState = deviceManager.batteryState == .charging ? "充电中" : "正常"
        return "\(batteryLevel)% · \(batteryState)"
    }
    
    // 获取存储信息
    private var storageInfo: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB]
        formatter.countStyle = .binary
        return "\(formatter.string(fromByteCount: deviceManager.totalSpace)) · 可用 \(formatter.string(fromByteCount: deviceManager.freeSpace))"
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("设备信息")
                                .font(.system(size: 24, weight: .bold))
                            Text(deviceManager.deviceModel)
                                .font(.system(size: 15))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Image(systemName: "iphone.gen3")
                            .font(.system(size: 40))
                            .foregroundColor(.green)
                    }
                    .padding(.vertical, 10)
                }
                
                Section(header: Text("总览").textCase(.uppercase)) {
                    NavigationLink(destination: DetailView(category: "基本信息")) {
                        DeviceInfoRow(icon: "iphone", title: "基本信息", value: deviceManager.deviceModel)
                    }
                    NavigationLink(destination: DetailView(category: "处理器信息")) {
                        DeviceInfoRow(icon: "cpu", title: "处理器信息", value: deviceManager.getProcessorInfo().first?.1 ?? "")
                    }
                    NavigationLink(destination: DetailView(category: "内存信息")) {
                        DeviceInfoRow(icon: "memorychip", title: "内存信息", value: deviceManager.getMemoryInfo().first?.1 ?? "")
                    }
                    NavigationLink(destination: DetailView(category: "屏幕信息")) {
                        let screenSize = UIScreen.main.bounds.size
                        DeviceInfoRow(icon: "display", title: "屏幕信息", 
                                    value: String(format: "%.1f″ · %dx%d", 
                                                screenSize.height / 163,  // 转换为英寸
                                                Int(screenSize.width * UIScreen.main.scale),
                                                Int(screenSize.height * UIScreen.main.scale)))
                    }
                    NavigationLink(destination: DetailView(category: "网络信息")) {
                        DeviceInfoRow(icon: "wifi", title: "网络信息", value: "Wi-Fi · 蜂窝网络")
                    }
                }
                
                Section(header: Text("系统").textCase(.uppercase)) {
                    DeviceInfoRow(icon: "battery.100", title: "电池信息", value: batteryInfo)
                    DeviceInfoRow(icon: "apple.logo", title: "操作系统", value: "iOS \(UIDevice.current.systemVersion)")
                    DeviceInfoRow(icon: "externaldrive", title: "存储信息", value: storageInfo)
                }
                
                Section(header: Text("诊断工具").textCase(.uppercase)) {
                    NavigationLink(destination: SensorView()) {
                        DeviceInfoRow(icon: "sensor", title: "传感器", value: "加速度计 · 陀螺仪 · 磁力计")
                    }
                    NavigationLink(destination: CompassView()) {
                        DeviceInfoRow(icon: "location.north.circle", title: "指南针", value: "电子罗盘 · 倾斜角度")
                    }
                    NavigationLink(destination: NetworkStatsView()) {
                        DeviceInfoRow(icon: "chart.bar", title: "流量统计", value: "实时监控 · 数据分析")
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Info button action
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.green)
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
