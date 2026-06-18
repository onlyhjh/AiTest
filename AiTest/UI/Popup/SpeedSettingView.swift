//
//  SpeedSettingView.swift
//  AiTest
//
//  Created by Joey's Mac mini on 6/11/26.
//

import SwiftUI
import SwiftData

struct SpeedSettingView: View {
    @Binding var isPresented: Bool
    @State private var sliderValue: Double = 0
    
    
    var body: some View {
        ZStack {
            Image(.splash)
                .resizable()
                .ignoresSafeArea()
            
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack() {
                Spacer()
                    .frame(height: 10)
                Text("👩‍🏭 스피드 설정!")
                Spacer()
                    .frame(height: 30)
                Slider(value: $sliderValue, in: -1...1)
                    .frame(width: 300)
                HStack {
                    Text("천천히")
                        .font(.caption)
                    Spacer()
                    Text("빨리")
                        .font(.caption)
                }
                .frame(width: 300)
                
                HStack(spacing: 20){
                    Button("확인") {
                        isPresented = false
                        UserDefaults.standard.gameSpeed = sliderValue
                        print("\(#function) gameSpeed: \(UserDefaults.standard.gameSpeed)")
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
            .background(Color.white.opacity(0.9))
            .cornerRadius(20)
        }
        .onAppear {
            sliderValue = UserDefaults.standard.gameSpeed ?? 0
        }
    }
}

