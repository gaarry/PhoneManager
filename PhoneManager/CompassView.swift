import SwiftUI
import CoreLocation

struct CompassView: View {
    @StateObject private var compassHeading = CompassHeading()
    
    var body: some View {
        VStack {
            Capsule()
                .frame(width: 5, height: 50)
                .foregroundColor(.red)
                .padding(.bottom, 100)
            
            ZStack {
                ForEach(0..<360/30, id: \.self) { i in
                    Rectangle()
                        .frame(width: 2, height: 10)
                        .offset(y: -150)
                        .rotationEffect(.degrees(Double(i) * 30))
                }
                
                ForEach(0..<360/90, id: \.self) { i in
                    Rectangle()
                        .frame(width: 2, height: 20)
                        .offset(y: -150)
                        .rotationEffect(.degrees(Double(i) * 90))
                }
                
                Text("N")
                    .offset(y: -130)
                Text("E")
                    .offset(x: 130)
                Text("S")
                    .offset(y: 130)
                Text("W")
                    .offset(x: -130)
            }
            .rotationEffect(.degrees(-compassHeading.degrees))
            
            Text("\(Int(compassHeading.degrees))°")
                .font(.largeTitle)
                .padding(.top, 50)
        }
        .navigationTitle("指南针")
    }
}

class CompassHeading: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var degrees: Double = 0
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.headingFilter = 1
        locationManager.delegate = self
        locationManager.startUpdatingHeading()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        degrees = newHeading.magneticHeading
    }
} 