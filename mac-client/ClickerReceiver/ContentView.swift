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
            Text(bleManager.isConnected ? "✅ 클리커 연결됨" : "📡 클리커 찾는 중...")
                .font(.title)
                .foregroundColor(bleManager.isConnected ? .green : .gray)
            
            Text("보드의 버튼을 누르면 유튜브 뮤직이 열립니다.")
                .font(.subheadline)
        }
        .frame(width: 400, height: 200)
    }
}

#Preview {
    ContentView()
}
