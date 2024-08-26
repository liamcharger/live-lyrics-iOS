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
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
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
                LazyVGrid(columns: columns) {
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
    var title: Text {
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
    var icon: String {
        switch sortItem {
        case .noSelection:
            return "circle"
        case .artist:
            return "person"
        case .key:
            return "pianokeys"
        case .name:
            return "textformat.size"
        case .tags:
            return "tag"
        case .dateCreated:
            return "calendar"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                Spacer()
                if sortItem == sortSelection {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.medium))
                        .foregroundColor(.gray)
                }
            }
            title
                .font(.system(size: 18).weight(.semibold))
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(Material.thin)
        .foregroundColor(.primary)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    SortView(isPresented: .constant(true), sortSelection: .constant(.noSelection))
}
