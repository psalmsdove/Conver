//
//  ChatMessage.swift
//  Conver
//
//  Created by Ali Erdem Kökcik on 28.01.2023.
//

import Foundation
import FirebaseFirestoreSwift

struct ChatMessage: Codable, Identifiable {
    @DocumentID var id: String?
    let fromId, toId, text: String
    let timestamp: Date
}
