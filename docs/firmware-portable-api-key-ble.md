# Portable device API key provisioning over BLE

This document specifies how the **Luftdaten.at mobile app** writes a Datahub API key to **portable BLE devices** (Air Badge, Air aRound, Air Bike) when the device is not yet registered in Datahub and has no `api_key` configured.

Firmware implementers (CircuitPython [`luftdaten-at/firmware`](https://github.com/luftdaten-at/firmware), ESP32 [`luftdaten-at/firmware-badge`](https://github.com/luftdaten-at/firmware-badge)) should implement the receive path described here so first connect provisioning works end-to-end.

---

## Purpose

On first successful BLE connect, the app:

1. Checks Datahub (`GET /api/v1/devices/name/?device=<chip_id>`).
2. If the device is **not** registered (`404`), generates a 32-character API key (when the badge has none).
3. Registers the device in Datahub (`POST /api/v1/devices/status/`).
4. Sends the API key to the device over BLE (this document).
5. Reads back `device_info` to verify the key is exposed to the central.

App implementation: [`BadgeDatahubRegistration`](../../lib/features/devices/logic/badge_datahub_registration.dart), [`PortableApiKeyBleCodec`](../../lib/features/devices/logic/portable_api_key_ble_codec.dart).

---

## Transport

| Item | Value |
|------|--------|
| Service UUID | `0931b4b5-2917-4a8d-9e72-23103c09ac29` |
| Characteristic | `030ff8b1-1e45-4ae6-bf36-3bca4c38cdba` (`trigger_reading_characteristic_2`) |
| Properties | WRITE, WRITE_NO_RESPONSE (same as existing measure commands) |

The app writes a **single** command buffer per provisioning attempt (no fragmentation required for a 32-byte key).

---

## Command byte

Add to firmware `BleCommands` ([`enums.py`](https://github.com/luftdaten-at/firmware/blob/main/firmware/enums.py)):

| Value | Name | Models |
|-------|------|--------|
| `0x09` | `SET_PORTABLE_CONFIGURATION` | Air Badge, Air aRound, Air Bike (portable models) |

Handle in each model’s `receive_command()` (or a shared portable base class), analogous to Air Station `0x06`.

---

## Payload format

After the leading command byte `0x09`, the payload is one **TLV record** using the same string encoding as Air Station configuration ([`ble-characteristics.md`](https://github.com/luftdaten-at/firmware/blob/main/docs/ble-characteristics.md)):

```text
[ 0x09 ] [ flag: u8 ] [ length: u8 ] [ value: length bytes UTF-8 ]
```

For API key provisioning:

| Field | Value |
|-------|--------|
| Command | `0x09` |
| Flag | `20` (`0x14`) — `AirstationConfigFlags.API_KEY` |
| Value | UTF-8 API key string |

**Example** (key `abcdefghijklmnopqrstuvwxyz012345`):

```text
09 14 20 61 62 63 64 65 66 67 68 69 6a 6b 6c 6d 6e 6f 70 71 72 73 74 75 76 77 78 79 7a 30 31 32 33 34 35
```

### Validation (firmware)

- Reject if `length < 16` or `length > 255`.
- Ignore unknown TLV flags in the same buffer for forward compatibility (app currently sends only flag `20`).
- Do not accept empty keys.

The app generates keys with the same rules as firmware boot-time generation: **32 characters**, charset `a-z` + `0-9` ([`Config.generate_random_api_key()`](https://github.com/luftdaten-at/firmware/blob/main/firmware/config.py)).

---

## Persistent storage (consistent key name)

The logical setting name is always **`api_key`**, regardless of platform:

### CircuitPython (Air aRound / Air Bike / shared portable code)

```python
Config.settings['api_key'] = decoded_utf8_key
```

`Config.settings` is an `AutoSaveDict` that persists to **`/settings.toml`** on CIRCUITPY ([`config.py`](https://github.com/luftdaten-at/firmware/blob/main/firmware/config.py)). This is the **same** storage used when firmware generates a key at first boot.

Do **not** store the key in a separate ad-hoc file or RAM-only variable.

### firmware-badge (ESP32)

Persist under the configuration key **`api_key`** in device NVS / flash settings (exact file or partition layout is implementation-specific). The name must match CircuitPython and Datahub ingest (`device.apikey` in JSON).

---

## Post-write behavior (firmware)

After a successful write:

1. **Persist** `api_key` as above.
2. **Refresh `device_info_characteristic`** so the central can read the key:
   - Prefer the **JSON path** (UTF-8 JSON starting with `{`) including `device.apikey` / `apikey`, matching [`LdProductModel.get_info()`](https://github.com/luftdaten-at/firmware/blob/main/firmware/models/ld_product_model.py).
   - Binary `device_info` with trailing length-prefixed key is also acceptable for legacy readers.
3. Optionally append a status log line (level `1`, message e.g. `API key provisioned via BLE`).

No reboot is required unless your stack cannot refresh GATT values live.

---

## Verification (central / app)

After writing, the app calls `refreshDeviceInfo` and expects:

- `BleJsonParser.parseApiKey()` to return the provisioned key from `device_info` JSON, **or**
- Binary `device_info` suffix parse (protocol v2 fallback).

The app then stores the key in secure storage ([`StationSecretsStore`](../../lib/features/devices/logic/station_secrets_store.dart)) keyed by BLE broadcast name.

---

## Security note

BLE provisioning is **unauthenticated** (same as other command writes). The app only sends keys while the user has an active connection from the Luftdaten.at app. Treat the API key as a credential on the BLE link and in `device_info` read-back.

---

## Related documentation

- App BLE overview: [bluetooth.md](bluetooth.md) (Air Badge provisioning section)
- Datahub registration flow: [external-apis.md](external-apis.md)
- Air Station TLV flag `20` on command `0x06`: [firmware ble-characteristics.md](https://github.com/luftdaten-at/firmware/blob/main/docs/ble-characteristics.md)
