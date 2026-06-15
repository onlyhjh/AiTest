//
//  SettingView.swift
//  AiTest
//
//  Created by Joey's Mac mini on 6/10/26.
//

import SwiftUI
import SwiftData

struct SettingView: View {
    @Binding var isPresented: Bool
    @State var gameData: GameData
    var isFirstLaunch: Bool
    @State var isShowCharacterSettingView: Bool = false
    @State var userName: String = ""
    @State var imageName: String = ""
    @State var characterIndex: Int = 0
    @State var alertMessage: String = ""
    @State var isPresentedAlert: Bool = false
    
    var body: some View {
        ZStack {
            Image(.splash)
                .resizable()
                .ignoresSafeArea()
            
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 10) {
                Text(self.isFirstLaunch ? "🥹 환영합니다!!!" : "👩‍🏭 설정!")
                    .font(.title)
                    .padding()
                Text("이름과 캐릭터를 설정하세요")
                    .font(.caption)
                HStack(spacing: 10) {
                    Button {
                        isShowCharacterSettingView = true
                        hideKeyboard()
                    } label: {
                        Image(imageName)
                            .resizable()
                            .frame(width: 50, height: 50)
                            .cornerRadius(24)
                            .padding(2)
                            .background(.green)
                            .cornerRadius(25)
                    }
                    HStack {
                        TextField("이름을 입력해 주세요", text: $userName)
                            .padding(10)
                            .frame(width: 200, height: 50)
                            .onChange(of: userName) {
                                if userName.count > 5 {
                                    userName = String(userName.prefix(5))
                                }
                            }
                    }
                    .background(.pink.opacity(0.1))
                    .cornerRadius(10)
                }
                HStack(spacing: 10) {
                    Button("확인") {
                        hideKeyboard()
                        if userName.isEmpty {
                            isPresentedAlert = true
                            alertMessage = "이름을 입력해 주세요"
                        }
                        else {
                            self.gameData.players[0].name = userName
                            self.gameData.players[0].imageName = imageName
                            self.gameData.players[0].characterIndex = characterIndex
                            
                            // 컴퓨터 player와 캐릭터 겹치지 안도록 조정
                            if self.gameData.players[1].characterIndex == characterIndex {
                                self.gameData.players[1] = PlayerFactory().getRandomPlayer(playerIndex: 1, without: [characterIndex, self.self.gameData.players[2].characterIndex])
                            }
                            if self.gameData.players[2].characterIndex == characterIndex {
                                self.gameData.players[2] = PlayerFactory().getRandomPlayer(playerIndex: 2, without: [characterIndex, self.gameData.players[1].characterIndex])
                            }
                            
                            isPresented = false
                        }
                    }
                    .foregroundStyle(.white)
                    .padding()
                    .frame(width: 150)
                    .background(.green)
                    .clipShape(Capsule())
                    
                    if !self.isFirstLaunch {
                        Button("취소") {
                            hideKeyboard()
                            isPresented = false
                        }
                        .foregroundStyle(.white)
                        .padding()
                        .frame(width: 150)
                        .background(.red)
                        .clipShape(Capsule())
                    }
                }
                .padding(10)
                
                Spacer()
                    .frame(height: 5)
            }
            .background(Color.white.opacity(0.9))
            .cornerRadius(20)
            
            if isShowCharacterSettingView {
                CharacterSettingView(isShowCharacterSettingView: $isShowCharacterSettingView, origianlCharacterIndex: $characterIndex)
            }
        }
        .alert(self.alertMessage, isPresented: self.$isPresentedAlert) {
            Button("OK") { self.isPresentedAlert = false }
        }
        .onAppear{
            characterIndex = self.gameData.players[0].characterIndex
            userName = self.gameData.players[0].name
            imageName = self.gameData.players[0].imageName
        }
        .onChange(of: characterIndex) { oldValue, newValue in
            // 사용자가 수정한 이름이 기존이름을 그대로 쓰는지 확인, 다르면 사용자 설정 커스텀 이름 사용
            if GameData.playerNames.contains(where: { $0 == self.gameData.players[0].name }) || self.userName.isEmpty {
                userName = GameData.playerNames[characterIndex]
                self.gameData.players[0].name = userName
            }
            else {
                userName = self.gameData.players[0].name
            }
            imageName = Player.imageNamePrefix + String(format: "%02d", characterIndex)
        }
    }
}
