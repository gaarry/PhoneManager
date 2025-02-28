import Foundation

enum Configuration {
    static func setupPermissions() {
        // 添加权限描述到主 Bundle 的 info dictionary
        var infoDictionary: [String: Any] = Bundle.main.infoDictionary ?? [:]
        
        // 添加权限描述
        infoDictionary["NSLocalNetworkUsageDescription"] = "需要访问本地网络以获取网络信息"
        infoDictionary["NSLocationWhenInUseUsageDescription"] = "需要访问位置信息以获取网络状态"
        infoDictionary["NSBluetoothAlwaysUsageDescription"] = "需要访问蓝牙以获取设备信息"
        infoDictionary["UIRequiresPersistentWiFi"] = true
        
        // 如果需要的话，还可以添加其他权限
    }
} 