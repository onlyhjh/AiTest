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
    var buttonTexts: [String]
    let buttonActions: [() -> Void]
    var closeAction: (() -> Void)
    
    init(title: String?, message: String?, players: [Player], cards: [Card], buttonTexts: [String], buttonActions: [() -> Void], closeAction: @escaping () -> Void) {
        self.title = title
        self.message = message
        self.players = players
        self.cards = cards
        self.buttonTexts = buttonTexts
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
                    Image(players[0].imageName ?? "player_unkown")
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
                        Image(cards[index].imageName ?? "hwatu_back")
                            .resizable()
                            .frame(width: 50, height: 75)
                            .rotationEffect(.degrees(15 * Double(index % 2 == 0 ? 1 : -1)))
                    }
                }
                HStack(spacing: 20) {
                    ForEach(0..<buttonTexts.count) { index in
                        Button(buttonTexts[index]) {
                            buttonActions[index]()
                        }
                        .foregroundStyle(.white)
                        .padding()
                        .frame(width: 150)
                        .background(index % 2 == 0 ? .red : .green)
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(20)
            .background(.white.opacity(0.8))
            .cornerRadius(20)
        }
        .presentationBackground(.black.opacity(0.2))
    }
}
