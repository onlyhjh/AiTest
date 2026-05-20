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

    func getGameScene(size: CGSize) -> SKScene {
        let scene = GameScene(size: size)
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
            }.edgesIgnoringSafeArea(.vertical)

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
