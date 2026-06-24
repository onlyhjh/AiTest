//
//  MessageView.swift
//  AiTest
//
//  Created by Joey's Mac mini on 6/17/26.
//

import SwiftUI

public struct MessageView: View {
    
    var title: String?
    var message: String?
    var buttonText: String
    let buttonAction: () -> Void
    
    init(title: String?, message: String?, buttonText: String, buttonAction: @escaping () -> Void) {
        self.title = title
        self.message = message
        self.buttonText = buttonText
        self.buttonAction = buttonAction
    }
    
    public var body: some View {
        ZStack {
            VStack(spacing: 10) {
                if let title = title {
                    Text(title)
                        .font(.title)
                }
                if let message = message {
                    Text(message)
                        .font(.caption)
                }
                Button(buttonText) {
                    self.buttonAction()
                }
                .foregroundStyle(.white)
                .padding()
                .frame(width: 150)
                .background(.green)
                .clipShape(Capsule())
            }
            .padding(20)
            .background(.white.opacity(0.9))
            .cornerRadius(20)
        }
        .presentationBackground(.black.opacity(0.4))
    }
}
