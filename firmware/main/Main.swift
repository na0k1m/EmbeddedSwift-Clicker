//===----------------------------------------------------------------------===//
// my-clicker: 버튼 입력 테스트
//===----------------------------------------------------------------------===//

@_cdecl("app_main")
func main() {
    print("🚀 클릭커 프로젝트 시작! 블루투스 세팅 중...")

    // 1. NVS (비휘발성 메모리) 초기화
    var ret = nvs_flash_init()
    if ret == 259 /* ESP_ERR_NVS_NO_FREE_PAGES */ || ret == 260 /* ESP_ERR_NVS_NEW_VERSION_FOUND */ {
        nvs_flash_erase()
        ret = nvs_flash_init()
    }

    // 2. 블루투스 GATT 서비스 등록 및 Advertising 시작
    ble_helper_init()

    // 3. 버튼 핀 설정 (GPIO 9번 - ESP32-C6 기본 내장 버튼 또는 0번)
    let buttonPin = gpio_num_t(0)
    gpio_reset_pin(buttonPin)
    gpio_set_direction(buttonPin, GPIO_MODE_INPUT)
    gpio_pullup_en(buttonPin)

    print("📡 블루투스 신호 송출 중... 주변 기기에서 'MyClicker'를 찾아보세요!")

    var lastButtonState: Int32 = 1

    while true {
        let currentState = gpio_get_level(buttonPin)

        // 버튼을 누른 순간 (1 -> 0 변화 감지)
        if lastButtonState == 1 && currentState == 0 {
            print("🔘 버튼 눌림 감지! 블루투스로 신호 전송...")
            ble_helper_send_click()
        }

        lastButtonState = currentState
        
        // 20ms 대기 (디바운싱 효과)
        vTaskDelay(20 / (1000 / UInt32(configTICK_RATE_HZ)))
    }
}
