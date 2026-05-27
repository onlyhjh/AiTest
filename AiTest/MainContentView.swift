//
//  MainContentView.swift
//  AiTest
//
//  Created by Joey's Mac mini on 5/20/26.
//

import SwiftUI
import SwiftData
import SpriteKit
import GameplayKit

struct MainContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    @StateObject private var gameData = GameData()
    @State var isPresentedAlert: Bool = false
    @State var isPresentedCustomPopup = false
    @State var alertMessage: String? = nil
    @State var popupType: String? = nil
    @State var gameStatus:GameStatus = .wait
    
    func getGameScene(size: CGSize) -> SKScene {
        let scene = GameScene(size: size, gameData: gameData)
        scene.scaleMode = .aspectFit
        return scene
    }
    
    var body: some View {
        ZStack {
            Color.tableBG
                .ignoresSafeArea(.all)
            GeometryReader { geometry in
                VStack(alignment: .leading) {
                    SpriteView(scene: self.getGameScene(size: geometry.size))
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
            .edgesIgnoringSafeArea(.vertical)
            HStack {
                Spacer()
                VStack(alignment: .center, spacing: 20, content: {
                    Button("start") {
                        self.gameData.deckCards = DeckFactory().generateFullDeck()
                        self.gameData.gameStatus = .start
                    }
                    Button("save") {
                        if !self.gameData.deckCards.isEmpty, let encoded = try? JSONEncoder().encode(self.gameData.deckCards) {
                                UserDefaults.standard.set(encoded, forKey: "deckCards")
                            self.alertMessage = "save success"
                            self.isPresentedAlert = true
                        }
                    }
                    Button("load") {
                        if let data = UserDefaults.standard.data(forKey: "deckCards"), let deckCards = try? JSONDecoder().decode([Card].self, from: data) {
                            self.gameData.deckCards = deckCards
                            self.gameData.gameStatus = .start
                        }
                    }
                })
                .padding(.all, 10)
            }
            .ignoresSafeArea(.all)
        }
        .fullScreenCover(isPresented: $isPresentedCustomPopup, onDismiss: {
            self.gameData.gameStatus = .wait
            self.gameData.popupTitle = nil
            self.gameData.popupMessage = nil
            self.gameData.players = []
            //self.gameData.popupCards = [] 결과반환
            self.gameData.completion = {}
        }, content: {
            switch self.gameData.gameStatus  {
            case .showSelectCardPopup:
                SelectCardsView(title: self.gameData.popupTitle, message: self.gameData.popupMessage, cards: self.gameData.popupCards, select1Action: {
                    isPresentedCustomPopup = false
                    self.gameData.popupCards = [self.gameData.popupCards[0], self.gameData.popupCards[1]]
                    self.gameData.completion()
                }, select2Action: {
                    isPresentedCustomPopup = false
                    self.gameData.popupCards = [self.gameData.popupCards[0], self.gameData.popupCards[2]]
                    self.gameData.completion()
                }, closeAction: {
                    isPresentedCustomPopup = false
                })
                .presentationBackground(.black.opacity(0.2))
            case .showOneSecMessagePopup:
                OneSecMessageView(title: self.gameData.popupTitle, message: self.gameData.popupMessage,cards: self.gameData.popupCards)
                    .presentationBackground(.black.opacity(0.2))
            case .showWinnerPopup:
                WinnerView(title: self.gameData.popupTitle, message: self.gameData.popupMessage, players: self.gameData.players, closeAction: {
                    isPresentedCustomPopup = false
                    self.gameData.completion()
                })
            default:
                EmptyView()
            }
        })
        .alert(self.alertMessage ?? "", isPresented: self.$isPresentedAlert) {
            Button("OK") { self.isPresentedAlert = false}
        }
        .onChange(of: gameData.gameStatus) {
            print("change gameStatus: \(gameData.gameStatus)")
            if self.gameStatus == gameData.gameStatus { return }
            self.gameStatus = gameData.gameStatus
            
            switch self.gameStatus {
            case .showSelectCardPopup:
                self.isPresentedCustomPopup = true
            case .showWinnerPopup:
                self.isPresentedCustomPopup = true
            case .showOneSecMessagePopup:
                self.isPresentedCustomPopup = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    isPresentedCustomPopup = false
                    gameData.completion()
                }
            case .showAlert:
                self.alertMessage = self.gameData.popupMessage
                self.gameData.popupMessage = nil
                self.isPresentedAlert = true
            default:
                isPresentedCustomPopup = false
            }
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    MainContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
