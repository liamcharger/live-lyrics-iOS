//
//  StoreKitManager.swift
//  Lyrics
//
//  Created by Liam Willey on 12/7/23.
//

import Foundation
import StoreKit
import SwiftUI

public enum StoreError: Error {
    case failedVerification
}

class StoreKitManager: ObservableObject {
    @Published var storeProducts: [Product] = []
    @Published var purchasedProducts: [Product] = []
    
    var updateListenerTask: Task<Void, Error>? = nil
    
    @AppStorage("hasPurchasedRemoveAds") var hasPurchasedRemoveAds: Bool = false
    
    private let productDict: [String: String]
    
    init() {
        if let plistPath = Bundle.main.path(forResource: "InAppPurchases", ofType: "plist"),
           let plist = FileManager.default.contents(atPath: plistPath) {
            productDict = (try? PropertyListSerialization.propertyList(from: plist, format: nil) as? [String: String]) ?? [:]
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
                    let transaction = try self.checkVerified(result)
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
            hasPurchasedRemoveAds = {
                return !storeProducts.isEmpty
            }()
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
        var purchasedCourses: [Product] = []
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if let product = storeProducts.first(where: { $0.id == transaction.productID }) {
                    self.hasPurchasedRemoveAds = true
                    purchasedCourses.append(product)
                }
            } catch {
                print("Transaction failed verification")
            }
        }
        
        self.purchasedProducts = purchasedCourses
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
        return purchasedProducts.contains(product)
    }
}
