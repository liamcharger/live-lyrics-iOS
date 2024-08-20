//
//  DatamuseService.swift
//  Lyrics
//
//  Created by Liam Willey on 8/20/24.
//

import Foundation

class DatamuseService: ObservableObject {
    @Published var rhymes = [DatamuseRhyme]()
    @Published var isLoadingRhymes = false
    
    let endpoint = "https://api.datamuse.com"
    
    static let shared = DatamuseService()
    
    func fetchRhymes(for word: String) {
        let words = word.replacingOccurrences(of: " ", with: "+")
        guard let url = URL(string: endpoint + "/words?sl=\(words)") else { return }
        
        self.isLoadingRhymes = true
        
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
                let decoder = JSONDecoder()
                let receivedRhymes = try decoder.decode([DatamuseRhyme].self, from: data)
                
                for rhyme in receivedRhymes {
                    rhymes.append(rhyme)
                }
            } catch let decodingError {
                print("Error decoding JSON for popular songs: \(decodingError.localizedDescription)")
            }
            
            self.rhymes = rhymes
            self.isLoadingRhymes = false
        }.resume()
    }
}
