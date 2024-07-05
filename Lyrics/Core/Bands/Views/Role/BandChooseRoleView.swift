//
//  BandChooseRoleView.swift
//  Lyrics
//
//  Created by Liam Willey on 7/3/24.
//

import SwiftUI
import BottomSheet

struct BandChooseRoleView: View {
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject var bandsViewModel = BandsViewModel.shared
    
    let member: BandMember
    let band: Band
    
    @Binding var selectedRole: BandRole?
    
    @State var name = ""
    @State var icon: String?
    
    @State var showChooseIconSheet = false
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                HStack {
                    Text("Create a Role")
                        .font(.system(size: 28, design: .rounded).weight(.bold))
                    Spacer()
                    Button(action: {dismiss()}) {
                        Image(systemName: "xmark")
                            .imageScale(.medium)
                            .padding(12)
                            .font(.body.weight(.semibold))
                            .foregroundColor(.primary)
                            .background(Material.regular)
                            .clipShape(Circle())
                    }
                    Button(action: {
                        // TODO: replace with function that adds the custom role to a collection, so the role can be reused with other members and can be associated with a variation
                        bandsViewModel.saveRole(to: member, for: band, role: BandRole(name: name, icon: icon, color: nil))
                    }) {
                        Text("Save")
                            .padding(12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .font(.body.weight(.semibold))
                            .clipShape(Capsule())
                    }
                }
                .padding()
                VStack(spacing: 0) {
                    Spacer()
                    Button {
                        showChooseIconSheet = true
                    } label: {
                        Circle()
                            .frame(minWidth: geo.size.width / 3.2, maxWidth: geo.size.width / 3.2)
                            .fixedSize()
                            .overlay {
                                FAText(iconName: icon ?? "face-smile", size: 50)
                                    .foregroundColor(.white)
                                    .opacity(0.7)
                            }
                    }
                    TextField("Role Name", text: $name)
                        .padding(12)
                        .padding(.horizontal, 4)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .overlay {
                            Capsule()
                                .stroke(Color(.systemBackground), lineWidth: 4)
                        }
                        .offset(y: 35)
                        .frame(maxWidth: 190)
                    Spacer()
                }
            }
            .background(
                Color(.systemBackground)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                if gesture.translation.height > 0 {
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                }
                            }
                    )
            )
        }
        .bottomSheet(isPresented: $showChooseIconSheet) {
            BandChooseRoleIcon(selectedIcon: $icon)
        }
    }
}
