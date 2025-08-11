//
//  SongVariationEditView.swift
//  Lyrics
//
//  Created by Liam Willey on 4/19/24.
//

import SwiftUI
import BottomSheet

struct SongVariationEditView: View {
    @ObservedObject var songViewModel = SongViewModel.shared
    @ObservedObject var bandsViewModel = BandsViewModel.shared
    
    let song: Song
    let variation: SongVariation
    
    @Binding var isDisplayed: Bool
    
    @State var errorMessage = ""
    @State var title = ""
    
    @State var selectedRole: BandRole?
    
    @State var showError = false
    @State var showAddRoleSheet = false
    
    var isEmpty: Bool {
        title.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    func update() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isDisplayed = false
        }
        songViewModel.updateVariation(song: song, variation: variation, title: title, role: selectedRole)
    }
    
    init(song: Song, variation: SongVariation, isDisplayed: Binding<Bool>) {
        self.song = song
        self.variation = variation
        self._isDisplayed = isDisplayed
        self._title = State(initialValue: variation.title)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                Text("Edit Variation")
                    .font(.title.weight(.bold))
                Spacer()
                CloseButton {
                    isDisplayed = false
                }
            }
            .padding()
            Divider()
            ScrollView {
                VStack {
                    CustomTextField(text: $title, placeholder: NSLocalizedString("title", comment: ""), image: "character.cursor.ibeam")
                    Button {
                        showAddRoleSheet = true
                    } label: {
                        HStack {
                            Text(selectedRole?.name ?? "Add a Role")
                            Spacer()
                            FAText(iconName: selectedRole?.icon ?? "plus", size: 18)
                        }
                        .padding()
                        .background(Material.regular)
                        .clipShape(Capsule())
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
            Divider()
            Button(action: update) {
                Text("Save")
                    .frame(maxWidth: .infinity)
                    .modifier(NavButtonViewModifier())
            }
            .opacity(isEmpty ? 0.5 : 1.0)
            .disabled(isEmpty)
            .padding()
        }
        .bottomSheet(isPresented: $showAddRoleSheet, detents: [.medium(), .large()]) {
            BandMemberAddRoleView(member: nil, band: nil, selectedRole: $selectedRole)
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .cancel())
        }
        .onAppear {
            if let roleId = variation.roleId {
                selectedRole = bandsViewModel.memberRoles.first(where: { $0.id! == roleId })
            }
        }
    }
}
