//
//  SortViewModel.swift
//  Lyrics
//
//  Created by Liam Willey on 1/2/24.
//

import Foundation

class SortViewModel: ObservableObject {
    private let sortSelectionKey = "sortSelection"
    
    func saveToUserDefaults(sortSelection: SortSelectionEnum) {
        UserDefaults.standard.set(sortSelection.rawValue, forKey: self.sortSelectionKey)
    }
    
    func loadFromUserDefaults(completion: @escaping(SortSelectionEnum) -> Void) {
        if let savedSortSelectionRawValue = UserDefaults.standard.value(forKey: sortSelectionKey) as? String,
           let savedSortSelection = SortSelectionEnum(rawValue: savedSortSelectionRawValue) {
            completion(savedSortSelection)
        }
    }
}
