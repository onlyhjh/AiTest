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
    @State var isPresentedSettingView = false
    @State var alertMessage: String? = nil
    @State var popupType: String? = nil
    @State var popupStatus: PopupStatus = .closePopup
    @State var scene: GameScene? // 다시 그리기 방지
    @State var showSpriteView = false
    
    var body: some View {
        ZStack {
            Color.tableBG
                .ignoresSafeArea(.all)
            GeometryReader { geometry in
                Group {
                    if let scene, showSpriteView {
                        SpriteView(scene: scene)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                    else {
                        Color.pink
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        if scene == nil {
                            let newScene = GameScene(size: geometry.size, gameData: self.gameData, popupData: self.popupData, isPresentedSettingView: $isPresentedSettingView)
                            newScene.scaleMode = .aspectFit
                            scene = newScene
                        }
                        showSpriteView = true
                    }
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
                    Button("save1") {
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
                    Button("save2") {
                        if !self.gameData.deckCards.isEmpty, let encoded = try? JSONEncoder().encode(self.gameData.deckCards) {
                                UserDefaults.standard.set(encoded, forKey: "deckCards2")
                            self.alertMessage = "save success"
                            self.isPresentedAlert = true
                        }
                    }
                    .foregroundStyle(.white)
                    .padding()
                    .background(.red)
                    .clipShape(Capsule())
                    Button("load1") {
                        if let data = UserDefaults.standard.data(forKey: "deckCards"), let deckCards = try? JSONDecoder().decode([Card].self, from: data) {
                            self.gameData.deckCards = deckCards
                            self.gameData.gameStatus = .start
                        }
                    }
                    .foregroundStyle(.white)
                    .padding()
                    .background(.blue)
                    .clipShape(Capsule())
                    Button("load2") {
                        if let data = UserDefaults.standard.data(forKey: "deckCards2"), let deckCards = try? JSONDecoder().decode([Card].self, from: data) {
                            self.gameData.deckCards = deckCards
                            self.gameData.gameStatus = .start
                        }
                    }
                    .foregroundStyle(.white)
                    .padding()
                    .background(.blue)
                    .clipShape(Capsule())
                })
                .padding(.all, 10)
            }
            .ignoresSafeArea(.all)
        }
        .onAppear {
            if let encodedData = UserDefaults.standard.object(forKey: "user"),
                let user = try? JSONDecoder().decode(Player.self, from: encodedData as! Data) {
                self.gameData.players[0] = user
                self.gameData.players[1] = PlayerFactory().getRandomPlayer(playerIndex: 1, without: [user.characterIndex])
                self.gameData.players[2] = PlayerFactory().getRandomPlayer(playerIndex: 2, without: [user.characterIndex, self.gameData.players[1].characterIndex])
            }
            else {
                self.gameData.players = PlayerFactory().getRandomPlayers()
                self.isPresentedSettingView = true
            }
        }
        .fullScreenCover(isPresented: $isPresentedSettingView, onDismiss: {
            print("$isPresentedSettingView onDismiss")
            if let encodedData = try? JSONEncoder().encode(self.gameData.players[0]) {
                UserDefaults.standard.set(encodedData, forKey: "user")
                self.gameData.gameStatus = .updatePlayers
            }
        }, content: {
            SettingView(isPresented: $isPresentedSettingView, gameData: gameData, isFirstLaunch: UserDefaults.standard.object(forKey: "user")  == nil)
        })
        .fullScreenCover(isPresented: $isPresentedPopup, onDismiss: {
            self.popupData.status = .closePopup
        }, content: {
            switch self.popupData.status  {
            case .showSelectCardPopup:
                SelectCardsView(title: self.popupData.title, message: self.popupData.message, players: self.popupData.players, cards: self.popupData.cards, buttonActions: [
                    {}, // 첫번째 카드는 이벤트 없음
                    {
                        isPresentedPopup = false
                        self.popupData.cards = [self.popupData.cards[0], self.popupData.cards[1]]
                        self.popupData.completion(0)
                    }, {
                        isPresentedPopup = false
                        self.popupData.cards = [self.popupData.cards[0], self.popupData.cards[2]]
                        self.popupData.completion(1)
                    }
                ], closeAction: {
                    isPresentedPopup = false
                })
            case .showSelectButtonPopup:
                SelectButtonView(title: self.popupData.title, message: self.popupData.message, players: self.popupData.players, cards: self.popupData.cards, buttonTexts: self.popupData.buttonTexts, buttonActions: [{
                    isPresentedPopup = false
                    self.popupData.completion(0)
                }, {
                    isPresentedPopup = false
                    self.popupData.completion(1)
                }], closeAction: {
                    isPresentedPopup = false
                })
            case .showAutoCloseMessagePopup:
                AutoCloseMessageView(title: self.popupData.title, message: self.popupData.message, players: self.popupData.players,cards: self.popupData.cards)
                    .onAppear{
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            isPresentedPopup = false
                            self.popupData.completion(0)
                        }
                    }
            case .showWinPopup:
                WinnerView(title: self.popupData.title, message: self.popupData.message, players: self.popupData.players, closeAction: {
                    isPresentedPopup = false
                    self.popupData.completion(0)
                })
            case .showSpecialWinPopup:
                SpecialWinView(title: self.popupData.title, message: self.popupData.message, players: self.popupData.players, cards: self.popupData.cards, closeAction: {
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
            Button("OK") { self.isPresentedAlert = false }
        }
        .onChange(of: popupData.status) {
            print("\(#function) change popupStatus: \(popupData.status)")
            if self.popupStatus == popupData.status { return }
            self.popupStatus = popupData.status
            
            switch self.popupStatus {
            case .showSelectCardPopup:
                self.isPresentedPopup = true
            case .showSelectButtonPopup:
                self.isPresentedPopup = true
            case .showSpecialWinPopup:
                self.isPresentedPopup = true
            case .showWinPopup:
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
}

#Preview {
    MainContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
