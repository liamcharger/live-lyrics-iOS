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
}

class StoreKitManager: ObservableObject {
    @Published var storeProducts: [Product] = []
    @Published var purchasedProducts: [Product] = []
    @Published var activeSubscriptions: [Product] = []
    
    @ObservedObject var authViewModel = AuthViewModel.shared
    
    var updateListenerTask: Task<Void, Error>? = nil
    
    private let productDict: [String : String]
    
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
        } else {
            // FIXME: see #38
//            authViewModel.showAds(true)
        }
        
        if !activeSubscriptions.isEmpty {
            authViewModel.updateProStatus(true)
        } else {
            authViewModel.updateProStatus(false)
        }
    }
    
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
