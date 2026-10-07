//
//  ContentView.swift
//  ClickerReceiver
//
//  Created by 김나영 on 9/8/26.
//

import Foundation
import SwiftUI
import AppKit
internal import Combine

class GitManager: ObservableObject {
    @Published var targetFolders: [String] = [] {
        didSet {
            UserDefaults.standard.set(targetFolders, forKey: "TargetFolders")
        }
    }
    
    init() {
        self.targetFolders = UserDefaults.standard.stringArray(forKey: "TargetFolders") ?? []
    }
    
    func addFolder(_ path: String) {
        if !targetFolders.contains(path) {
            targetFolders.append(path)
        }
    }
    
    func removeFolder(at offsets: IndexSet) {
        targetFolders.remove(atOffsets: offsets)
    }
    
    func pushAll() {
        print("🚀 등록된 모든 폴더에 대해 git push 시작...")
        for folder in targetFolders {
            push(at: folder)
        }
        print("✅ 모든 폴더 push 작업 완료!")
    }
    
    private func push(at path: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = dateFormatter.string(from: Date())
        let commitMessage = "Auto commit via Clicker: \(dateString)"
        
        let script = """
        git add .
        git commit -m "\(commitMessage)"
        git push
        """
        
        let task = Process()
        task.currentDirectoryPath = path
        
        // 환경 변수 설정 (git이 시스템 경로에 있다고 가정)
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/usr/bin:/usr/local/bin:/opt/homebrew/bin:" + (env["PATH"] ?? "")
        task.environment = env
        
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", script]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                if task.terminationStatus == 0 {
                    print("[\(path)] ✅ 푸시 성공:\n\(output)")
                } else {
                    print("[\(path)] ⚠️ 완료 (상태코드 \(task.terminationStatus)):\n\(output)")
                }
            }
        } catch {
            print("[\(path)] ❌ 명령어 실행 실패: \(error)")
        }
    }
}

struct ContentView: View {
    @StateObject var bleManager = BLEManager()
    @StateObject var gitManager = GitManager()
    
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
            
            Divider().padding(.horizontal, 20)
            
            // Git 푸시 타겟 UI
            VStack(alignment: .leading, spacing: 10) {
                Text("Git 푸시 타겟 폴더")
                    .font(.headline)
                
                List {
                    ForEach(gitManager.targetFolders, id: \.self) { folder in
                        Text(folder)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .onDelete(perform: gitManager.removeFolder)
                }
                .frame(height: 100)
                .border(Color.gray.opacity(0.3))
                
                HStack {
                    Button(action: selectFolder) {
                        Label("폴더 추가", systemImage: "folder.badge.plus")
                    }
                    
                    Spacer()
                    
                    Button(action: { gitManager.pushAll() }) {
                        Label("테스트 푸시 (ESP버튼)", systemImage: "paperplane.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(width: 450, height: 420)
        .onAppear {
            bleManager.onPushTriggered = {
                gitManager.pushAll()
            }
        }
    }
    
    func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK {
            if let url = panel.url {
                gitManager.addFolder(url.path)
            }
        }
    }
}

#Preview {
    ContentView()
}
