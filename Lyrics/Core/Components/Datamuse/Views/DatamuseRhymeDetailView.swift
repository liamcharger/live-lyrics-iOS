//
//  DatamuseRhymeDetailView.swift
//  Lyrics
//
//  Created by Liam Willey on 8/20/24.
//

import SwiftUI

struct DatamuseRhymeDetailView: View {
    @ObservedObject var datamuseService = DatamuseService.shared
    
    @Binding var isDisplayed: Bool
    @Binding var selectedWord: String
    
    let columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var groupedRhymes: [Int: [DatamuseRhyme]] {
        Dictionary(grouping: datamuseService.rhymes, by: { $0.numSyllables })
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rhymes for")
                        .font(.system(size: 26, weight: .bold))
                    Text(selectedWord)
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                        .lineLimit(4)
                }
                Spacer()
                SheetCloseButton {
                    isDisplayed = false
                }
            }
            .padding()
            Divider()
            if datamuseService.isLoadingRhymes {
                Spacer()
                ProgressView("Loading")
                Spacer()
            } else {
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(Array(groupedRhymes.keys.sorted()), id: \.self) { syllables in
                            Section(header: Text("\(syllables) Syllable\(syllables == 1 ? "" : "s")").font(.headline).padding(syllables == 1 ? [] : [.top])) {
                                LazyVGrid(columns: columns) {
                                    ForEach(groupedRhymes[syllables]!.sorted(by: { $0.score > $1.score })) { rhyme in
                                        Text(rhyme.word)
                                            .padding(12)
                                            .frame(maxWidth: .infinity)
                                            .background(rhyme.score == 100 ? Color.blue : Color.materialRegularGray)
                                            .foregroundColor(rhyme.score == 100 ? Color.white : Color.primary)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
}
