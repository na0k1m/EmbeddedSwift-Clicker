#include "BLEHelper.h"
#include <string.h>
#include "esp_log.h"
#include "nimble/nimble_port.h"
#include "nimble/nimble_port_freertos.h"
#include "host/ble_hs.h"
#include "host/ble_hs_mbuf.h"
#include "host/util/util.h"
#include "services/gap/ble_svc_gap.h"
#include "services/gatt/ble_svc_gatt.h"

#define TAG "BLE_HELPER"
#define DEVICE_NAME "MyClicker"

// GATT UUID 정의 (Service: 0xFFE0, Characteristic: 0xFFE1)
static const ble_uuid16_t gatt_svr_svc_uuid = BLE_UUID16_INIT(0xFFE0);
static const ble_uuid16_t gatt_svr_chr_uuid = BLE_UUID16_INIT(0xFFE1);

static uint16_t click_val_handle;
static uint16_t active_conn_handle = BLE_HS_CONN_HANDLE_NONE;
static uint8_t own_addr_type;

static void ble_app_advertise(void);

static int gatt_svr_chr_access(uint16_t conn_handle, uint16_t attr_handle,
                               struct ble_gatt_access_ctxt *ctxt, void *arg) {
    uint8_t click_val = 0;
    int rc = os_mbuf_append(ctxt->om, &click_val, sizeof(click_val));
    return rc == 0 ? 0 : BLE_ATT_ERR_INSUFFICIENT_RES;
}

static const struct ble_gatt_svc_def gatt_svr_svcs[] = {
    {
        .type = BLE_GATT_SVC_TYPE_PRIMARY,
        .uuid = &gatt_svr_svc_uuid.u,
        .characteristics = (struct ble_gatt_chr_def[]) { {
            .uuid = &gatt_svr_chr_uuid.u,
            .access_cb = gatt_svr_chr_access,
            .flags = BLE_GATT_CHR_F_READ | BLE_GATT_CHR_F_NOTIFY,
            .val_handle = &click_val_handle,
        }, {
            0,
        } },
    },
    {
        0,
    },
};
static int ble_gap_event(struct ble_gap_event *event, void *arg) {
    switch (event->type) {
        case BLE_GAP_EVENT_CONNECT:
            if (event->connect.status == 0) {
                active_conn_handle = event->connect.conn_handle;
                ESP_LOGI(TAG, "Device Connected! Handle=%d", active_conn_handle);
            } else {
                active_conn_handle = BLE_HS_CONN_HANDLE_NONE;
                ble_app_advertise();
            }
            break;
        case BLE_GAP_EVENT_DISCONNECT:
            ESP_LOGI(TAG, "Device Disconnected. Resuming advertising...");
            active_conn_handle = BLE_HS_CONN_HANDLE_NONE;
            ble_app_advertise();
            break;
        case BLE_GAP_EVENT_ADV_COMPLETE:
            ble_app_advertise();
            break;
        default:
            break;
    }
    return 0;
}

static void ble_app_advertise(void) {
    struct ble_gap_adv_params adv_params;
    struct ble_hs_adv_fields fields;
    int rc;

    memset(&fields, 0, sizeof(fields));
    fields.flags = BLE_HS_ADV_F_DISC_GEN | BLE_HS_ADV_F_BREDR_UNSUP;
    fields.name = (uint8_t *)DEVICE_NAME;
    fields.name_len = strlen(DEVICE_NAME);
    fields.name_is_complete = 1;

    // Advertising 데이터에 서비스 UUID 포함
    fields.uuids16 = (ble_uuid16_t[]){ gatt_svr_svc_uuid };
    fields.num_uuids16 = 1;
    fields.uuids16_is_complete = 1;

    rc = ble_gap_adv_set_fields(&fields);
    if (rc != 0) {
        ESP_LOGE(TAG, "Failed to set adv fields: rc=%d", rc);
        return;
    }

    memset(&adv_params, 0, sizeof(adv_params));
    adv_params.conn_mode = BLE_GAP_CONN_MODE_UND;
    adv_params.disc_mode = BLE_GAP_DISC_MODE_GEN;

    rc = ble_gap_adv_start(own_addr_type, NULL, BLE_HS_FOREVER, &adv_params, ble_gap_event, NULL);
    if (rc != 0) {
        ESP_LOGE(TAG, "Failed to start advertising: rc=%d", rc);
        return;
    }
    ESP_LOGI(TAG, "BLE Advertising started as '%s'", DEVICE_NAME);
}

static void ble_on_sync(void) {
    int rc = ble_hs_util_ensure_addr(0);
    if (rc != 0) {
        ESP_LOGE(TAG, "Error ensuring address: rc=%d", rc);
        return;
    }
    rc = ble_hs_id_infer_auto(0, &own_addr_type);
    if (rc != 0) {
        ESP_LOGE(TAG, "Error determining address type: rc=%d", rc);
        return;
    }
    ble_app_advertise();
}

static void ble_host_task(void *param) {
    ESP_LOGI(TAG, "BLE Host Task Started");
    nimble_port_run();
    nimble_port_freertos_deinit();
}

void ble_helper_init(void) {
    nimble_port_init();
    ble_svc_gap_init();
    ble_svc_gatt_init();
    ble_svc_gap_device_name_set(DEVICE_NAME);

    // GATT 테이블 등록
    ble_gatts_count_cfg(gatt_svr_svcs);
    ble_gatts_add_svcs(gatt_svr_svcs);

    ble_hs_cfg.sync_cb = ble_on_sync;
    nimble_port_freertos_init(ble_host_task);
}

void ble_helper_send_click(void) {
    if (active_conn_handle == BLE_HS_CONN_HANDLE_NONE) {
        ESP_LOGW(TAG, "No device connected to send click.");
        return;
    }

    uint8_t click_data = 1;
    struct os_mbuf *om = ble_hs_mbuf_from_flat(&click_data, sizeof(click_data));
    if (om != NULL) {
        int rc = ble_gatts_notify_custom(active_conn_handle, click_val_handle, om);
        if (rc == 0) {
            ESP_LOGI(TAG, "Notification Sent: [Click 1]");
        } else {
            ESP_LOGE(TAG, "Failed to send notification: rc=%d", rc);
        }
    }
}

bool ble_helper_is_connected(void) {
    return active_conn_handle != BLE_HS_CONN_HANDLE_NONE;
}
