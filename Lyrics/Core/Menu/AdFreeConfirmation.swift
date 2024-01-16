//
//  AdFreeConfirmationView.swift
//  Lyrics
//
//  Created by Liam Willey on 1/16/24.
//

import SwiftUI
import StoreKit
import FASwiftUI

struct AdFreeConfirmationView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @EnvironmentObject var storeKitManager: StoreKitManager
    
    @Binding var isDisplayed: Bool
    
    func purchaseSubscription(product: Product) async {
        do {
            if try await storeKitManager.purchase(product) != nil {
                isDisplayed = false
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    var body: some View {
        ForEach(storeKitManager.storeProducts, id: \.self) { product in
            VStack(spacing: 10) {
                SheetCloseButton(isPresented: $isDisplayed)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding()
                Spacer()
                FAText(iconName: "money-bill", size: 44)
                VStack {
                    Text("Ad-Free Access")
                        .font(.system(size: 32, design: .rounded).weight(.bold))
                        .multilineTextAlignment(.leading)
                    Text("One-Time Purchase • \(product.displayPrice)")
                        .foregroundColor(.gray)
                }
                Button {
                    Task {
                        await purchaseSubscription(product: product)
                    }
                } label: {
                    Text("Confirm Purchase")
                        .modifier(NavButtonViewModifier())
                        .padding()
                }
                Spacer()
                Spacer()
            }
        }
    }
}

#Preview {
    AdFreeConfirmationView(isDisplayed: .constant(true))
}
