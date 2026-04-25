#include <Wire.h>

#define MPU_ADDR 0x68

void writeReg(uint8_t reg, uint8_t data) {
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(reg);
  Wire.write(data);
  Wire.endTransmission();
}

void readRegs(uint8_t reg, uint8_t *buf, uint8_t len) {
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(reg);
  Wire.endTransmission(false);
  Wire.requestFrom(MPU_ADDR, (uint8_t)len);
  for (uint8_t i = 0; i < len; i++) {
    buf[i] = Wire.available() ? Wire.read() : 0;
  }
}

void mpuInit() {
  writeReg(0x6B, 0x00);  // Wake up
  delay(100);
  writeReg(0x1B, 0x00);  // Gyro ±250°/s
  writeReg(0x1C, 0x00);  // Accel ±2g
  delay(10);
}

void mpuRead(int16_t &ax, int16_t &ay, int16_t &az,
             int16_t &gx, int16_t &gy, int16_t &gz) {
  uint8_t buf[14];
  readRegs(0x3B, buf, 14);
  ax = (int16_t)(buf[0]  << 8 | buf[1]);
  ay = (int16_t)(buf[2]  << 8 | buf[3]);
  az = (int16_t)(buf[4]  << 8 | buf[5]);
  gx = (int16_t)(buf[8]  << 8 | buf[9]);
  gy = (int16_t)(buf[10] << 8 | buf[11]);
  gz = (int16_t)(buf[12] << 8 | buf[13]);
}

void setup() {
  Serial.begin(115200);
  delay(1000);
  Wire.begin(21, 22);
  Wire.setClock(400000);
  mpuInit();
  Serial.println("READY");
}

void loop() {
  int16_t ax, ay, az, gx, gy, gz;
  mpuRead(ax, ay, az, gx, gy, gz);

  Serial.print(ax); Serial.print(",");
  Serial.print(ay); Serial.print(",");
  Serial.print(az); Serial.print(",");
  Serial.print(gx); Serial.print(",");
  Serial.print(gy); Serial.print(",");
  Serial.println(gz);

  delay(10);
}
