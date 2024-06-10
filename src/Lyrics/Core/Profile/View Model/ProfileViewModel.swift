//
//  ProfileViewModel.swift
//  Lyrics
//
//  Created by Liam Willey on 5/19/23.
//

import Foundation
import SwiftUI

class ProfileViewModel: ObservableObject {
    let service = UserService()
    
    func changePassword(_ user: User, newPassword: String, currentPassword: String, completion: @escaping(Bool) -> Void, completionString: @escaping(String) -> Void) {
        service.changePassword(user, password: newPassword, currentPassword: currentPassword) { success in
            if success {
                completion(true)
            } else {
                completion(false)
            }
        } completionString: { string in
            completionString(string)
        }
    }
}
