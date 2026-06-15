//
//  AutoCloseMessageView.swift.swift
//  AiTest
//
//  Created by Joey's Mac mini on 5/26/26.
//

import SwiftUI

public struct AutoCloseMessageView: View {

    var title: String?
    var message: String?
    var players: [Player]
    var cards: [Card]
    
    // 😎 😭 🥶😱🤯😭😘🤩💀
    init(title: String?, message: String?, players: [Player], cards: [Card]) {
        self.title = title
        self.message = message
        self.players = players
        self.cards = cards
    }
    
    public var body: some View {
        ZStack {
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    Image(players[0].imageName ?? Player.unknownImageName)
                        .resizable()
                        .frame(width: 50, height: 50)
                        .cornerRadius(25)
                    if let title {
                        Text(title)
                            .font(.title)
                    }
                }
                if let message {
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
            }
            .padding(20)
            .background(.white.opacity(0.8))
            .cornerRadius(20)
        }
        .presentationBackground(.black.opacity(0.2))
    }
}
