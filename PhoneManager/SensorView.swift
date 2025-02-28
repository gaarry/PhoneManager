import SwiftUI
import CoreMotion

struct SensorView: View {
    @StateObject private var motionManager = MotionManager()
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("实时传感器数据")
                        .font(.system(size: 24, weight: .bold))
                    Text("监测设备的运动状态和方向")
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 10)
            }
            
            Section(header: Text("加速度计").textCase(.uppercase)) {
                DetailInfoRow(title: "X轴加速度", value: String(format: "%.3f G", motionManager.accelerometer.x))
                DetailInfoRow(title: "Y轴加速度", value: String(format: "%.3f G", motionManager.accelerometer.y))
                DetailInfoRow(title: "Z轴加速度", value: String(format: "%.3f G", motionManager.accelerometer.z))
            }
            
            Section(header: Text("陀螺仪").textCase(.uppercase)) {
                DetailInfoRow(title: "X轴角速度", value: String(format: "%.2f °/s", motionManager.gyro.x))
                DetailInfoRow(title: "Y轴角速度", value: String(format: "%.2f °/s", motionManager.gyro.y))
                DetailInfoRow(title: "Z轴角速度", value: String(format: "%.2f °/s", motionManager.gyro.z))
            }
            
            Section(header: Text("磁力计").textCase(.uppercase)) {
                DetailInfoRow(title: "X轴磁场", value: String(format: "%.2f µT", motionManager.magnetometer.x))
                DetailInfoRow(title: "Y轴磁场", value: String(format: "%.2f µT", motionManager.magnetometer.y))
                DetailInfoRow(title: "Z轴磁场", value: String(format: "%.2f µT", motionManager.magnetometer.z))
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationBarTitleDisplayMode(.inline)
    }
}

class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    @Published var accelerometer = CMAcceleration()
    @Published var gyro = CMRotationRate()
    @Published var magnetometer = CMMagneticField()
    
    init() {
        startUpdates()
    }
    
    private func startUpdates() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
                guard let data = data else { return }
                self?.accelerometer = data.acceleration
            }
        }
        
        if motionManager.isGyroAvailable {
            motionManager.gyroUpdateInterval = 0.1
            motionManager.startGyroUpdates(to: .main) { [weak self] data, _ in
                guard let data = data else { return }
                self?.gyro = data.rotationRate
            }
        }
        
        if motionManager.isMagnetometerAvailable {
            motionManager.magnetometerUpdateInterval = 0.1
            motionManager.startMagnetometerUpdates(to: .main) { [weak self] data, _ in
                guard let data = data else { return }
                self?.magnetometer = data.magneticField
            }
        }
    }
    
    deinit {
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        motionManager.stopMagnetometerUpdates()
    }
} 