//
//  CharacterIconSettingView.swift
//  AiTest
//
//  Created by Joey's Mac mini on 6/11/26.
//

import SwiftUI
import SwiftData

struct CharacterIconSettingView: View {
    @Binding var isPresented: Bool
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
                        isPresented = false
                        origianlCharacterIndex = tempCharacterIndex
                    }
                    .foregroundStyle(.white)
                    .padding()
                    .frame(width: 150)
                    .background(.green)
                    .clipShape(Capsule())
                    
                    Button("취소") {
                        isPresented = false
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
            .padding(20)
            .background(.white.opacity(0.9))
            .cornerRadius(20)
        }
        .presentationBackground(.black.opacity(0.2))
        .onAppear {
            tempCharacterIndex = origianlCharacterIndex
        }
    }
}

