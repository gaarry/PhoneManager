import SwiftUI
import CoreTelephony
import SystemConfiguration

struct DetailInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .medium))
        }
        .padding(.vertical, 6)
    }
}

struct DetailView: View {
    @StateObject private var deviceManager = DeviceManager.shared
    let category: String
    
    private func getDetailInfo() -> [(String, String)] {
        switch category {
        case "基本信息":
            return DeviceManager.shared.getBasicDeviceInfo()
        case "处理器信息":
            return DeviceManager.shared.getProcessorInfo()
        case "内存信息":
            return DeviceManager.shared.getMemoryInfo()
        case "屏幕信息":
            return [
                ("屏幕尺寸", "6.1英寸"),
                ("分辨率", "\(Int(UIScreen.main.bounds.width))x\(Int(UIScreen.main.bounds.height))"),
                ("像素密度", "460 PPI"),
                ("屏幕技术", "OLED"),
                ("刷新率", "120Hz"),
                ("亮度", "2000尼特"),
                ("对比度", "2000000:1"),
                ("色彩范围", "P3广色域"),
                ("触摸采样", "240Hz"),
                ("HDR支持", "是"),
                ("原彩显示", "支持"),
                ("永远显示", "支持")
            ]
        case "网络信息":
            return deviceManager.getNetworkInfo()
        case "电池信息":
            return DeviceManager.shared.getBatteryInfo()
        case "存储信息":
            return DeviceManager.shared.getDetailedStorageInfo()
        default:
            return []
        }
    }
    
    var body: some View {
        List {
            ForEach(getDetailInfo(), id: \.0) { item in
                DetailInfoRow(title: item.0, value: item.1)
            }
        }
        .navigationTitle(category)
    }
} 