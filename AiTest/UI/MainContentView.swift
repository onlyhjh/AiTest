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

    @StateObject private var gameData = GameData()
    @StateObject private var popupData = PopupData()
    @State var isPresentedAlert: Bool = false
    @State var isPresentedPopup = false
    @State var isPresentedCharacterSettingPopup = false
    @State var isPresentedSpeedSettingPopup = false
    @State var alertMessage: String? = nil
    @State var popupType: String? = nil
    @State var popupStatus: PopupStatus = .closePopup
    @State var scene: GameScene? // 다시 그리기 방지
    @State var showSpriteView = false
    @State var isStarted = false
    
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
                            let newScene = GameScene(size: geometry.size, gameData: self.gameData, popupData: self.popupData, isPresentedCharacterSettingPopup: $isPresentedCharacterSettingPopup)
                            newScene.scaleMode = .aspectFit
                            scene = newScene
                        }
                        showSpriteView = true
                    }
                }
            }
            .edgesIgnoringSafeArea(.vertical)
            
            if !isStarted {
                Image(.splash)
                    .resizable()
                    .ignoresSafeArea()
            }
            
            HStack {
                Spacer()
                VStack(alignment: .center, spacing: 20, content: {
                    Button("⚙︎") {
                        isPresentedSpeedSettingPopup = true
                    }
                    .foregroundStyle(.white)
                    .font(.largeTitle)
                    Spacer()
                    Button("start") {
                        self.gameData.deckCards = DeckFactory().generateFullDeck()
                        self.gameData.gameStatus = .start
                        self.isStarted = true
                    }
                    .foregroundStyle(.white)
                    .padding()
                    .background(.green)
                    .clipShape(Capsule())
                    Button("save") {
                        if !self.gameData.deckCards.isEmpty, let encoded = try? JSONEncoder().encode(self.gameData.deckCards) {
                            UserDefaults.standard.savedDeckCards = encoded
                            UserDefaults.standard.savedWinnerIndex = self.gameData.winnerIndex
                            self.alertMessage = "save success"
                            self.isPresentedAlert = true
                        }
                    }
                    .foregroundStyle(.white)
                    .padding()
                    .background(.red)
                    .clipShape(Capsule())

                    Button("load") {
                        if let data = UserDefaults.standard.savedDeckCards, let deckCards = try? JSONDecoder().decode([Card].self, from: data) {
                            self.gameData.deckCards = deckCards
                            UserDefaults.standard.lastWinnerIndex = UserDefaults.standard.savedWinnerIndex ?? 0
                            self.gameData.winnerIndex = UserDefaults.standard.savedWinnerIndex ?? 0
                            self.gameData.gameStatus = .start
                            self.isStarted = true
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
            if let encodedData = UserDefaults.standard.user, let user = try? JSONDecoder().decode(Player.self, from: encodedData) {
                self.gameData.players[0] = user
                self.gameData.players[1] = PlayerFactory().getRandomPlayer(playerIndex: 1, without: [user.characterIndex])
                self.gameData.players[2] = PlayerFactory().getRandomPlayer(playerIndex: 2, without: [user.characterIndex, self.gameData.players[1].characterIndex])
            }
            else {
                self.gameData.players = PlayerFactory().getRandomPlayers()
                self.isPresentedCharacterSettingPopup = true
            }
        }
        .fullScreenCover(isPresented: $isPresentedCharacterSettingPopup, onDismiss: {
            if let encodedData = try? JSONEncoder().encode(self.gameData.players[0]) {
                UserDefaults.standard.user = encodedData
                self.gameData.gameStatus = .updatePlayers
            }
        }, content: {
            CharacterSettingView(isPresented: $isPresentedCharacterSettingPopup, gameData: gameData, isFirstLaunch: UserDefaults.standard.user == nil)
        })
        .fullScreenCover(isPresented: $isPresentedSpeedSettingPopup, onDismiss: {
            let gameSpeed = UserDefaults.standard.gameSpeed ?? 0.0
            self.gameData.setCardDuration(gameSpeed: gameSpeed)
            self.popupData.setAutoCloseDuration(gameSpeed: gameSpeed)
        }, content: {
            SpeedSettingView(isPresented: $isPresentedSpeedSettingPopup)
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
                SelectButtonView(title: self.popupData.title, message: self.popupData.message, players: self.popupData.players, cards: self.popupData.cards, button1Text: self.popupData.button1Text, button2Text: self.popupData.button2Text, button1Action: {
                    isPresentedPopup = false
                    self.popupData.completion(0)
                }, button2Action : {
                    isPresentedPopup = false
                    self.popupData.completion(1)
                })
            case .showAutoCloseMessagePopup:
                AutoCloseMessageView(title: self.popupData.title, message: self.popupData.message, players: self.popupData.players,cards: self.popupData.cards)
                    .onAppear{
                        DispatchQueue.main.asyncAfter(deadline: .now() + self.popupData.autoCloseDuration) {
                            isPresentedPopup = false
                            self.popupData.completion(0)
                        }
                    }
            case .showMessagePopup:
                MessageView(title: self.popupData.title, message: self.popupData.message, buttonText: self.popupData.button1Text, buttonAction: {
                    isPresentedPopup = false
                    self.popupData.completion(0)
                })
            case .showWinnerPopup:
                WinnerView(title: self.popupData.title, message: self.popupData.message, players: self.popupData.players, closeAction: {
                    isPresentedPopup = false
                    self.popupData.completion(0)
                })
            case .showSpecialWinnerPopup:
                SpecialWinnerView(title: self.popupData.title, message: self.popupData.message, players: self.popupData.players, cards: self.popupData.cards, closeAction: {
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
            case .closePopup:
                self.isPresentedPopup = false
            case .showAlert:
                self.alertMessage = self.popupData.message
                self.isPresentedAlert = true
            default:
                self.isPresentedPopup = true
            }
        }
    }
}

#Preview {
    MainContentView()
}
