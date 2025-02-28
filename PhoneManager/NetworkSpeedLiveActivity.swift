import SwiftUI
import ActivityKit
import WidgetKit

struct NetworkSpeedAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var uploadSpeed: Double
        var downloadSpeed: Double
    }
}

@available(iOS 16.1, *)
struct NetworkSpeedLiveActivityView: View {
    let context: ActivityViewContext<NetworkSpeedAttributes>
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Label {
                    Text(formatSpeed(context.state.uploadSpeed))
                } icon: {
                    Image(systemName: "arrow.up")
                }
                
                Label {
                    Text(formatSpeed(context.state.downloadSpeed))
                } icon: {
                    Image(systemName: "arrow.down")
                }
            }
            .font(.system(size: 13, weight: .medium))
            
            Spacer()
            
            Image(systemName: "wave.3.right")
                .font(.system(size: 24))
        }
        .padding(.horizontal)
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
} 