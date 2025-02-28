import SwiftUI
import Network
import CoreTelephony
import SystemConfiguration
import SystemConfiguration.CaptiveNetwork
import Darwin
import Foundation

struct NetworkStatsView: View {
    @StateObject private var networkMonitor = NetworkMonitor()
    @State private var todayUsage: Double = 0
    @State private var monthlyUsage: Double = 0
    @State private var showingResetAlert = false
    @State private var resetType: ResetType = .today
    
    enum ResetType {
        case today, month
    }
    
    var body: some View {
        List {
            Section(header: Text("实时流量")) {
                DetailInfoRow(title: "上传速度", value: formatSpeed(networkMonitor.uploadSpeed))
                DetailInfoRow(title: "下载速度", value: formatSpeed(networkMonitor.downloadSpeed))
            }
            
            Section(header: Text("今日流量").textCase(.uppercase)) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("上传")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Text(formatBytes(Double(networkMonitor.totalUpload)))
                            .font(.system(size: 17, weight: .medium))
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("下载")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Text(formatBytes(Double(networkMonitor.totalDownload)))
                            .font(.system(size: 17, weight: .medium))
                    }
                }
                .padding(.vertical, 8)
                
                Button(action: {
                    resetType = .today
                    showingResetAlert = true
                }) {
                    HStack {
                        Text("重置今日流量")
                            .foregroundColor(.red)
                        Spacer()
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.red)
                    }
                }
            }
            
            Section(header: Text("本月流量").textCase(.uppercase)) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("总计")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Text(formatBytes(monthlyUsage))
                            .font(.system(size: 17, weight: .medium))
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("日均")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Text(formatBytes(monthlyUsage / Double(Calendar.current.component(.day, from: Date()))))
                            .font(.system(size: 17, weight: .medium))
                    }
                }
                .padding(.vertical, 8)
                
                Button(action: {
                    resetType = .month
                    showingResetAlert = true
                }) {
                    HStack {
                        Text("重置本月流量")
                            .foregroundColor(.red)
                        Spacer()
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .navigationTitle("流量统计")
        .onAppear {
            // 添加通知观察者
            NotificationCenter.default.addObserver(
                forName: .init("UpdateNetworkStats"),
                object: nil,
                queue: .main) { notification in
                if let userInfo = notification.userInfo,
                   let today = userInfo["today"] as? Double,
                   let monthly = userInfo["monthly"] as? Double {
                    todayUsage = today
                    monthlyUsage = monthly
                }
            }
        }
        .alert(isPresented: $showingResetAlert) {
            Alert(
                title: Text("确认重置"),
                message: Text("确定要重置\(resetType == .today ? "今日" : "本月")流量统计吗？此操作不可撤销。"),
                primaryButton: .destructive(Text("重置")) {
                    resetStats()
                },
                secondaryButton: .cancel(Text("取消"))
            )
        }
    }
    
    private func formatSpeed(_ bytesPerSecond: Double) -> String {
        if bytesPerSecond < 1024 {
            return String(format: "%.1f B/s", bytesPerSecond)
        } else if bytesPerSecond < 1024 * 1024 {
            return String(format: "%.1f KB/s", bytesPerSecond / 1024)
        } else {
            return String(format: "%.1f MB/s", bytesPerSecond / (1024 * 1024))
        }
    }
    
    private func formatBytes(_ bytes: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    private func resetStats() {
        let defaults = UserDefaults.standard
        let today = formatDate(Date())
        
        switch resetType {
        case .today:
            // 重置今日流量
            defaults.removeObject(forKey: "networkStats_\(today)")
            networkMonitor.reset()
            
        case .month:
            // 重置本月流量
            let currentMonth = Calendar.current.component(.month, from: Date())
            let currentYear = Calendar.current.component(.year, from: Date())
            
            // 删除本月所有日期的数据
            for key in defaults.dictionaryRepresentation().keys {
                if key.hasPrefix("networkStats_") {
                    let dateString = String(key.dropFirst("networkStats_".count))
                    if let date = parseDate(dateString) {
                        let month = Calendar.current.component(.month, from: date)
                        let year = Calendar.current.component(.year, from: date)
                        if month == currentMonth && year == currentYear {
                            defaults.removeObject(forKey: key)
                        }
                    }
                }
            }
            
            // 重置当前显示的月度用量和今日流量
            monthlyUsage = 0
            networkMonitor.reset()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
}

class NetworkMonitor: ObservableObject {
    @Published var uploadSpeed: Double = 0
    @Published var downloadSpeed: Double = 0
    @Published var totalUpload: UInt64 = 0
    @Published var totalDownload: UInt64 = 0
    
    private var previousUpload: UInt64 = 0
    private var previousDownload: UInt64 = 0
    private var baselineUpload: UInt64 = 0
    private var baselineDownload: UInt64 = 0
    private var timer: Timer?
    private let queue = DispatchQueue(label: "com.networkmonitor")
    
    init() {
        // 从 UserDefaults 读取基准值
        let defaults = UserDefaults.standard
        baselineUpload = UInt64(defaults.integer(forKey: "baselineUpload"))
        baselineDownload = UInt64(defaults.integer(forKey: "baselineDownload"))
        startMonitoring()
    }
    
    private func startMonitoring() {
        updateCounters()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateNetworkStats()
        }
    }
    
    private func updateNetworkStats() {
        let previousUp = previousUpload
        let previousDown = previousDownload
        updateCounters()
        uploadSpeed = Double(totalUpload - previousUp)
        downloadSpeed = Double(totalDownload - previousDown)
    }
    
    private func updateCounters() {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return }
        defer { freeifaddrs(ifaddr) }
        
        var tempUpload: UInt64 = 0
        var tempDownload: UInt64 = 0
        
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            guard let interface = ptr?.pointee else { continue }
            let name = String(cString: interface.ifa_name)
            
            // 只统计 en0 (WiFi) 和 pdp_ip0 (蜂窝数据) 的流量
            if name == "en0" || name == "pdp_ip0" {
                var data = if_data()
                if interface.ifa_addr.pointee.sa_family == UInt8(AF_LINK) {
                    memcpy(&data, interface.ifa_data, MemoryLayout<if_data>.size)
                    tempUpload += UInt64(data.ifi_obytes)
                    tempDownload += UInt64(data.ifi_ibytes)
                }
            }
        }
        
        // 减去基准值得到实际的流量
        tempUpload = tempUpload > baselineUpload ? tempUpload - baselineUpload : 0
        tempDownload = tempDownload > baselineDownload ? tempDownload - baselineDownload : 0
        
        previousUpload = totalUpload
        previousDownload = totalDownload
        totalUpload = tempUpload
        totalDownload = tempDownload
        
        // 保存每日流量统计
        saveDailyStats()
    }
    
    private func saveDailyStats() {
        let defaults = UserDefaults.standard
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        
        // 保存今日流量，明确指定字典类型
        let dailyStats: [String: Any] = [
            "upload": self.totalUpload,
            "download": self.totalDownload,
            "date": today
        ]
        defaults.set(dailyStats, forKey: "networkStats_\(today)")
        
        // 更新 UI 显示的数据
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 获取今日流量
            let todayTotal = Double(self.totalUpload + self.totalDownload)
            
            // 获取本月流量
            var monthlyTotal: Double = 0
            let calendar = Calendar.current
            let currentMonth = calendar.component(.month, from: Date())
            let currentYear = calendar.component(.year, from: Date())
            
            for key in defaults.dictionaryRepresentation().keys {
                if key.hasPrefix("networkStats_") {
                    let dateString = String(key.dropFirst("networkStats_".count))
                    if let date = dateFormatter.date(from: dateString),
                       calendar.component(.month, from: date) == currentMonth,
                       calendar.component(.year, from: date) == currentYear,
                       let stats = defaults.dictionary(forKey: key) {
                        if let upload = stats["upload"] as? UInt64,
                           let download = stats["download"] as? UInt64 {
                            monthlyTotal += Double(upload + download)
                        }
                    }
                }
            }
            
            // 更新 NetworkStatsView 的状态
            NotificationCenter.default.post(
                name: .init("UpdateNetworkStats"), 
                object: nil, 
                userInfo: [
                    "today": todayTotal, 
                    "monthly": monthlyTotal
                ]
            )
        }
    }
    
    private func cleanOldStats() {
        let defaults = UserDefaults.standard
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date())!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // 清理旧的统计数据
        for key in defaults.dictionaryRepresentation().keys {
            if key.hasPrefix("networkStats_") {
                let dateString = String(key.dropFirst("networkStats_".count))
                if let date = dateFormatter.date(from: dateString),
                   date < thirtyDaysAgo {
                    defaults.removeObject(forKey: key)
                }
            }
        }
        
        // 如果上次重置时间超过30天，也重置基准值
        if let lastResetDateString = defaults.string(forKey: "lastResetDate"),
           let lastResetDate = dateFormatter.date(from: lastResetDateString),
           lastResetDate < thirtyDaysAgo {
            defaults.removeObject(forKey: "baselineUpload")
            defaults.removeObject(forKey: "baselineDownload")
            baselineUpload = 0
            baselineDownload = 0
        }
    }
    
    func reset() {
        // 更新基准值
        baselineUpload = totalUpload + baselineUpload
        baselineDownload = totalDownload + baselineDownload
        
        // 保存基准值到 UserDefaults
        let defaults = UserDefaults.standard
        defaults.set(baselineUpload, forKey: "baselineUpload")
        defaults.set(baselineDownload, forKey: "baselineDownload")
        
        // 重置计数器
        totalUpload = 0
        totalDownload = 0
        previousUpload = 0
        previousDownload = 0
        
        // 保存重置时间
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        defaults.set(dateFormatter.string(from: Date()), forKey: "lastResetDate")
    }
    
    deinit {
        timer?.invalidate()
    }
} 