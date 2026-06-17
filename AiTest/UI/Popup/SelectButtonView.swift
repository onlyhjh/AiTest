//
//  SelectButtonView.swift
//  AiTest
//
//  Created by Joey's Mac mini on 5/26/26.
//

import SwiftUI

public struct SelectButtonView: View {
    
    var title: String?
    var message: String?
    var players: [Player]
    var cards: [Card]
    var button1Text: String
    var button2Text: String
    var button1Action: (() -> Void)
    var button2Action: (() -> Void)
    
    init(title: String?, message: String?, players: [Player], cards: [Card], button1Text: String, button2Text: String, button1Action: @escaping () -> Void, button2Action: @escaping () -> Void) {
        self.title = title
        self.message = message
        self.players = players
        self.cards = cards
        self.button1Text = button1Text
        self.button2Text = button2Text
        self.button1Action = button1Action
        self.button2Action = button2Action
    }
    
    public var body: some View {
        ZStack {
            VStack(spacing: 10) {
//                HStack(spacing: 10) {
//                    Spacer()
//                    Button {
//                        closeAction()
//                    } label: {
//                        Image(systemName: "xmark.circle.fill")
//                                .font(.title)
//                                .foregroundColor(.gray)
//                    }
//                }
                HStack(spacing: 10) {
                    Image(players[0].imageName ?? Player.unknownImageName)
                        .resizable()
                        .frame(width: 50, height: 50)
                        .cornerRadius(25)
                    if let title = title {
                        Text(title)
                            .font(.title)
                    }
                }
                if let message = message {
                    Text(message)
                        .font(.caption)
                }
                HStack(spacing: 0) {
                    ForEach(0..<cards.count) { index in
                        Image(cards[index].imageName ?? Card.backImageName)
                            .resizable()
                            .frame(width: 50, height: 75)
                            .rotationEffect(.degrees(15 * Double(index % 2 == 0 ? 1 : -1)))
                    }
                }
                HStack(spacing: 20) {
                    Button(button1Text) {
                        button1Action()
                    }
                    .foregroundStyle(.white)
                    .padding()
                    .frame(width: 150)
                    .background(.red)
                    .clipShape(Capsule())
                    
                    Button(button2Text) {
                        button2Action()
                    }
                    .foregroundStyle(.white)
                    .padding()
                    .frame(width: 150)
                    .background(.green)
                    .clipShape(Capsule())
                }
            }
            .padding(20)
            .background(.white.opacity(0.8))
            .cornerRadius(20)
        }
        .presentationBackground(.black.opacity(0.2))
    }
}
