//
//  ChatLogView.swift
//  Conver
//
//  Created by Ali Erdem Kökcik on 28.01.2023.
//

import SwiftUI
import Firebase

struct FirebaseConstants {
    static let fromId = "fromId"
    static let toId = "toId"
    static let text = "text"
}
 
struct ChatMessage: Identifiable{
    var id: String { documentId  }
    let documentId: String
    let fromId, toId, text: String
    init(documentId: String, data: [String: Any]){
        self.documentId = documentId
        self.fromId = data[FirebaseConstants.fromId] as? String ?? ""
        self.toId = data[FirebaseConstants.toId] as? String ?? ""
        self.text = data[FirebaseConstants.text] as? String ?? ""
    }
}

class ChatLogViewModel: ObservableObject {
    // MARK: - Properties
    @Published var chatText = ""
    @Published var errorMessage = ""
    @Published var chatMessages = [ChatMessage]()
    
    let chatUser: ChatUser?
    
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        fetchMessages()
    }
    // MARK: - Fetching message function
    private func fetchMessages(){
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else { return }
                guard let toId = chatUser?.uid else { return }
                FirebaseManager.shared.firestore
                    .collection("messages")
                    .document(fromId)
                    .collection(toId)
                    .order(by: "timestamp")
                    .addSnapshotListener { querySnapshot, error in
                        if let error = error {
                            self.errorMessage = "Failed to listen for messages: \(error)"
                            print(error)
                            return
                        }
                        
                        querySnapshot?.documentChanges.forEach({ change in
                            if change.type == .added {
                                let data = change.document.data()
                                self.chatMessages.append(.init(documentId: change.document.documentID, data: data))
                    }
                })
            }
    }
    // MARK: - Sending message function
    func handleSend() {
        print(chatText)
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        guard let toId = chatUser?.uid else { return }
        
        let document = FirebaseManager.shared.firestore.collection("messages")
            .document(fromId)
            .collection(toId)
            .document()
        
        let messageData = [FirebaseConstants.fromId: fromId, FirebaseConstants.toId: toId, FirebaseConstants.text: self.chatText, "timestamp": Timestamp()] as [String : Any]
        
        document.setData(messageData) { error in
            if let error = error {
                print(error)
                self.errorMessage = "Failed to save message into Firestore: \(error)"
                return
            }
            
            print("Successfully saved current user sending message")
            self.chatText = ""
        }
        
        let recipientMessageDocument = FirebaseManager.shared.firestore.collection("messages")
            .document(toId)
            .collection(fromId)
            .document()
        
        recipientMessageDocument.setData(messageData) { error in
            if let error = error {
                print(error)
                self.errorMessage = "Failed to save message into Firestore: \(error)"
                return
            }
            
            print("Recipient saved message as well")
        }
    }
}

struct ChatLogView: View {
    
    let chatUser: ChatUser?
    
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        self.vm = .init(chatUser: chatUser)
    }
    
    @ObservedObject var vm: ChatLogViewModel
    // MARK: - Body
    var body: some View {
        ZStack {
            messagesView
            Text(vm.errorMessage)
        }
        .navigationTitle(chatUser?.email ?? "")
            .navigationBarTitleDisplayMode(.inline)
    }
    // MARK: - Messages
    private var messagesView: some View {
        VStack {
            if #available(iOS 15.0, *) {
                ScrollView {
                    ForEach(vm.chatMessages){ message in
                        VStack{
                            if message.fromId == FirebaseManager.shared.auth.currentUser?.uid{
                                HStack {
                                    Spacer()
                                    HStack {
                                        Text(message.text )
                                            .foregroundColor(.white)
                                    }
                                    .padding()
                                    .background(Color.black)
                                    .cornerRadius(30)
                                }
                                .padding(.horizontal)
                                .padding(.top, 6)
                            } else {
                                HStack {
                                    HStack {
                                        Text(message.text )
                                            .foregroundColor(Color.black)
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(30)
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.top, 6)
                            }
                        }
                        
                    }
                    
                    HStack{ Spacer() }
                }
                .background(Color(.init(white: 0.95, alpha: 1)))
                .safeAreaInset(edge: .bottom) {
                    chatBottomBar
                        .background(Color(.systemBackground).ignoresSafeArea())
                }
            } else {
                // Fallback on earlier versions
            }
        }
    }
    // MARK: - Bottom bar
    private var chatBottomBar: some View {
        HStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 24))
                .foregroundColor(Color(.darkGray))
            ZStack {
                DescriptionPlaceholder()
                TextEditor(text: $vm.chatText)
                    .opacity(vm.chatText.isEmpty ? 0.5 : 1)
            }
            .frame(height: 40)
            
            Button {
                vm.handleSend()
            } label: {
                Text("Send")
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.black)
            .cornerRadius(30)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

private struct DescriptionPlaceholder: View {
    var body: some View {
        HStack {
            Text("Enter your message")
                .foregroundColor(Color(.gray))
                .font(.system(size: 17))
                .padding(.leading, 5)
                .padding(.top, -4)
            Spacer()
        }
    }
}

// MARK: - Preview
struct ChatLogView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChatLogView(chatUser: .init(data: ["uid" : "tnDMbcec1qUwwTt6jcA6aQ5bYVZ2", "email" : "alierdem @gmail.com"]))
        }
    }
}
