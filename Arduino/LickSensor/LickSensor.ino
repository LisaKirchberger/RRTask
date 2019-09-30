/* Original DualLick15_WM + integrated Servo communication
/ Opto Setup usually COM3
/ WF Setup usually COM9
*
 *  Servo
Control a servo by serial commands:
position (degrees) is given by an ascii string, ending with a newline.
Joris Coppens 20160202
*/
#include <Servo.h>

Servo myservo;  // create servo object to control a servo
// twelve servo objects can be created on most boards
#include <CapacitiveSensor.h>

CapacitiveSensor   cs_4_2 = CapacitiveSensor(4, 2);       // 10M resistor between pins 4 & 2, pin 2 is sensor pin, add a wire and or foil if desired
CapacitiveSensor   cs_4_6 = CapacitiveSensor(4, 6);       // 10M resistor between pins 4 & 6, pin 6 is sensor pin, add a wire and or foil

int pos = 70;    // variable to store the servo position
int newpos = 70;
int stepsz = 2;
int nrstep = 6; // Variable to store the nr of steps in which servo position is reached
int command;
int RewardtimeOne = 200; //was 200
int RewardtimeTwo = 200; //was 200
unsigned long trialonset = 0;
unsigned long Timeout = 6000; //6000
int Enable = 0;
unsigned long Trialtime = 0;
unsigned int Indx = 0;
int thres = 10000;
int Reward1 = 10; //output
int Reward2 = 11;
long Sensor1;
long Sensor2;
int Sen = 0;
float threshold1 = 200; //was200
float threshold2 = 200;//was200
long buf1[20];
long buf2[20];
int gavepassive = 0;
int easymode;
long wentthrough = 0;
int passide = 0;
long Onsettm=0;
unsigned long rewardtime = 0;
int rewardduration = 0;
unsigned long lastlick = 0;
// Tobias
boolean bSucc = 1;
unsigned long trialonset2 = 0;
boolean bOpened = false;
boolean bOpenedPas = false;
int side = 0;
int delaytime = 0;
int OpenLaterWhenClosed = 0;


void setup()
{
  Serial.begin(250000);
  pinMode(Reward1, OUTPUT);  //fluid output (tobias thinks right side)
  pinMode(Reward2, OUTPUT);  //fluid output (tobias thinks left side)
  pinMode(12, OUTPUT); //ttl pulse for lick
  digitalWrite(Reward1, LOW);
  digitalWrite(Reward2, LOW);
  //digitalWrite(12, LOW);

  myservo.attach(9);  // attaches the servo on pin 9 to the servo object
  myservo.write(pos);
}


void checkSerial() 
{
  if (Serial.find("I")) {
    delay(1);
    char Ctrl = Serial.read();
    switch ( Ctrl ) {
      case 'C':
         Serial.println('D');
         Serial.println(threshold1);
         Serial.println(threshold2);
         break;
      case 'O':
        newpos = Serial.parseInt();
        stepsz = (pos - newpos)/nrstep;
        for(int x = 1; x < nrstep+1; x++){
          pos = pos - stepsz;       
          myservo.write(pos);  // tell servo to go to position in variable 'pos'
          Serial.println('W'); 
          delay(15);
           }        
        Serial.println('D');
       
        break;
      case 'L':
        RewardtimeOne = Serial.parseInt();
        Serial.println('D');
        break;
      case 'R':
        RewardtimeTwo = Serial.parseInt();
        Serial.println('D');
        break;
      case 'E':
        Enable = Serial.parseInt(); // '1' is right '2' is left
        Serial.println('D');
        break;
      case 'D':
        Enable = 0;
        Serial.println('D');
        digitalWrite(Reward1, LOW);
        digitalWrite(Reward2, LOW);        
        break;
      case 'T':
        Timeout = Serial.parseInt();
        Serial.println('D');
        break;
      case 'S':
        Trialtime = millis() - 1;
        gavepassive = 0;
        wentthrough = 0;
        break;
        // change Lisa: not sending back anything when S, was sent, have to ask for the time later by sending: A
      case 'A':
        Serial.println('R');
        Serial.println(Trialtime);
        break;
      case 'M':
        easymode = Serial.parseInt();
        Serial.println('D');
        break;
      case 'P':
        if (Enable == 1 && millis() - trialonset > Timeout) {
           if (bOpenedPas == false) {
                  digitalWrite(Reward1, HIGH);
                  Onsettm = millis();
                  bOpenedPas = true;
                  passide = 1;
                  gavepassive = 1;

                }
        }
        else if (Enable == 2 && millis() - trialonset > Timeout) {
           if (bOpenedPas == false) {
                  digitalWrite(Reward2, HIGH);
                  Onsettm = millis();
                  bOpenedPas = true;
                  passide = 2;
                  gavepassive = 1;
                }          
        }
       Serial.println('D');
        break;
      case 'F':
        thres = Serial.parseInt();
        Serial.println('D');
        break;
      default:
      ;
    }
  }
}


void printFeedback(char m) {
  Serial.println('O');

  // Tobias
  Serial.println('X');
  Serial.println(m);
  Serial.println(millis() - Trialtime);
  Serial.println(gavepassive);
  Serial.println(wentthrough);
  Serial.println(threshold1);
  Serial.println(threshold2);
}

void checkSensors() 
{
  buf1[Indx] = cs_4_2.capacitiveSensorRaw(1);
  buf2[Indx] = cs_4_6.capacitiveSensorRaw(1);

  Sensor1 = 0;
  Sensor2 = 0;

  for (int i = 0; i < 20; i++) {
    Sensor1 += buf1[i];
    Sensor2 += buf2[i];
  }

  if (Sensor1 - threshold1 > thres) {
    Sen = 1;
    if (bSucc) {
      //digitalWrite(12, HIGH);
      bSucc = false;
      lastlick = millis();
      printRight();
    }
  }
  else if (Sensor2 - threshold2 > thres) {
    Sen = 2;
    if (bSucc) {
      //digitalWrite(12, HIGH);
      bSucc = false;
      lastlick = millis();
      printLeft();
    }
  }
  else if (Sensor2 - threshold2 < thres * 0.5 &&  Sensor1 - threshold1 < thres * 0.5)
  {
    bSucc = true;
    //digitalWrite(12, LOW);
  }

   

  if ((millis() - Trialtime < 3000 && millis() - Trialtime > 0 && Enable > 0 && Sen > 0) | OpenLaterWhenClosed > 0) 
  {
    if ((Enable == 1 && Sen == 1) | OpenLaterWhenClosed == 1) {
      
      if (bOpened == false) {
        
        if (bOpenedPas == false) { 
               
          digitalWrite(Reward1, HIGH);
          Onsettm = millis();
          
          if (OpenLaterWhenClosed == 1 | gavepassive == 1) {
            bOpenedPas = true;
            OpenLaterWhenClosed = 0;
            passide = 1;
            wentthrough = Sensor1 - threshold1;
            printFeedback('1');
            Enable = 0;
            Sen = 0;
          }
          else if (OpenLaterWhenClosed == 0) {
            bOpened = true;
            OpenLaterWhenClosed = 0;
            side = 1;               
            wentthrough = Sensor1 - threshold1;
            printFeedback('1');
            Enable = 0;
            Sen = 0;
          }
            
        }
        else if (bOpenedPas == true) {
           OpenLaterWhenClosed = 1;
        }
      }
    }
    else if ((Enable == 2 && Sen == 2 )| OpenLaterWhenClosed == 2) {
      
      if (bOpened == false) {
        
        if (bOpenedPas == false) { 
               
          digitalWrite(Reward2, HIGH);
          Onsettm = millis();
          
          if (OpenLaterWhenClosed == 2 | gavepassive == 1) {
            bOpenedPas = true;
            OpenLaterWhenClosed = 0;
            passide = 2;
            wentthrough = Sensor2 - threshold2;
            printFeedback('2');
            Enable = 0;
            Sen = 0;
          }
          else if (OpenLaterWhenClosed == 0) {
            bOpened = true;
            OpenLaterWhenClosed = 0;
            side = 2;               
            wentthrough = Sensor2 - threshold2;
            printFeedback('2');
            Enable = 0;
            Sen = 0;
          }
            
        }
        else if (bOpenedPas == true) {
          OpenLaterWhenClosed = 2;
        }
      }
    }
    else if (Enable > 0) {
      if (easymode) {
        switch (Enable) {
          case 1:
            if (bOpenedPas == false) {
                    digitalWrite(Reward1, HIGH);
                    Onsettm = millis();
                    bOpenedPas = true;
                    passide = 1;
                  }
          break;
          case 2:
            if (bOpenedPas == false) {
                    digitalWrite(Reward2, HIGH);
                    Onsettm = millis();
                    bOpenedPas = true;
                    passide = 2;
                  }           
          break;
        }
      }
      wentthrough = max(Sensor1 - threshold1, Sensor2 - threshold2);
      printFeedback('0');
      Enable = 0;
      Sen = 0;

      
    }
  }
  
if (bOpened == true){
   if(side == 1 && millis() - Onsettm >= RewardtimeOne - 90) {
      delaytime = (RewardtimeOne-(millis()-Onsettm));
      if (delaytime>1) {
        delay(delaytime);
      }
     side = 0;
     digitalWrite(Reward1, LOW);
     Serial.println('O');
     Serial.println('Q');
     Serial.println(millis()-Onsettm);
     bOpened = false;
     bOpenedPas = false;
   }
   else if(side == 2 && millis() - Onsettm >= RewardtimeTwo - 90) {
     delaytime = (RewardtimeTwo-(millis()-Onsettm));
     if (delaytime>1){
        delay(delaytime);
      }
     side = 0;
     digitalWrite(Reward2, LOW);
     Serial.println('O');
     Serial.println('Q');
     Serial.println(millis()-Onsettm);
     bOpened = false;
     bOpenedPas = false;
   }
}
else if (bOpenedPas == true){
   if (passide == 1 && millis() - Onsettm >= RewardtimeOne/2 - 90){
     delaytime = ((RewardtimeOne/2)-(millis()-Onsettm));
     if (delaytime>1){
        delay(delaytime);
      }
     digitalWrite(Reward1, LOW);
     Serial.println('O');
     Serial.println('Q');
     Serial.println(millis()-Onsettm);
     bOpened = false;
     bOpenedPas = false;
     passide = 0;
     
   }
    else if (passide == 2 && millis() - Onsettm >= RewardtimeTwo/2 - 90){
        delaytime = ((RewardtimeTwo/2)-(millis()-Onsettm));
        if (delaytime>1){
            delay(delaytime);
        }
      digitalWrite(Reward2, LOW);
       Serial.println('O');
       Serial.println('Q');
       Serial.println(millis()-Onsettm);
       bOpened = false;
      bOpenedPas = false;
      passide = 0;
     

   }
  }
}

// Tobias
void printRight() {
  Serial.println('O');
  Serial.println("Y");
  Serial.println(millis());
}

// Tobias
void printLeft() {
  Serial.println('O');
  Serial.println("Z");
  Serial.println(millis());
}

void loop() {
  if (Serial.available() > 1) {
    checkSerial();
  }

  // Tobias
  if (millis() - lastlick > 10) {
    checkSensors();
    if (Sen == 0) {
      if (Sensor1 < threshold1 * 10) threshold1 = (threshold1 * 9 + Sensor1) / 10;
      if (Sensor2 < threshold2 * 10) threshold2 = (threshold2 * 9 + Sensor2) / 10;
    }
  }

  Sen = 0;
  Indx += 1;
  if (Indx > 19) {
    Indx = 0;
  }
}

