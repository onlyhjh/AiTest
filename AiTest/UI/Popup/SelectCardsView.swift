//
//  SelectCardsView.swift
//  AiTest
//
//  Created by Joey's Mac mini on 5/26/26.
//

import SwiftUI

public struct SelectCardsView: View {
    
    var title: String?
    var message: String?
    var players: [Player]
    var cards: [Card]
    var buttonActions: [() -> Void]
    var closeAction: (() -> Void)
    
    init(title: String?, message: String?, players: [Player], cards: [Card], buttonActions: [() -> Void], closeAction: @escaping () -> Void) {
        self.title = title
        self.message = message
        self.players = players
        self.cards = cards
        self.buttonActions = buttonActions
        self.closeAction = closeAction
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
                    Image(players.first?.imageName ?? Player.unknownImageName)
                        .resizable()
                        .frame(width: 50, height: 50)
                        .cornerRadius(25)
                    if let title {
                        Text(title)
                            .font(.title)
                    }
                    Image(cards[0].imageName ?? Card.backImageName)
                        .resizable()
                        .frame(width: 25, height: 37)
                }
                if let message {
                    Text(message)
                        .font(.caption)
                }
                HStack(spacing: 20) {
                    ForEach(1..<cards.count) { index in
                        Button {
                            buttonActions[index]()
                        } label: {
                            Image(cards[index].imageName ?? Card.backImageName)
                                .resizable()
                                .frame(width: 50, height: 75)
                        }
                    }
                }
            }
            .padding(20)
            .background(.white.opacity(0.9))
            .cornerRadius(20)
        }
        .presentationBackground(.black.opacity(0.2))
    }
}
