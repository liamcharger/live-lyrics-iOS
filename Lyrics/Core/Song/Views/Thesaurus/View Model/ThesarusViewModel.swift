//
//  ThesarusViewModel.swift
//  Lyrics
//
//  Created by Liam Willey on 6/26/23.
//

import Foundation

//struct Rhyme: Codable, Hashable {
//    let t: String
//    let freq: Int
//    let q: String
//    let s: String
//}

//enum APIError: Error {
//    case invalidURL
//    case noData
//}

struct License: Codable {
    let name: String
    let url: String
}

struct DictionaryEntry: Codable {
    let word: String
    let phonetic: String
    let phonetics: [Phonetics]
    let meanings: [Meaning]
    let sourceUrls: [String]
    let license: License?

    struct Phonetics: Codable {
        let text: String
        let audio: String?
        let sourceUrl: String?
        let license: License?
    }

    struct Meaning: Codable {
        let partOfSpeech: String
        let definitions: [Definition]
        let synonyms: [String]
        let antonyms: [String]
    }

    struct Definition: Codable {
        let definition: String
        let example: String
        let synonyms: [String]
        let antonyms: [String]
    }

    struct License: Codable {
        let name: String
        let url: String
    }
}

class ThesarusViewModel: ObservableObject {
//    func fetchRhymes(forWord word: String, completion: @escaping([Rhyme]) -> Void) {
//        let baseURL = URL(string: "https://rhymebrain.com")!
//        let rhymeEndpoint = baseURL.appendingPathComponent("talk")
//        
//        guard var components = URLComponents(url: rhymeEndpoint, resolvingAgainstBaseURL: true) else {
//            return
//        }
//        
//        components.queryItems = [URLQueryItem(name: "word", value: word)]
//        
//        guard let url = components.url else {
//            return
//        }
//        
//        let task = URLSession.shared.dataTask(with: url) { data, response, error in
//            if let error = error {
//                print("Error: \(error)")
//                return
//            }
//
//            guard let httpResponse = response as? HTTPURLResponse,
//                  httpResponse.statusCode == 200 else {
//                print("Invalid response")
//                return
//            }
//
//            guard let data = data else {
//                print("No data received")
//                return
//            }
//            
//            // Print the data as a string
//            if let dataString = String(data: data, encoding: .utf8) {
//                print("Received data: \(dataString)")
//            }
//
//            do {
//                let rhymes = try JSONDecoder().decode([Rhyme].self, from: data)
//
//                // Process the array of rhymes as needed
//                for rhyme in rhymes {
//                    print("Word: \(rhyme.t)")
//                    print("Score: \(rhyme.s)")
//                    print("Frequency: \(rhyme.freq)")
//                    print("Syllables: \(rhyme.s)")
//                    print("-------------------")
//                }
//                
//                completion(rhymes)
//            } catch {
//                print("Error decoding JSON: \(error)")
//            }
//        }
//
//        task.resume()
//
//    }
    
    func fetchDictionaryEntry(word: String, completion: @escaping (Result<DictionaryEntry, Error>) -> Void) {
        guard let url = URL(string: "https://api.dictionaryapi.dev/api/v2/entries/en/\(word)") else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }

            do {
                let entries = try JSONDecoder().decode([DictionaryEntry].self, from: data)

                if let entry = entries.first {
                    completion(.success(entry))
                } else {
                    completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No entry found for the word '\(word)'"])))
                }
            } catch {
                completion(.failure(error))
            }
        }

        task.resume()
    }
}
