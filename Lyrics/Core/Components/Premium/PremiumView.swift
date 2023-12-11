//
//  PremiumView.swift
//  Lyrics
//
//  Created by Liam Willey on 8/14/23.
//

import SwiftUI

//struct PremiumView: View {
//    @EnvironmentObject var viewModel: AuthViewModel
//    
//    var content: some View
//        
//        init(@ViewBuilder content: () -> Content) {
//            self.content = content()
//        }
//    
//    var body: some View {
//        ZStack {
//            content
//                .blur(radius: 25)
//                .disabled(true)
//            VStack(spacing: 35) {
//                VStack(spacing: 8) {
//                    Text("You've run into a Premium feature!")
//                        .multilineTextAlignment(.center)
//                        .font(.title.weight(.bold))
//                    Text("Subscribe to access it.")
//                }
//                VStack {
//                    Button {
//                        viewModel.updateSubStatus(subStatus: true) { success, errorMessage in
//                            if success {
//                                print("Success!")
//                            } else {
//                                //                                showError.toggle()
//                                //                                self.errorMessage = errorMessage
//                            }
//                        }
//                    } label: {
//                        Text("Subscribe")
//                            .padding(12)
//                            .background(.blue)
//                            .foregroundColor(.white)
//                            .clipShape(Capsule())
//                            .padding(.horizontal)
//                    }
//                }
//            }
//        }
//    }
//}
