//
//  WordService.swift
//  Lyrics
//
//  Created by Liam Willey on 8/20/24.
//

import Foundation

class WordService: ObservableObject {
    @Published var rhymes = [Rhyme]()
    @Published var words = [DatamuseWord]()
    @Published var isLoadingWords = false
    
    let datamuseEndpoint = "https://api.datamuse.com"
    let rhymeBrainEndpoint = "https://rhymebrain.com"
    
    static let shared = WordService()
    
    func fetchWords(for word: String, type: DatamuseWordType) {
        switch type {
        case .synonymn:
            fetchSynonyms(for: word)
        case .rhyme:
            fetchRhymes(for: word)
        case .antonymn:
            fetchAntonyms(for: word)
        case .related:
            fetchRelated(for: word)
        case .startsWith:
            fetchWordsStartingWith(for: word)
        }
    }
    
    func fetchRhymes(for word: String) {
        let words = word.replacingOccurrences(of: " ", with: "+")
        guard let url = URL(string: rhymeBrainEndpoint + "/talk?function=getRhymes&word=\(words)") else { return }
        
        self.isLoadingWords = true
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Failed to fetch rhymes: \(error)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                let rhymes = try JSONDecoder().decode([RhymebrainRhyme].self, from: data)
                var completedRhymes = [Rhyme]()
                let group = DispatchGroup()
                
                group.enter()
                for rhyme in rhymes {
                    completedRhymes.append(Rhyme(word: rhyme.word, score: rhyme.score, syllables: Int(rhyme.syllables) ?? 1))
                }
                group.leave()
                
                group.notify(queue: .main) {
                    self.rhymes = completedRhymes
                    self.isLoadingWords = false
                }
            } catch {
                print("Failed to decode JSON: \(error)")
                self.isLoadingWords = false
            }
        }.resume()
    }
    
    func fetchSynonyms(for word: String) {
        let words = word.replacingOccurrences(of: " ", with: "+")
        guard let url = URL(string: datamuseEndpoint + "/words?rel_syn=\(words)") else { return }
        
        self.isLoadingWords = true
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching data: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data returned.")
                return
            }
            
            var words = [DatamuseWord]()
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                    for item in jsonResponse {
                        if let word = item["word"] as? String,
                           let score = item["score"] as? Int {
                            words.append(DatamuseWord(word: word, score: score))
                        } else {
                            print("Error parsing item: \(item)")
                        }
                    }
                } else {
                    print("Invalid JSON format")
                }
            } catch {
                print("Error parsing JSON: \(error.localizedDescription)")
            }
            
            DispatchQueue.main.async {
                self.words = words
                self.isLoadingWords = false
            }
        }.resume()
    }
    
    func fetchAntonyms(for word: String) {
        let words = word.replacingOccurrences(of: " ", with: "+")
        guard let url = URL(string: datamuseEndpoint + "/rel_ant=\(words)") else { return }
        
        self.isLoadingWords = true
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching data: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data returned.")
                return
            }
            
            var words = [DatamuseWord]()
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                    for item in jsonResponse {
                        if let word = item["word"] as? String,
                           let score = item["score"] as? Int {
                            words.append(DatamuseWord(word: word, score: score))
                        } else {
                            print("Error parsing item: \(item)")
                        }
                    }
                } else {
                    print("Invalid JSON format")
                }
            } catch {
                print("Error parsing JSON: \(error.localizedDescription)")
            }
            
            DispatchQueue.main.async {
                self.words = words
                self.isLoadingWords = false
            }
        }.resume()
    }
    
    func fetchRelated(for word: String) {
        let words = word.replacingOccurrences(of: " ", with: "+")
        guard let url = URL(string: datamuseEndpoint + "/words?ml=\(words)") else { return }
        
        self.isLoadingWords = true
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching data: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data returned.")
                return
            }
            
            var words = [DatamuseWord]()
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                    for item in jsonResponse {
                        if let word = item["word"] as? String,
                           let score = item["score"] as? Int {
                            words.append(DatamuseWord(word: word, score: score))
                        } else {
                            print("Error parsing item: \(item)")
                        }
                    }
                } else {
                    print("Invalid JSON format")
                }
            } catch {
                print("Error parsing JSON: \(error.localizedDescription)")
            }
            
            DispatchQueue.main.async {
                self.words = words
                self.isLoadingWords = false
            }
        }.resume()
    }
    
    func fetchWordsStartingWith(for word: String) {
        let words = word.replacingOccurrences(of: " ", with: "+")
        guard let url = URL(string: datamuseEndpoint + "/sug?s=\(words)") else { return }
        
        self.isLoadingWords = true
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching data: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data returned.")
                return
            }
            
            var words = [DatamuseWord]()
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                    for item in jsonResponse {
                        if let word = item["word"] as? String,
                           let score = item["score"] as? Int {
                            words.append(DatamuseWord(word: word, score: score))
                        } else {
                            print("Error parsing item: \(item)")
                        }
                    }
                } else {
                    print("Invalid JSON format")
                }
            } catch {
                print("Error parsing JSON: \(error.localizedDescription)")
            }
            
            DispatchQueue.main.async {
                self.words = words
                self.isLoadingWords = false
            }
        }.resume()
    }
}
