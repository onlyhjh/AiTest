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
    @StateObject private var popupData = PopupData()
    @State var isPresentedAlert: Bool = false
    @State var isPresentedPopup = false
    @State var alertMessage: String? = nil
    @State var popupType: String? = nil
    @State var popupStatus: PopupStatus = .closePopup
    
    func getGameScene(size: CGSize) -> SKScene {
        let scene = GameScene(size: size, gameData: self.gameData, popupData: self.popupData)
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
                    .foregroundStyle(.white)
                    .padding()
                    .background(.green)
                    .clipShape(Capsule())
                    Button("save") {
                        if !self.gameData.deckCards.isEmpty, let encoded = try? JSONEncoder().encode(self.gameData.deckCards) {
                                UserDefaults.standard.set(encoded, forKey: "deckCards")
                            self.alertMessage = "save success"
                            self.isPresentedAlert = true
                        }
                    }
                    .foregroundStyle(.white)
                    .padding()
                    .background(.red)
                    .clipShape(Capsule())
                    Button("load") {
                        if let data = UserDefaults.standard.data(forKey: "deckCards"), let deckCards = try? JSONDecoder().decode([Card].self, from: data) {
                            self.gameData.deckCards = deckCards
                            self.gameData.gameStatus = .start
                        }
                    }
                    .foregroundStyle(.white)
                    .padding()
                    .background(.pink)
                    .clipShape(Capsule())
                })
                .padding(.all, 10)
            }
            .ignoresSafeArea(.all)
        }
        .fullScreenCover(isPresented: $isPresentedPopup, onDismiss: {
            self.popupData.status = .closePopup
        }, content: {
            switch self.popupData.status  {
            case .showSelectCardPopup:
                SelectCardsView(title: self.popupData.title, message: self.popupData.message, players: self.popupData.players, cards: self.popupData.cards, select1Action: {
                    isPresentedPopup = false
                    self.popupData.cards = [self.popupData.cards[0], self.popupData.cards[1]]
                    self.popupData.completion(0)
                }, select2Action: {
                    isPresentedPopup = false
                    self.popupData.cards = [self.popupData.cards[0], self.popupData.cards[2]]
                    self.popupData.completion(1)
                }, closeAction: {
                    isPresentedPopup = false
                })
            case .showSelectWavePopup:
                SelectWaveView(title: self.popupData.title, message: self.popupData.message, players: self.popupData.players, cards: self.popupData.cards, select1Action: {
                    isPresentedPopup = false
                    self.popupData.completion(0)
                }, select2Action: {
                    isPresentedPopup = false
                    self.popupData.cards = [self.popupData.cards[0], self.popupData.cards[2]]
                    self.popupData.completion(1)
                }, closeAction: {
                    isPresentedPopup = false
                })
            case .showAutoCloseMessagePopup:
                AutoCloseMessageView(title: self.popupData.title, message: self.popupData.message, players: self.popupData.players,cards: self.popupData.cards, autoAction: {
                    isPresentedPopup = false
                    self.popupData.completion(0)
                })
            case .showWinnerPopup:
                WinnerView(title: self.popupData.title, message: self.popupData.message, players: self.popupData.players, closeAction: {
                    isPresentedPopup = false
                    self.popupData.completion(0)
                })
            case .showChongTongWinnerPopup:
                ChongTongWinnerView(title: self.popupData.title, message: self.popupData.message, players: self.popupData.players, cards: self.popupData.cards, closeAction: {
                    isPresentedPopup = false
                    self.popupData.completion(0)
                })
            default:
                EmptyView()
            }
        })
        .transaction { transaction in
            transaction.disablesAnimations = true
        }
        .alert(self.alertMessage ?? "", isPresented: self.$isPresentedAlert) {
            Button("OK") { self.isPresentedAlert = false}
        }
        .onChange(of: popupData.status) {
            print("change popupStatus: \(popupData.status)")
            if self.popupStatus == popupData.status { return }
            self.popupStatus = popupData.status
            
            switch self.popupStatus {
            case .showSelectCardPopup:
                self.isPresentedPopup = true
            case .showSelectWavePopup:
                self.isPresentedPopup = true
            case .showChongTongWinnerPopup:
                self.isPresentedPopup = true
            case .showWinnerPopup:
                self.isPresentedPopup = true
            case .showAutoCloseMessagePopup:
                self.isPresentedPopup = true
            case .showAlert:
                self.alertMessage = self.popupData.message
                self.isPresentedAlert = true
            default:
                isPresentedPopup = false
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
