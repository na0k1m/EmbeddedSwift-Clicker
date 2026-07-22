# SPDX-FileCopyrightText: 2026 Espressif Systems (Shanghai) CO LTD
# SPDX-License-Identifier: Unlicense OR CC0-1.0
import pytest
from pytest_embedded import Dut


@pytest.mark.generic
@pytest.mark.temp_skip_ci(
    targets=["esp32", "esp32s2", "esp32s3"],
    reason="Swift is only supported on RISC-V targets",
)
def test_swift(dut: Dut) -> None:
    dut.expect('Hello from Swift!')
