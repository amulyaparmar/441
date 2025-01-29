//
//  PostView.swift
//  swiftUIChatter
//
//  Created by BlessedAmulya Parmar on 1/29/25.
//


import SwiftUI

struct PostView: View {
    @Binding var isPresented: Bool

    private let username = "amulya"
    @State private var message = "Some short sample text."

    var body: some View {
        VStack {
            Text(username)
                .padding(.top, 30.0)
            TextEditor(text: $message)
                .padding(EdgeInsets(top: 10, leading: 18, bottom: 0, trailing: 4))
                .frame(minHeight: 80, maxHeight: 120)
        }
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement:.topBarTrailing) {
                SubmitButton()
            }
        }
    }

    @ViewBuilder
    private func SubmitButton() -> some View {
        @State var isDisabled: Bool = false
        
        Button {
            isDisabled = true
            ChattStore.shared.postChatt(Chatt(username: username, message: message)) {
                ChattStore.shared.getChatts()
            }
            isPresented.toggle()
        } label: {
            Image(systemName: "paperplane")
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.2 : 1)        
    }
}
