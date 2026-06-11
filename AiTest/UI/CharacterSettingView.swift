//
//  CharacterSettingView.swift
//  AiTest
//
//  Created by Joey's Mac mini on 6/11/26.
//

import SwiftUI
import SwiftData

struct CharacterSettingView: View {
    @Binding var isShowCharacterSettingView: Bool
    @Binding var origianlCharacterIndex: Int
    @State var tempCharacterIndex: Int = -1
    
    let columns = [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            VStack() {
                Spacer()
                    .frame(height: 10)
                Text("👩‍🏭 캐릭터 설정!")
                
                ScrollView{
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(0..<GameData.playerNames.count) { i in
                            Button(action: {
                                tempCharacterIndex = i
                            }, label: {
                                Image(Player.imageNamePrefix + String(format: "%02d", i))
                                    .resizable()
                                    .frame(width: 70, height: 70)
                                    .cornerRadius(33)
                                    .padding(4)
                                    .background(tempCharacterIndex == i ? .green : .gray)
                                    .cornerRadius(35)
                            })
                        }
                    }
                    .frame(width: 550)
                    .padding(10)
                }
                
                HStack(spacing: 100){
                    Button("확인") {
                        isShowCharacterSettingView = false
                        origianlCharacterIndex = tempCharacterIndex
                    }
                    .foregroundStyle(.white)
                    .padding()
                    .frame(width: 150)
                    .background(.green)
                    .clipShape(Capsule())
                    
                    Button("취소") {
                        isShowCharacterSettingView = false
                    }
                    .foregroundStyle(.white)
                    .padding()
                    .frame(width: 150)
                    .background(.red)
                    .clipShape(Capsule())
                }
                
                Spacer()
                    .frame(height: 10)
                
            }
            .background(Color.white.opacity(0.9))
            .cornerRadius(20)
        }
        .onAppear {
            tempCharacterIndex = origianlCharacterIndex
        }
    }
}

