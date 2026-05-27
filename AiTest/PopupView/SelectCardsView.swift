//
//  SelectCardsView.swift
//  AiTest
//
//  Created by Joey's Mac mini on 5/26/26.
//

import SwiftUI

public struct SelectCardsView: View {
    
    var title: String
    var cards: [Card]
    var select1Action: (() -> Void)
    var select2Action: (() -> Void)
    var closeAction: (() -> Void)
    
    init(title: String, cards: [Card], select1Action: @escaping () -> Void, select2Action: @escaping () -> Void, closeAction: @escaping () -> Void) {
        self.title = title
        self.cards = cards
        self.select1Action = select1Action
        self.select2Action = select2Action
        self.closeAction = closeAction
    }
    
    public var body: some View {
        ZStack {
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    Image(cards[0].imageName ?? "hwatu_back")
                        .resizable()
                        .frame(width: 25, height: 37)
                    Text(title)
                    
                    Button {
                        closeAction()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.gray)
                    }
                }
                HStack(spacing: 10) {
                    Button {
                        select1Action()
                    } label: {
                        Image(cards[1].imageName ?? "hwatu_back")
                            .resizable()
                            .frame(width: 50, height: 75)
                    }
                    
                    Button {
                        select2Action()
                    } label: {
                        Image(cards[2].imageName ?? "hwatu_back")
                            .resizable()
                            .frame(width: 50, height: 75)
                    }
                }
            }
            .padding(10)
            .background(.white.opacity(0.8))
            .cornerRadius(10)
        }
    }
}
