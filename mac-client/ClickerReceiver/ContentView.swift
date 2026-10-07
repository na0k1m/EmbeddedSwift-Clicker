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
    @Published var customCommitMessage: String = "" {
        didSet {
            UserDefaults.standard.set(customCommitMessage, forKey: "CustomCommitMessage")
        }
    }
    
    init() {
        self.targetFolders = UserDefaults.standard.stringArray(forKey: "TargetFolders") ?? []
        self.customCommitMessage = UserDefaults.standard.string(forKey: "CustomCommitMessage") ?? ""
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
        
        let commitMessage: String
        let trimmedCustom = customCommitMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedCustom.isEmpty {
            commitMessage = "Auto commit via Clicker: \(dateString)"
        } else {
            commitMessage = trimmedCustom
        }
        
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
        ZStack {
            // 앱 전체 반응형 배경
            LinearGradient(gradient: Gradient(colors: [Color(red: 249/255, green: 250/255, blue: 252/255).opacity(0.92), Color(red: 243/255, green: 245/255, blue: 248/255).opacity(0.93), Color(red: 234/255, green: 241/255, blue: 249/255).opacity(0.94)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
            
            // 1. Bluetooth Connection Card
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Color(red: 229/255, green: 240/255, blue: 254/255))
                        .frame(width: 36, height: 36)
                    Image(systemName: "bluetooth")
                        .foregroundColor(Color(red: 8/255, green: 124/255, blue: 240/255))
                        .font(.system(size: 18))
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Bluetooth")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(red: 37/255, green: 40/255, blue: 46/255))
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(bleManager.isConnected ? Color(red: 49/255, green: 188/255, blue: 105/255) : Color.gray)
                            .frame(width: 6, height: 6)
                        Text(bleManager.isConnected ? "Connected to Git Clicker Mini" : "Searching for clicker...")
                            .font(.system(size: 11))
                            .foregroundColor(Color(red: 119/255, green: 126/255, blue: 137/255))
                    }
                }
                
                Spacer()
                
                Toggle("", isOn: $bleManager.isScanningEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
            .padding(14)
            .background(Color.white.opacity(0.44))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.75), lineWidth: 1)
            )
            
            // 2. Target Git Folders Section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Target Git Folders")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(red: 37/255, green: 40/255, blue: 46/255))
                    Spacer()
                    Text("\(gitManager.targetFolders.count) folders")
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 119/255, green: 126/255, blue: 137/255))
                }
                
                VStack(spacing: 0) {
                    if gitManager.targetFolders.isEmpty {
                        Text("No folders added yet.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(Array(gitManager.targetFolders.enumerated()), id: \.element) { index, folder in
                            HStack(spacing: 12) {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 16))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text((folder as NSString).lastPathComponent) // 폴더명만 간략하게
                                        .font(.system(size: 11.5, weight: .regular, design: .monospaced))
                                        .foregroundColor(Color(red: 37/255, green: 40/255, blue: 46/255))
                                    
                                    HStack(spacing: 5) {
                                        Image(systemName: "arrow.branch")
                                            .font(.system(size: 10))
                                            .foregroundColor(Color(red: 119/255, green: 126/255, blue: 137/255))
                                        Text("main")
                                            .font(.system(size: 10.5))
                                            .foregroundColor(Color(red: 119/255, green: 126/255, blue: 137/255))
                                        Text("·")
                                            .font(.system(size: 10))
                                            .foregroundColor(Color(red: 147/255, green: 154/255, blue: 165/255))
                                        Text("Ready to push")
                                            .font(.system(size: 10.5))
                                            .foregroundColor(Color(red: 119/255, green: 126/255, blue: 137/255))
                                    }
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    gitManager.removeFolder(at: IndexSet(integer: index))
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(Color.gray)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            
                            if index < gitManager.targetFolders.count - 1 {
                                Divider()
                                    .padding(.leading, 42)
                                    .background(Color(red: 220/255, green: 225/255, blue: 231/255).opacity(0.5))
                            }
                        }
                    }
                }
                .background(Color.white.opacity(0.72))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(red: 204/255, green: 211/255, blue: 222/255).opacity(0.5), lineWidth: 1)
                )
                
                Button(action: selectFolder) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("Add Folder")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(red: 37/255, green: 40/255, blue: 46/255))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.59))
                    .cornerRadius(7)
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(Color(red: 205/255, green: 211/255, blue: 220/255).opacity(0.69), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // 3. Commit Message Input
            VStack(alignment: .leading, spacing: 10) {
                Text("Commit Message (Auto if empty)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(red: 37/255, green: 40/255, blue: 46/255))
                
                TextField("Leave empty for an automatic message", text: $gitManager.customCommitMessage)
                    .font(.system(size: 12))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.72))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(red: 202/255, green: 209/255, blue: 221/255).opacity(0.56), lineWidth: 1)
                    )
                    .textFieldStyle(PlainTextFieldStyle())
            }
            
            // 4. Test Push Button
            Button(action: { gitManager.pushAll() }) {
                HStack(spacing: 8) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 14))
                    Text("Test Push")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(gradient: Gradient(colors: [Color(red: 36/255, green: 148/255, blue: 255/255), Color(red: 8/255, green: 120/255, blue: 237/255)]), startPoint: .top, endPoint: .bottom)
                )
                .cornerRadius(9)
                .shadow(color: Color(red: 8/255, green: 124/255, blue: 240/255).opacity(0.16), radius: 5, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
            
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 24)
            .frame(maxWidth: 500, maxHeight: .infinity, alignment: .center) // 세로 중앙 정렬로 변경
        }
        .frame(minWidth: 400, minHeight: 450)
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
