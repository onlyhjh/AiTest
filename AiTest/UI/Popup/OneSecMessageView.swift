//
//  OneSecMessageView.swift
//  AiTest
//
//  Created by Joey's Mac mini on 5/26/26.
//

import SwiftUI

public struct OneSecMessageView: View {
    
    var title: String?
    var message: String?
    var cards: [Card]
    
    // 😎 😭 🥶😱🤯😭😘🤩💀
    init(title: String?, message: String?, cards: [Card]) {
        self.title = title
        self.message = message
        self.cards = cards
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
                HStack(spacing: 0) {
                    ForEach(0..<cards.count) { index in
                        Image(cards[index].imageName ?? "hwatu_back")
                            .resizable()
                            .frame(width: 50, height: 75)
                            .rotationEffect(.degrees(15 * Double(index % 2 == 0 ? 1 : -1)))
                    }
                }
            }
            .padding(10)
            .background(.white.opacity(0.8))
            .cornerRadius(10)
        }
    }
}
