//
//  ChatUser.swift
//  Conver
//
//  Created by Ali Erdem Kökcik on 28.01.2023.
//

import FirebaseFirestoreSwift

struct ChatUser: Codable, Identifiable {
    @DocumentID var id: String?
    let uid, email, profileImageUrl: String
}
