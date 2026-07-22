//===----------------------------------------------------------------------===//
// my-clicker: 버튼 입력 테스트
//===----------------------------------------------------------------------===//

@_cdecl("app_main")
func main() {
    print("클릭커 프로젝트 시작! BOOT 버튼을 눌러보세요.")

    let buttonPin = gpio_num_t(9) // XIAO ESP32-C6의 BOOT 버튼 핀
    
    // 1. 버튼 핀을 '입력(Input)' 모드로 설정
    gpio_reset_pin(buttonPin)
    gpio_set_direction(buttonPin, GPIO_MODE_INPUT)
    
    // 내부 풀업 저항 켜기 (버튼을 안 누르면 1, 누르면 0이 되도록 설정)
    gpio_set_pull_mode(buttonPin, GPIO_PULLUP_ONLY)

    var wasPressed = false

    // 2. 무한 루프를 돌며 버튼 상태 감시
    while true {
        let isPressed = gpio_get_level(buttonPin) == 0 // 0이면 눌린 상태

        if isPressed && !wasPressed {
            print("👇 버튼이 눌렸습니다.")
            wasPressed = true
        } else if !isPressed && wasPressed {
            print("👆 버튼에서 손을 뗐습니다.")
            wasPressed = false
        }
        
        // 너무 빠르게 반복하지 않도록 약간의 딜레이 (디바운싱 효과)
        vTaskDelay(50 / (1000 / UInt32(configTICK_RATE_HZ)))
    }
}

//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

// The code will blink an LED on GPIO8. To change the pin, modify Led(gpioPin: 8)
//@_cdecl("app_main")
//func main() {
//  print("Hello from Swift on ESP32-C6!")
//
//  var ledValue: Bool = false
//  let blinkDelayMs: UInt32 = 500
//  let led = Led(gpioPin: 8)
//
//  while true {
//    led.setLed(value: ledValue)
//    ledValue.toggle()  // Toggle the boolean value
//    vTaskDelay(blinkDelayMs / (1000 / UInt32(configTICK_RATE_HZ)))
//  }
//}
