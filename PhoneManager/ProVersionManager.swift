import Foundation
import StoreKit

class ProVersionManager: ObservableObject {
    @Published var isPro = false
    @Published var showProAlert = false
    
    func upgradeToProVersion() {
        // 这里应该实现实际的应用内购买逻辑
        showProAlert = true
    }
} 