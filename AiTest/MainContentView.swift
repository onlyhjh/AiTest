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
    @State var showSavedAlert: Bool = false
    
    func getGameScene(size: CGSize) -> SKScene {
        let scene = GameScene(size: size, gameData: self.gameData)
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
            .onChange(of: gameData.gameStatus) {
                print("change gameStatus: \(gameData.gameStatus)")
            }
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
                            self.showSavedAlert = true
                        }
                    }
                    Button("load") {
                        if let data = UserDefaults.standard.data(forKey: "deckCards"), let deckCards = try? JSONDecoder().decode([Card].self, from: data) {
                            self.gameData.deckCards = deckCards
                            self.gameData.gameStatus = .start
                        }
                    }
                })
            }
            .ignoresSafeArea(.all)
            .alert("", isPresented: self.$showSavedAlert) {
                Button("OK") { showSavedAlert = false}
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
