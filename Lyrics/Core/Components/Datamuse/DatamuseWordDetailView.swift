//
//  DatamuseWordDetailView.swift
//  Lyrics
//
//  Created by Liam Willey on 8/20/24.
//

import SwiftUI
import TipKit

enum DatamuseWordType: String {
    case synonymn = "synonym_title"
    case rhyme = "rhyme_title"
    case antonymn = "antonym_title"
    case related = "related_title"
    case startsWith = "startsWith_title"
}

struct DatamuseWordDetailView: View {
    @ObservedObject var datamuseService = WordService.shared
    
    @Environment(\.presentationMode) var presMode
    
    @State var wordToCopy: DatamuseWord?
    
    let selectedWord = SongDetailViewModel.shared.selectedText
    let type: DatamuseWordType
    let pasteboard = UIPasteboard.general
    let columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var groupedWords: [Int: [Rhyme]] {
        Dictionary(grouping: datamuseService.rhymes, by: { $0.syllables })
    }
    var topResults: [Rhyme] {
        datamuseService.rhymes.filter { $0.score >= 300 }.sorted(by: { $0.score > $1.score })
    }
    
    func wordRowView(word: String, score: Int) -> some View {
        return Button {
            pasteboard.string = word
            wordToCopy = DatamuseWord(word: word, score: score)
        } label: {
            DatamuseWordRowView(word: word, selectedWord: $wordToCopy)
        }
        .showDatamuseCopyTip()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString(type.rawValue, comment: ""))
                        .font(.system(size: 26, weight: .bold))
                    Text(selectedWord)
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                Spacer()
                CloseButton {
                    presMode.wrappedValue.dismiss()
                }
            }
            .padding()
            Divider()
            if datamuseService.isLoadingWords || (type == .rhyme ? (datamuseService.rhymes.isEmpty) : (datamuseService.words.isEmpty)) {
                FullscreenMessage(imageName: "circle.slash", title: "Hmm, we couldn't find any results for that word.", isLoading: datamuseService.isLoadingWords)
            } else {
                ScrollView {
                    VStack(alignment: .leading) {
                        if type == .rhyme {
                            if !topResults.isEmpty {
                                Section(header: Text("Top Results").font(.headline)) {
                                    LazyVGrid(columns: columns) {
                                        ForEach(topResults.filter({ $0.word != selectedWord }), id: \.word) { rhyme in
                                            wordRowView(word: rhyme.word, score: rhyme.score)
                                        }
                                    }
                                }
                            }
                            ForEach(Array(groupedWords.keys.sorted()), id: \.self) { syllables in
                                Section(header: Text("\(syllables) Syllable\(syllables == 1 ? "" : "s")").font(.headline).padding(topResults.isEmpty ? [] : [.top])) {
                                    LazyVGrid(columns: columns) {
                                        ForEach(groupedWords[syllables]!.sorted(by: { $0.score > $1.score }).filter({ $0.word != selectedWord }), id: \.word) { rhyme in
                                            wordRowView(word: rhyme.word, score: rhyme.score)
                                        }
                                    }
                                }
                            }
                        } else {
                            LazyVGrid(columns: columns) {
                                ForEach(datamuseService.words.sorted(by: { $0.score > $1.score }).filter({ $0.word != selectedWord })) { word in
                                    wordRowView(word: word.word, score: word.score)
                                }
                            }
                        }
                        Text("Powered by Datamuse")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding(.top)
                    }
                    .multilineTextAlignment(.center)
                    .padding([.horizontal,
                              .bottom])
                    .padding(.top, 14)
                }
            }
        }
    }
}
