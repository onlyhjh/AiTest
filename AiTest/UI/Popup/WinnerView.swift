//
//  WinnerView.swift
//  AiTest
//
//  Created by Joey's Mac mini on 5/27/26.
//


import SwiftUI

public struct WinnerView: View {
    
    var title: String?
    var message: String?
    var players: [Player]
    var closeAction: (() -> Void)
    
    init(title: String?, message: String?, players: [Player], closeAction: @escaping () -> Void) {
        self.title = title
        self.message = message
        self.players = players
        self.closeAction = closeAction
    }
    
    public var body: some View {
        ZStack {
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    Image(players[0].imageName ?? Player.unknownImageName)
                        .resizable()
                        .frame(width: 50, height: 50)
                        .cornerRadius(25)
                    Text(title ?? "")
                        .font(.title)
                    Button {
                        closeAction()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.gray)
                    }
                }
                if let message = message {
                    Text(message)
                        .font(.caption)
                }
                HStack(spacing: 10) {
                    Image(players[1].imageName ?? Player.unknownImageName)
                        .resizable()
                        .frame(width: 34, height: 34)
                        .cornerRadius(17)
                    Text(players[1].scoreText ?? "")
                        .font(.caption)
                }
                HStack(spacing: 10) {
                    Image(players[2].imageName ?? Player.unknownImageName)
                        .resizable()
                        .frame(width: 34, height: 34)
                        .cornerRadius(17)
                    Text(players[2].scoreText ?? "")
                        .font(.caption)
                }
                Button("확인") {
                    closeAction()
                }
                .foregroundStyle(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(.green)
                .clipShape(Capsule())
            }
            .padding(20)
            .background(.white.opacity(0.8))
            .cornerRadius(20)
        }
        .presentationBackground(.black.opacity(0.2))
    }
}
