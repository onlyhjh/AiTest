//
//  SelectWaveView.swift
//  AiTest
//
//  Created by Joey's Mac mini on 5/26/26.
//

import SwiftUI

public struct SelectWaveView: View {
    
    var title: String?
    var message: String?
    var cards: [Card]
    var select1Action: (() -> Void)
    var select2Action: (() -> Void)
    var closeAction: (() -> Void)
    
    init(title: String?, message: String?, cards: [Card], select1Action: @escaping () -> Void, select2Action: @escaping () -> Void, closeAction: @escaping () -> Void) {
        self.title = title
        self.message = message
        self.cards = cards
        self.select1Action = select1Action
        self.select2Action = select2Action
        self.closeAction = closeAction
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
                HStack(spacing: 10) {
                    Button {
                        select1Action()
                    } label: {
                        Text("흔들기")
                    }
                    
                    Button {
                        select2Action()
                    } label: {
                        Text("그냥치기")
                    }
                }
            }
            .padding(10)
            .background(.white.opacity(0.8))
            .cornerRadius(10)
        }
    }
}
