//
//  ChongTongWinnerView.swift
//  AiTest
//
//  Created by Joey's Mac mini on 5/26/26.
//

import SwiftUI

public struct ChongTongWinnerView: View {

    var title: String?
    var message: String?
    var players: [Player]
    var cards: [Card]
    var closeAction: () -> Void = { }
    
    // 😎 😭 🥶😱🤯😭😘🤩💀
    init(title: String?, message: String?, players: [Player], cards: [Card], closeAction: @escaping () -> Void) {
        self.title = title
        self.message = message
        self.players = players
        self.cards = cards
        self.closeAction = closeAction
    }
    
    public var body: some View {
        ZStack {
            VStack(spacing: 10) {
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
                HStack(spacing: 10) {
                    Image(players[1].imageName ?? "player_unkown")
                        .resizable()
                        .frame(width: 34, height: 34)
                        .cornerRadius(17)
                    Text(players[1].scoreText ?? "")
                        .font(.caption)
                }
                HStack(spacing: 10) {
                    Image(players[2].imageName ?? "player_unkown")
                        .resizable()
                        .frame(width: 34, height: 34)
                        .cornerRadius(17)
                    Text(players[2].scoreText ?? "")
                        .font(.caption)
                }
                HStack(spacing: 20) {
                    Button("확인") {
                        closeAction()
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
