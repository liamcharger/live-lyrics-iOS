//
//  SortView.swift
//  Lyrics
//
//  Created by Liam Willey on 1/2/24.
//

import SwiftUI

struct SortView: View {
    @ObservedObject var sortViewModel = SortViewModel.shared
    
    @Binding var isPresented: Bool
    @Binding var sortSelection: SortSelectionEnum
    
    private let sortOptions: [SortSelectionEnum] = [.noSelection, .artist, .key, .name, .tags, .dateCreated]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Sort By")
                    .font(.system(size: 26, design: .rounded).weight(.bold))
                Spacer()
                SheetCloseButton {
                    isPresented = false
                }
            }
            .padding()
            Divider()
            ScrollView {
                VStack {
                    ForEach(sortOptions, id: \.self) { sortItem in
                        Button {
                            sortSelection = sortItem
                            sortViewModel.saveToUserDefaults(sortSelection: sortItem)
                        } label: {
                            SortRowView(sortSelection: $sortSelection, sortItem: sortItem)
                        }
                    }
                }
                .padding()
            }
        }
        .onAppear {
            sortViewModel.loadFromUserDefaults { sortItem in
                sortSelection = sortItem
            }
        }
    }
}

struct SortRowView: View {
    @Binding var sortSelection: SortSelectionEnum
    
    let sortItem: SortSelectionEnum
    
    var body: some View {
        HStack {
            HStack {
                Group {
                    switch sortItem {
                    case .noSelection:
                        Text("None")
                    case .artist:
                        Text("Artist")
                    case .key:
                        Text("Key")
                    case .name:
                        Text("Name")
                    case .tags:
                        Text("Tags")
                    case .dateCreated:
                        Text("Date Created")
                    }
                }
                .multilineTextAlignment(.leading)
                Spacer()
                if sortItem == sortSelection {
                    FAText(iconName: "check", size: 18)
                }
            }
            .padding()
            .background(Material.regular)
            .foregroundColor(.primary)
            .clipShape(Capsule())
        }
    }
}

#Preview {
    SortView(isPresented: .constant(true), sortSelection: .constant(.noSelection))
}
