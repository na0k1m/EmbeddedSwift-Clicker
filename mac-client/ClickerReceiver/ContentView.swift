//
//  ContentView.swift
//  ClickerReceiver
//
//  Created by 김나영 on 9/8/26.
//

import Foundation
import SwiftUI

struct ContentView: View {
    @StateObject var bleManager = BLEManager()
    
    var body: some View {
        VStack(spacing: 20) {
            
            // 블루투스 활성화/비활성화 토글
            Toggle(isOn: $bleManager.isScanningEnabled) {
                Text(bleManager.isScanningEnabled ? "블루투스 켜짐" : "블루투스 꺼짐")
                    .font(.headline)
            }
            .toggleStyle(.switch)
            .padding(.horizontal, 40)
            
            Divider().padding(.horizontal, 20)
            
            Text(bleManager.isConnected ? "✅ 클리커 연결됨" : "📡 클리커 찾는 중...")
                .font(.title)
                .foregroundColor(bleManager.isConnected ? .green : .gray)
                .opacity(bleManager.isScanningEnabled ? 1.0 : 0.3) // 꺼져있을 땐 흐리게
            
            Text("보드의 버튼을 누르면 유튜브 뮤직이 열립니다.")
                .font(.subheadline)
        }
        .frame(width: 400, height: 200)
    }
}

#Preview {
    ContentView()
}
