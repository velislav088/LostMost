void setup() {
  // Setup LED pin 
  pinMode(13, OUTPUT);

  // Rapid flash 10 times on startup - check
  for (int i = 0; i < 10; i++) {
    digitalWrite(13, HIGH);
    delay(100);
    digitalWrite(13, LOW);
    delay(100);
  }
  delay(1000);
}

void loop() {
  // Slow blink
  digitalWrite(13, HIGH);
  delay(1000);
  digitalWrite(13, LOW);
  delay(1000);
}