//
//  StoreKitManager.swift
//  Lyrics
//
//  Created by Liam Willey on 12/7/23.
//

import SwiftUI
import StoreKit
import FirebaseFunctions

public enum StoreError: Error {
    case failedVerification
    case missingReceipt
}

class StoreKitManager: ObservableObject {
    @Published var storeProducts: [Product] = []
    @Published var purchasedProducts: [Product] = []
    @Published var activeSubscriptions: [Product] = []
    
    @AppStorage("StoreKitManager.lastTimeFunctionsCalled") private var lastTimeFunctionsCalled: Double = 0
    
    @ObservedObject var authViewModel = AuthViewModel.shared
    
    var updateListenerTask: Task<Void, Error>? = nil
    
    private let productDict: [String : String]
    private let threeDaysInSeconds: TimeInterval = 3 * 24 * 60 * 60
    
    static let shared = StoreKitManager()
    
    init() {
        if let plistPath = Bundle.main.path(forResource: "InAppPurchases", ofType: "plist"),
           let plist = FileManager.default.contents(atPath: plistPath) {
            productDict = (try? PropertyListSerialization.propertyList(from: plist, format: nil) as? [String : String]) ?? [:]
        } else {
            productDict = [:]
        }
        
        updateListenerTask = listenForTransactions()
        
        Task {
            await requestProducts()
            await updateCustomerProductStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updateCustomerProductStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification")
                }
            }
        }
    }
    
    @MainActor
    func requestProducts() async {
        do {
            storeProducts = try await Product.products(for: productDict.values)
        } catch {
            print("Failed - error retrieving products \(error)")
        }
    }
    
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let signedType):
            return signedType
        }
    }
    
    @MainActor
    func updateCustomerProductStatus() async {
        var purchasedIaps: [Product] = []
        var activeSubscriptions: [Product] = []
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                if let product = storeProducts.first(where: { $0.id == transaction.productID }) {
                    if product.type == .nonConsumable {
                        purchasedIaps.append(product)
                    } else if product.type == .autoRenewable {
                        activeSubscriptions.append(product)
                    }
                }
            } catch {
                print("Transaction failed verification")
            }
        }
        
        self.purchasedProducts = purchasedIaps
        self.activeSubscriptions = activeSubscriptions
        
        if purchasedProducts.contains(where: { $0.id == "remove_ads" }) {
            authViewModel.showAds(false)
        }
        
        if !activeSubscriptions.isEmpty {
            authViewModel.updateProStatus(true)
        } else {
            if shouldCallFunctions() {
                validateReceipt()
            }
        }
    }
    
    // MARK: - Receipt Fetching and Apple Validation
    
    func fetchReceipt() -> Data? {
        if let receiptURL = Bundle.main.appStoreReceiptURL {
            do {
                let receiptData = try Data(contentsOf: receiptURL)
                return receiptData
            } catch {
                print("Error fetching receipt: \(error.localizedDescription)")
            }
            return getReceiptFromFirestore()
        }
        authViewModel.updateProStatus(false)
        return nil
    }
    
    func getReceiptFromFirestore() -> Data? {
        if let receipt = authViewModel.currentUser?.purchaseReceipt, let data = receipt.data(using: .utf8) {
            return Data(data)
        }
        return nil
    }
    
    func base64EncodedReceipt() -> String? {
        if let receiptData = fetchReceipt() {
            return receiptData.base64EncodedString(options: [])
        }
        return nil
    }
    
    func saveReceiptToFirestore() async {
        guard let encodedReceipt = base64EncodedReceipt() else {
            print("No receipt available or user not authenticated")
            return
        }
        
        authViewModel.saveReceiptToFirestore(encodedReceipt)
    }
    
    func validateReceipt() {
        let functions = Functions.functions()
        
        let parameters: [String: Any?] = [
            "receipt-data": base64EncodedReceipt()
        ]
        
        functions.httpsCallable("validateReceipt").call(parameters) { result, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            if let data = result?.data as? [String: Any], let isSubscribed = data["isSubscribed"] as? Bool {
                self.authViewModel.updateProStatus(isSubscribed)
            } else {
                _ = NSError(domain: "FirebaseFunctions", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unexpected result format"])
            }
            self.lastTimeFunctionsCalled = Date().timeIntervalSince1970
        }
    }
    
    private func shouldCallFunctions() -> Bool {
        let now = Date().timeIntervalSince1970
        let lastCalledDate = Date(timeIntervalSince1970: lastTimeFunctionsCalled)
        let timeIntervalSinceLastCall = now - lastCalledDate.timeIntervalSince1970
        return timeIntervalSinceLastCall < threeDaysInSeconds
    }
    
    // MARK: - Purchasing
    
    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verificationResult):
            let transaction = try checkVerified(verificationResult)
            await updateCustomerProductStatus()
            await transaction.finish()
            return transaction
        case .userCancelled, .pending:
            return nil
        default:
            return nil
        }
    }
    
    func isPurchased(_ product: Product) async throws -> Bool {
        if product.type == .nonConsumable {
            return purchasedProducts.contains(product)
        } else if product.type == .autoRenewable {
            return activeSubscriptions.contains(product)
        }
        return false
    }
}
