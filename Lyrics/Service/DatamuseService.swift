//
//  DatamuseService.swift
//  Lyrics
//
//  Created by Liam Willey on 8/20/24.
//

import Foundation

class DatamuseService: ObservableObject {
    @Published var rhymes = [DatamuseRhyme]()
    @Published var words = [DatamuseWord]()
    @Published var isLoadingWords = false
    
    let endpoint = "https://api.datamuse.com"
    
    static let shared = DatamuseService()
    
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
        guard let url = URL(string: endpoint + "/words?sl=\(words)") else { return }
        
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
            
            var rhymes = [DatamuseRhyme]()
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                    for item in jsonResponse {
                        if let word = item["word"] as? String,
                           let score = item["score"] as? Int,
                           let numSyllables = item["numSyllables"] as? Int {
                            rhymes.append(DatamuseRhyme(word: word, score: score, numSyllables: numSyllables))
                        } else {
                            print("Error parsing item: \(item)")
                        }
                    }
                } else {
                    print("Invalid JSON format")
                }
            } catch let parsingError {
                print("Error decoding JSON for rhymes: \(parsingError.localizedDescription)")
            }
            
            DispatchQueue.main.async {
                self.rhymes = rhymes
                self.isLoadingWords = false
            }
        }.resume()
    }
    
    func fetchSynonyms(for word: String) {
        let words = word.replacingOccurrences(of: " ", with: "+")
        guard let url = URL(string: endpoint + "/words?rel_syn=\(words)") else { return }
        
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
        guard let url = URL(string: endpoint + "/rel_ant=\(words)") else { return }
        
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
        guard let url = URL(string: endpoint + "/words?ml=\(words)") else { return }
        
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
        guard let url = URL(string: endpoint + "/sug?s=\(words)") else { return }
        
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
