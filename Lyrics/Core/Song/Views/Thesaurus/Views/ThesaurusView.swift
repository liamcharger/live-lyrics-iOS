//
//  ThesaurusView.swift
//  Lyrics
//
//  Created by Liam Willey on 6/26/23.
//

import SwiftUI
#if os(iOS)
import BottomSheet
#endif

struct ThesaurusView: View {
    @State private var word: String = ""
    @State private var synonyms: [String] = []
    @State var dictionaryEntry: DictionaryEntry?
    @State private var isLoading: Bool = false
    @State private var showResults: Bool = false
    
    private let apiKey = "15eb71a0b82c606cd20042d604b20634"
    private let baseURL = "https://words.bighugelabs.com/api/2"
    
    @Environment(\.presentationMode) var presMode
    @ObservedObject var viewModel = ThesarusViewModel()
    
    var nextView: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .padding()
            } else if !synonyms.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        //                        Text("Synonyms")
                        //                            .font(.title2.weight(.semibold))
                        //                            .padding(14)
                        ForEach(synonyms, id: \.self) { synonym in
                            HStack {
                                Text(synonym)
                                Spacer()
                            }
                            .padding(14)
                            .background(Material.regular)
                            .foregroundColor(Color("Color"))
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom)
                    VStack(alignment: .leading, spacing: 10) {
                        //                        Text("Rhymes & Off Rhymes")
                        //                            .font(.title2.weight(.semibold))
                        //                            .padding()
                        //                        ForEach(rhymes?.meanings ?? []) { meaning in
                        //                            HStack {
                        //                                Text("\(meaning.synonyms)")
                        //                                Spacer()
                        //                            }
                        //                            .padding()
                        //                            .background(Material.regular)
                        //                            .cornerRadius(10)
                        //                            .padding(.horizontal)
                        //                            .contextMenu {
                        //                                Button {
                        //                                    let pasteboard = UIPasteboard.general
                        //                                    pasteboard.string = ""
                        //                                } label: {
                        //                                    Label("Copy", systemImage: "doc")
                        //                                }
                        //                            }
                        //                        }
                    }
                    .padding(.bottom)
                }
            }
        }
    }
    
    var body: some View {
        VStack {
            HStack(spacing: 10) {
                Text("Word Assistant")
                    .font(.title2.weight(.semibold))
                Spacer()
                Button(action: {presMode.wrappedValue.dismiss()}) {
                    Image(systemName: "xmark")
                        .imageScale(.medium)
                        .padding(12)
                        .font(.body.weight(.semibold))
                        .foregroundColor(Color("Color"))
                        .background(Material.regular)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal)
            .padding(.top)
            Spacer()
            CustomTextField(text: $word, placeholder: "Enter a word")
                .padding()
            Spacer()
            Button(action: {
                showResults = true
            }) {
                HStack {
                    Spacer()
                    Text("Get Synonyms")
                    Spacer()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(word.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
            .padding()
            .sheet(isPresented: $showResults) {
                nextView
                    .onAppear {
                        fetchSynonyms()
                        fetchDictionaryEntry()
                    }
            }
        }
    }
    
    //    func fetchRhymes() {
    //        viewModel.fetchRhymes(forWord: word) { rhymes in
    //            self.rhymes = rhymes
    //        }
    //    }
    
    func fetchDictionaryEntry() {
        viewModel.fetchDictionaryEntry(word: word) { result in
            switch result {
            case .success(let entry):
                DispatchQueue.main.async {
                    self.dictionaryEntry = entry
                }
            case .failure(let error):
                // Handle the error
                print("Failed to fetch dictionary entry: \(error)")
            }
        }
    }
    
    private func fetchSynonyms() {
        showResults = true
        guard let encodedWord = word.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return
        }
        
        let url = URL(string: "\(baseURL)/\(apiKey)/\(encodedWord)/json")!
        let request = URLRequest(url: url)
        
        isLoading = true
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            defer {
                DispatchQueue.main.async {
                    isLoading = false
                }
            }
            
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    
                    if let noun = json?["noun"] as? [String: Any],
                       let synonyms = noun["syn"] as? [String] {
                        DispatchQueue.main.async {
                            self.synonyms = synonyms
                        }
                    }
                } catch {
                    print("Error: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
}
