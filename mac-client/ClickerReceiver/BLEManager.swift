//
//  BLEManager.swift
//  ClickerReceiver
//
//  Created by 김나영 on 9/8/26.
//


import CoreBluetooth
import AppKit
internal import Combine

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var centralManager: CBCentralManager!
    var clickerPeripheral: CBPeripheral?
    
    @Published var isConnected = false
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // 블루투스가 켜져 있으면 'MyClicker' 서비스(FFE0) 찾기 시작
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("🔍 클리커 스캔 시작...")
            centralManager.scanForPeripherals(withServices: [CBUUID(string: "FFE0")], options: nil)
        }
    }
    
    // 기기를 찾으면 연결
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("🔗 클리커 발견! 연결 시도 중...")
        clickerPeripheral = peripheral
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
    }
    
    // 연결 성공 시 특성(FFE1) 찾기
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("✅ 연결 완료!")
        DispatchQueue.main.async { self.isConnected = true }
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: "FFE0")])
    }
    
    // 연결 끊기면 다시 스캔
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("❌ 연결 끊김. 다시 스캔합니다...")
        DispatchQueue.main.async { self.isConnected = false }
        centralManager.scanForPeripherals(withServices: [CBUUID(string: "FFE0")], options: nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics([CBUUID(string: "FFE1")], for: service)
            }
        }
    }
    
    // 알림(Notify) 활성화
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == CBUUID(string: "FFE1") {
                    peripheral.setNotifyValue(true, for: characteristic)
                    print("📬 신호 수신 준비 완료!")
                }
            }
        }
    }
    
    // 버튼을 눌러서 0x01 데이터가 들어왔을 때 실행할 동작
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let value = characteristic.value, let firstByte = value.first, firstByte == 1 {
            print("🔘 클리커 눌림!")
            DispatchQueue.main.async {
                self.openYouTubeMusic()
            }
        }
    }
    
    // 유튜브 뮤직 열기 함수
    func openYouTubeMusic() {
        let urlString = "https://youtu.be/PGADim6UzHE?si=i9N4A7R_DM35W87a"
        
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}
