//
//  StoreKitManager.swift
//  Lyrics
//
//  Created by Liam Willey on 12/7/23.
//

import SwiftUI
import StoreKit

public enum StoreError: Error {
    case failedVerification
    case missingReceipt
}

class StoreKitManager: ObservableObject {
    @Published var storeProducts: [Product] = []
    @Published var purchasedProducts: [Product] = []
    @Published var activeSubscriptions: [Product] = []
    
    @ObservedObject var authViewModel = AuthViewModel.shared
    
    var updateListenerTask: Task<Void, Error>? = nil
    
    private let productDict: [String : String]
    private let sharedSecret = "dc7b1a5b8d7e4165b7fb90553d48f08c"
    
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
            await validateReceiptWithApple()
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
    
    func validateReceiptWithApple() async {
        guard let encodedReceipt = base64EncodedReceipt() else {
            print("No receipt available")
            return
        }
        
        let receiptRequestData: [String: Any] = ["receipt-data": encodedReceipt, "password": sharedSecret]
        
        do {
            // First try the production validation
            let isValidProduction = try await validateWithAppleServer(receiptRequestData: receiptRequestData, urlString: "https://buy.itunes.apple.com/verifyReceipt")
            
            if !isValidProduction {
                // If the production fails, try sandbox
                let isValidSandbox = try await validateWithAppleServer(receiptRequestData: receiptRequestData, urlString: "https://sandbox.itunes.apple.com/verifyReceipt")
                
                if !isValidSandbox {
                    print("Receipt validation failed")
                }
            }
        } catch {
            print("Error validating receipt: \(error.localizedDescription)")
        }
    }
    
    func validateWithAppleServer(receiptRequestData: [String: Any], urlString: String) async throws -> Bool {
        guard let url = URL(string: urlString) else {
            authViewModel.updateProStatus(false)
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonData = try JSONSerialization.data(withJSONObject: receiptRequestData, options: [])
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("Invalid response from Apple")
            return false
        }
        
        if let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let response = handleAppleReceiptResponse(response: jsonResponse)
            
            if !response {
                authViewModel.updateProStatus(false)
            }
        }
        
        authViewModel.updateProStatus(false)
        return false
    }
    
    func handleAppleReceiptResponse(response: [String: Any]) -> Bool {
        if let status = response["status"] as? Int {
            // Status code 0 means the receipt is valid
            if status == 0 {
                // Check if the receipt contains a valid subscription or in-app purchase
                if let latestReceiptInfo = response["latest_receipt_info"] as? [[String: Any]] {
                    // Iterate through the receipt info and find the active subscription
                    for receiptInfo in latestReceiptInfo {
                        if let productId = receiptInfo["product_id"] as? String {
                            if productDict.values.contains(productId) {
                                // Receipt contains a valid subscription or in-app purchase
                                authViewModel.updateProStatus(true)
                                return true
                            }
                        }
                    }
                }
                return true
            } else {
                print("Receipt validation failed with status code: \(status)")
            }
        }
        return false
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
