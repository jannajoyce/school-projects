#include "dht.h"
#include <util/delay.h>

static int8_t dht_read(uint8_t *data) {
    uint8_t bit = 0, byte = 0, timeout = 0;

    // Send start signal
    DHT_DDR |= (1 << DHT_INPUTPIN);
    DHT_PORT &= ~(1 << DHT_INPUTPIN);
    _delay_ms(20);
    DHT_PORT |= (1 << DHT_INPUTPIN);
    _delay_us(40);
    DHT_DDR &= ~(1 << DHT_INPUTPIN);

    // Wait for response
    while (!(DHT_PIN & (1 << DHT_INPUTPIN))) {
        if (++timeout > DHT_TIMEOUT) return -1;
    }
    timeout = 0;
    while (DHT_PIN & (1 << DHT_INPUTPIN)) {
        if (++timeout > DHT_TIMEOUT) return -1;
    }

    // Read 40 bits (5 bytes)
    for (byte = 0; byte < 5; byte++) {
        for (bit = 0; bit < 8; bit++) {
            while (!(DHT_PIN & (1 << DHT_INPUTPIN)));
            _delay_us(30);
            if (DHT_PIN & (1 << DHT_INPUTPIN)) data[byte] |= (1 << (7 - bit));
            while (DHT_PIN & (1 << DHT_INPUTPIN));
        }
    }

    // Verify checksum
    if ((data[0] + data[1] + data[2] + data[3]) != data[4]) return -2;

    return 0;
}

int8_t dht_GetTempUtil(uint16_t *temperature, uint16_t *humidity) {
    uint8_t data[5] = {0};
    int8_t result = dht_read(data);

    if (result == 0) {
        *humidity = ((uint16_t)data[0] << 8) | data[1];
        *temperature = ((uint16_t)data[2] << 8) | data[3];
    }

    return result;
}
