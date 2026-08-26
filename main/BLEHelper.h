#pragma once

#ifdef __cplusplus
extern "C" {
#endif

void ble_helper_init(void);
void ble_helper_send_click(void);
bool ble_helper_is_connected(void);

#ifdef __cplusplus
}
#endif
