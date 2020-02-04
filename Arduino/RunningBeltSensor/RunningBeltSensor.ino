/* motion encoder for mouse Treadmill
/ Opto Setup      COM12
/ WF Setup        COM10  
/ Boxes           COM5                  */

#define encPinA 2 
#define encPinB 3 
#define outPin 5

volatile long encPos = 0; 
unsigned long lasttime = 0;
unsigned long lastpos = 0;
short mySpeed = 0;
short testvalue = 45;


void setup() 
{ 
  pinMode(encPinA, INPUT); 
  pinMode(encPinB, INPUT); 
// encoder pin on interrupt 0 (pin 2) 
  attachInterrupt(0, doEncoderA, CHANGE);
// encoder pin on interrupt 1 (pin 3) 
  attachInterrupt(1, doEncoderB, CHANGE);  
  Serial.begin(57600);
} 


void loop()
{
  //Do stuff here 
  if ((millis() - lasttime) > 10)
  {
   lasttime = millis(); 
   mySpeed = (encPos-lastpos);
   lastpos = encPos;
  }
  
  if (Serial.available()) {
     int m = Serial.read();
     if(m == 1) {
       encPos = 0;    // zero the position
       lastpos = 0;
      } 
      else if (m==2) {
        Serial.write((byte*)&mySpeed,2);
        //Serial.write((byte*)&testvalue,2);
      }
    }
} 


void doEncoderA(){ 
  // look for a low-to-high on channel A
  if (digitalRead(encPinA) == HIGH) { 
    // check channel B to see which way encoder is turning
    if (digitalRead(encPinB) == LOW) {  
      encPos += 1;         // CW
    } 
    else {
      encPos -= 1;         // CCW
    }
  }
  else   // must be a high-to-low edge on channel A                                       
  { 
    // check channel B to see which way encoder is turning  
    if (digitalRead(encPinB) == HIGH) {   
      encPos += 1;          // CW
    } 
    else {
      encPos -= 1;          // CCW
    }
  }
} 


void doEncoderB(){ 
  // look for a low-to-high on channel B
  if (digitalRead(encPinB) == HIGH) {   
   // check channel A to see which way encoder is turning
    if (digitalRead(encPinA) == HIGH) {  
      encPos += 1;         // CW
    } 
    else {
      encPos -= 1;         // CCW
    }
  }
  // Look for a high-to-low on channel B
  else { 
    // check channel B to see which way encoder is turning  
    if (digitalRead(encPinA) == LOW) {   
      encPos += 1;          // CW
    } 
    else {
      encPos -= 1;          // CCW
    }
  }
} 
