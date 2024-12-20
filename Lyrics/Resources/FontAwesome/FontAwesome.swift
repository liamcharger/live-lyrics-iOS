//
//  FontAwesome.swift
//  link-swiftui
//
//  Created by Matt Maddux on 9/23/19.
//  Copyright © 2019 Matt Maddux. All rights reserved.
//

import SwiftUI

class FontAwesome {
    
    // ======================================================= //
    // MARK: - Shared Instance
    // ======================================================= //
    
    static var shared: FontAwesome = FontAwesome()
    
    // ======================================================= //
    // MARK: - Published Properties
    // ======================================================= //
    
    private(set) var store: [String: FAIcon]
    
    // ======================================================= //
    // MARK: - Initializer
    // ======================================================= //
    
    init() {
        let fileURL = Bundle.main.url(forResource: "icons", withExtension: "json")!
        let jsonString = try! String(contentsOf: fileURL, encoding: .utf8)
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        self.store = try! decoder.decode([String: FAIcon].self, from: jsonData)
        for key in store.keys {
            store[key]!.id = key
        }
    }
    
    
    // ======================================================= //
    // MARK: - Methods
    // ======================================================= //
    
    func icon(byName name: String) -> FAIcon? {
        return store[name.lowercased()]
    }
    
    // icon(byAlias:) added to allow FA5 backwards compatibility where names have changed and moved to an aliases array
    func icon(byAlias name: String) -> FAIcon? {
        var iconName = ""
        for item in store {
            if let aliasNames = item.value.aliasNames, aliasNames.contains(name) {
                iconName = item.value.id ?? name
                print("found \(name) by alias as \(iconName)")
                return store[iconName.lowercased()]
            }
        }
        return store[iconName.lowercased()]
    }
}
