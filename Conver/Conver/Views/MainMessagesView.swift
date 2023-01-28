//
//  MainMessagesView.swift
//  Conver
//
//  Created by Ali Erdem Kökcik on 26.01.2023.
//

import SwiftUI
import SDWebImageSwiftUI


class MainMessagesViewModel: ObservableObject{
    // MARK: - Properties
    @Published var errorMessage = ""
    @Published var chatUser: ChatUser?
    init(){
        self.isUserCurrentlyLoggedOut = FirebaseManager.shared.auth.currentUser?.uid == nil
        fetchCurrentUser()
    }
    // MARK: - Fetching the current user
    func fetchCurrentUser() {
            guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
                self.errorMessage = "Could not find firebase uid"
                return
            }
            FirebaseManager.shared.firestore.collection("users").document(uid).getDocument { snapshot, error in
                if let error = error {
                    self.errorMessage = "Failed to fetch current user: \(error)"
                    print("Failed to fetch current user:", error)
                    return
                }
    //            self.errorMessage = "123"
                guard let data = snapshot?.data() else {
                    self.errorMessage = "No data found"
                    return
                }
    //            self.errorMessage = "Data: \(data.description)"
                let uid = data["uid"] as? String ?? ""
                let email = data["email"] as? String ?? ""
                let profileImageUrl = data["profileImageUrl"] as? String ?? ""
                self.chatUser = ChatUser(uid: uid, email: email, profileImageUrl: profileImageUrl)
    //            self.errorMessage = chatUser.profileImageUrl
            }
        }
    // MARK: - Sign out from the application
    
    @Published var isUserCurrentlyLoggedOut = false
    
    func handleSignOut(){
        isUserCurrentlyLoggedOut.toggle()
        try? FirebaseManager.shared.auth.signOut()
    }
}
    // MARK: - Main Messages
    struct MainMessagesView: View {
    // MARK: - Properties
    @State var shouldShowLogOutOptions = false
    @ObservedObject private var vm = MainMessagesViewModel()
    // MARK: - Body
    var body: some View {
        NavigationView{
            VStack{
                // Text("Current user ID: \(vm.errorMessage)")
                // MARK: - NAVBAR
                
                HStack(spacing: 16){
                    WebImage(url: URL(string: vm.chatUser?.profileImageUrl ?? ""))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 52, height: 52)
                        .clipped()
                        .cornerRadius(44)
                    VStack(alignment: .leading, spacing: 4){
                        let email =  vm.chatUser?.email.replacingOccurrences(of: "@gmail.com", with: "") ?? ""
                            .replacingOccurrences(of: "@hotmail.com", with: "") // Removing gmail and hotmail from the name
                        Text(email)
                            .font(.system(size: 24, weight: .bold))
                        HStack{
                            Circle()
                                .foregroundColor(.green)
                                .frame(width: 10, height: 10)
                            Text("online")
                                .font(.system(size: 12))
                                .foregroundColor(Color(.lightGray))
                        }
                    }
                    Spacer()
                    // MARK: - Settings
                    Button {
                        shouldShowLogOutOptions.toggle() // it turns true from false
                    } label: {
                        Image(systemName: "gear")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color("NewMessageButton"))
                    }
                }
                .padding()
                .actionSheet(isPresented: $shouldShowLogOutOptions) { // A popup screen which shows the settings
                         .init(title: Text("Settings"), message: Text("What do you wanna do?"), buttons: [
                             .destructive(Text("Sign Out"), action: {
                                 print("handle sign out")
                                 vm.handleSignOut()
                             }),
                                 .cancel()
                         ])
                     }
                .fullScreenCover(isPresented: $vm.isUserCurrentlyLoggedOut, onDismiss: nil){ // It will direct to the login view
                    LoginView(didCompleteLoginProcess: {
                        self.vm.isUserCurrentlyLoggedOut = false
                        self.vm.fetchCurrentUser()
                    })
                }
                
                // MARK: - Messages
                
                ScrollView{
                    ForEach(0..<10, id: \.self){ num in
                        VStack{
                            HStack(spacing: 16){
                                Image(systemName: "person.fill")
                                    .font(.system(size: 32))
                                    .padding(8)
                                    .overlay(RoundedRectangle(cornerRadius: 44)
                                        .stroke(Color.black, lineWidth: 1)
                                    )
                                VStack(alignment: .leading){
                                    Text("Username")
                                        .font(.system(size: 14, weight: .bold))
                                    Text("Message sent to user")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(.lightGray))
                                }
                                Spacer()
                                Text("22d")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            Divider()
                                .padding(.vertical, 8)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 50)
                }
                
                // MARK: - New message button
                
                .overlay(Button {
                    //
                } label: {
                    HStack{
                        Spacer()
                        Text("+ New message")
                            .font(.system(size: 16, weight: .bold))
                        Spacer()
                    }
                    .foregroundColor(Color("NewMessageText")) // Dark mode compatibility
                    .padding(.vertical)
                    .background(Color("NewMessageButton")) // Dark mode compatibility
                    .cornerRadius(30)
                    .shadow(radius: 20)
                    .padding()
                }, alignment: .bottom)
            }
            .navigationBarHidden(true)
            .navigationTitle("Main Messages")
        }
    }
}
// MARK: - Preview
struct MainMessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MainMessagesView()
            .preferredColorScheme(.dark)
        MainMessagesView()
    }
}
