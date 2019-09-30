
/* Blinking Mask
*/


long randNumber;
int pin = 12;

void setup() {
  // put your setup code here, to run once:
  pinMode(pin, OUTPUT);

}

void loop() {
  // put your main code here, to run repeatedly:
  digitalWrite(pin, HIGH);   // turn the LED on (HIGH is the voltage level)
  randNumber = random(0, 1000);
  delay(randNumber);              // wait 
  digitalWrite(pin, LOW);    // turn the LED off by making the voltage LOW
  randNumber = random(0, 1000);
  delay(randNumber);              // wait 
}
