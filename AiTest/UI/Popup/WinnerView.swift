//
//  WinnerView.swift
//  AiTest
//
//  Created by Joey's Mac mini on 5/27/26.
//


import SwiftUI

public struct WinnerView: View {
    
    var title: String?
    var message: String?
    var players: [Player]
    var closeAction: (() -> Void)
    
    let title3 = "kim"
    
    init(title: String?, message: String?, players: [Player], closeAction: @escaping () -> Void) {
        self.title = title
        self.message = message
        self.players = players
        self.closeAction = closeAction
    }
    
    public var body: some View {
        ZStack {
            VStack(spacing: 20) {
                HStack {
                    VStack(spacing: 20) {
                        // Winner
                        VStack(spacing: 10) {
                            HStack {
                                Image(players[0].imageName)
                                    .resizable()
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(30)
                                
                                VStack(spacing: 5) {
                                    HStack(spacing: 10) {
                                        Text(players[0].name)
                                            .font(.title)
                                            .bold()
                                        Text("승")
                                            .font(.title)
                                            .bold()
                                            .foregroundStyle(.white)
                                            .background(.pink)
                                            .clipShape(Circle())
                                    }
                                    Text("+\(players[2].finalScore)만냥")
                                        .font(.title3)
                                        .bold()
                                        .padding(7)
                                        .foregroundStyle(.white)
                                        .background(.blue)
                                        .clipShape(Capsule())
                                }
                            }
                            HStack(spacing: 10) {
                                Text(players[0].goCount > 2 ? "\(players[0].goCount)고x\(Int(pow(2.0, Double(players[0].goCount - 2))))" : "3고x2")
                                    .font(.caption)
                                    .bold()
                                    .padding(5)
                                    .foregroundStyle(players[0].goCount > 2 ? .red : .white.opacity(0.5))
                                    .background(players[0].goCount > 2 ? .yellow: .gray.opacity(0.5))
                                Text(players[0].waveCount > 0 ? "흔들기x\(Int(pow(2.0, Double(players[0].waveCount))))" : "흔들기x2")
                                    .font(.caption)
                                    .bold()
                                    .padding(5)
                                    .foregroundStyle(players[0].waveCount > 0 ? .red : .white.opacity(0.5))
                                    .background(players[0].waveCount > 0 ? .yellow: .gray.opacity(0.5))
                                Text("나가리x2")
                                    .font(.caption)
                                    .bold()
                                    .padding(5)
                                    .foregroundStyle(players[0].wasNagari ? .red : .white.opacity(0.5))
                                    .background(players[0].wasNagari ? .yellow: .gray.opacity(0.5))
                                Text("멍텅구리x2")
                                    .font(.caption)
                                    .bold()
                                    .padding(5)
                                    .foregroundStyle(players[0].isMungtungguri ? .red : .white.opacity(0.5))
                                    .background(players[0].isMungtungguri ? .yellow: .gray.opacity(0.5))
                            }
                        }// winner
                        
                        HStack(spacing: 10) {
                            HStack(spacing: 30) {
                                // Player1
                                VStack(spacing: 10) {
                                    HStack(spacing: 5) {
                                        Image(players[1].imageName)
                                            .resizable()
                                            .frame(width: 34, height: 34)
                                            .cornerRadius(17)
                                        VStack(spacing: 0) {
                                            HStack(spacing: 5) {
                                                Text(players[1].name)
                                                    .font(.title3)
                                                    .bold()
                                                Text("패")
                                                    .font(.title3)
                                                    .bold()
                                                    .foregroundStyle(.white)
                                                    .background(.red)
                                                    .clipShape(Circle())
                                                Spacer()
                                            }
                                            HStack(spacing: 5) {
                                                Text("-\(players[1].finalScore)만냥")
                                                    .font(.title3)
                                                    .bold()
                                                    .padding(5)
                                                    .foregroundStyle(.white)
                                                    .background(.blue)
                                                    .clipShape(Capsule())
                                                Spacer()
                                            }
                                        }
                                    }
                                    HStack(spacing: 10) {
                                        Text("광박x2")
                                            .font(.caption)
                                            .bold()
                                            .padding(5)
                                            .foregroundStyle(players[1].isGwangBak ? .red : .white.opacity(0.5))
                                            .background(players[1].isGwangBak ? .yellow: .gray.opacity(0.5))
                                        Text("피박x2")
                                            .font(.caption)
                                            .bold()
                                            .padding(5)
                                            .foregroundStyle(players[1].isPiBak ? .red : .white.opacity(0.5))
                                            .background(players[1].isPiBak ? .yellow: .gray.opacity(0.5))
                                        Text("고박x2")
                                            .font(.caption)
                                            .bold()
                                            .padding(5)
                                            .foregroundStyle(players[1].isGoBak ? .red : .white.opacity(0.5))
                                            .background(players[1].isGoBak ? .yellow: .gray.opacity(0.5))
                                    }
                                }
                                .frame(width: 200)
                                
                                // Player1
                                VStack(spacing: 10) {
                                    HStack(spacing: 5) {
                                        Image(players[2].imageName)
                                            .resizable()
                                            .frame(width: 34, height: 34)
                                            .cornerRadius(17)
                                        VStack(spacing: 0) {
                                            HStack(spacing: 5) {
                                                Text(players[2].name)
                                                    .font(.title3)
                                                    .bold()
                                                Text("패")
                                                    .font(.title3)
                                                    .bold()
                                                    .foregroundStyle(.white)
                                                    .background(.red)
                                                    .clipShape(Circle())
                                                Spacer()
                                            }
                                            HStack(spacing: 5) {
                                                Text("-\(players[2].finalScore)만냥")
                                                    .font(.title3)
                                                    .bold()
                                                    .padding(5)
                                                    .foregroundStyle(.white)
                                                    .background(.blue)
                                                    .clipShape(Capsule())
                                                Spacer()
                                            }
                                        }
                                    }
                                    
                                    HStack(spacing: 10) {
                                        Text("광박x2")
                                            .font(.caption)
                                            .bold()
                                            .padding(5)
                                            .foregroundStyle(players[2].isGwangBak ? .red : .white.opacity(0.5))
                                            .background(players[2].isGwangBak ? .yellow: .gray.opacity(0.5))
                                        Text("피박x2")
                                            .font(.caption)
                                            .bold()
                                            .padding(5)
                                            .foregroundStyle(players[2].isPiBak ? .red : .white.opacity(0.5))
                                            .background(players[2].isPiBak ? .yellow: .gray.opacity(0.5))
                                        Text("고박x2")
                                            .font(.caption)
                                            .bold()
                                            .padding(5)
                                            .foregroundStyle(players[2].isGoBak ? .red : .white.opacity(0.5))
                                            .background(players[2].isGoBak ? .yellow: .gray.opacity(0.5))
                                    }
                                }
                                .frame(width: 200)
                            }
                        }
                    }
                    // Score
                    VStack() {
                        Spacer().frame(height: 10)
                        Text("총\(players[0].baseScore)점")
                            .font(.headline)
                            .bold()
                            .foregroundColor(.white)
                        VStack(spacing: 3) {
                            if players[0].gwangScore > 0 {
                                HStack() {
                                    Text("광")
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.white)
                                        .frame(width: 50)
                                    Spacer()
                                    Text("\(players[0].gwangScore)점")
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.white)
                                }
                                .frame(width: 100)
                            }
                            if players[0].yeolScore > 0 {
                                HStack() {
                                    Text("열")
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.white)
                                        .frame(width: 50)
                                    Spacer()
                                    Text("\(players[0].yeolScore)점")
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.white)
                                }
                                .frame(width: 100)
                            }
                            if players[0].ttiScore > 0 {
                                HStack() {
                                    Text("띠")
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.white)
                                        .frame(width: 50)
                                    Spacer()
                                    Text("\(players[0].ttiScore)점")
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.white)
                                }
                                .frame(width: 100)
                            }
                            if players[0].piScore > 0 {
                                HStack() {
                                    Text("피")
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.white)
                                        .frame(width: 50)
                                    Spacer()
                                    Text("\(players[0].piScore)점")
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.white)
                                }
                                .frame(width: 100)
                            }
                            if players[0].chungdanScore > 0 {
                                HStack() {
                                    Text("청단")
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.white)
                                        .frame(width: 50)
                                    Spacer()
                                    Text("\(players[0].chungdanScore)점")
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.white)
                                }
                                .frame(width: 100)
                            }
                            if players[0].hongdanScore > 0 {
                                HStack() {
                                    Text("홍단")
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.white)
                                        .frame(width: 50)
                                    Spacer()
                                    Text("\(players[0].hongdanScore)점")
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.white)
                                }
                                .frame(width: 100)
                            }
                            if players[0].chodanScore > 0 {
                                HStack() {
                                    Text("초단")
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.white)
                                        .frame(width: 50)
                                    Spacer()
                                    Text("\(players[0].chodanScore)점")
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.white)
                                }
                                .frame(width: 100)
                            }
                            if players[0].godoriScore > 0 {
                                HStack() {
                                    Text("고도리")
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.white)
                                        .frame(width: 50)
                                    Spacer()
                                    Text("\(players[0].godoriScore)점")
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.white)
                                }
                                .frame(width: 100)
                            }
                        }
                        .frame(width: 130 , height: 220)
                        .background(.white.opacity(0.5))
                    }
                    .background(.black.opacity(0.8))
                    .cornerRadius(20)
                    .padding(.horizontal, 20)
                }
                Button("확인") {
                    closeAction()
                }
                .foregroundStyle(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(.green)
                .clipShape(Capsule())
            } // inner frame
            .frame(width: 650)
            .padding(20)
            .background(.white.opacity(0.8))
            .cornerRadius(20)
        }
        .ignoresSafeArea()
        .presentationBackground(.black.opacity(0.4))
    }
}

#Preview {
    ZStack {
        Color.tableBG
            .edgesIgnoringSafeArea(.all)
        WinnerView(title: "OOO승", message: "message", players: PlayerFactory().getRandomPlayers(), closeAction: {
        })
    }
    
}
