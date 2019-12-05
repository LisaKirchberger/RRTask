#include <CapacitiveSensor.h>

CapacitiveSensor   cs_4_2 = CapacitiveSensor(4, 2);       // 10M resistor between pins 4 & 2, pin 2 is sensor pin, add a wire and or foil if desired

#define Reward 10 //output

int Rewardtime = 200;           // Time the Valve will be open for in ms when reward is given
float PassiveScale = 1.0;       // Fraction of reward given as a passive
int Enable = 0;                 // Enables the Valve to be opened

unsigned long Trialtime = 0;
unsigned long runtime = 0;

unsigned int Indx = 0;
int thres = 5000;

long Sensor;
int Sen = 0;
long SerOut;
boolean  bSucc = 1;  //sensor is succeptible if previously at baseline

float baseline = 200;
long buf[20];

void setup()
{
  Serial.begin(250000);
  pinMode(Reward, OUTPUT);  //fluid output
}

void checkSerial() {
  if (Serial.find("I")) {
    delay(1);
    char Ctrl = Serial.read();

    switch ( Ctrl ) {

      case 'R':
        //reward time for right valve
        Rewardtime = Serial.parseInt();
        Serial.println("D");
        break;

      case 'E':
        //set enable to 1 or 2, 1 for Go and 2 for NoGo
        Enable = Serial.parseInt();
        Serial.println("D");
        break;

      case 'D':
        //disable reward
        Enable = 0;
        Serial.println("D");
        break;

      case 'O':
        //Scale reward for passive reward
        PassiveScale = Serial.parseFloat();
        Serial.println("D");
        break;

      case 'S':
        Trialtime = millis();
        break;

      case 'P':
        //give passive reward
        digitalWrite(Reward, HIGH);
        delay(Rewardtime * PassiveScale);
        digitalWrite(Reward, LOW);
        Enable = 0;
        break;

      case 'F':
        //threshold value for sensors, above which lick is detected
        thres = Serial.parseInt();
        Serial.println("D");
        break;

      case 'B':
        //retrieve baseline
        Serial.print("D");
        Serial.print(baseline);
        break;

      default:
        ;
    }
  }
}

//reward valve one open and close
void openValve( ) {
  digitalWrite(Reward, HIGH);
  delay(Rewardtime);
  digitalWrite(Reward, LOW);
}


void printLick() {
  Serial.print("L");
}

void printReaction(char* m) {
  Serial.print("X");
  Serial.println(m);
  Serial.println(runtime - Trialtime);
  Serial.println(SerOut);
}


void checkSensors() {

  Sensor = 0;
  Sen = 0;
  buf[Indx] = cs_4_2.capacitiveSensorRaw(1);

  //sums over previous 20 samples + this one
  for (int i = 0; i < 20; i++) {
    Sensor += buf[i];
  }
  //if sensor goes over threshold set Sen to 1 then wait until sensors go below threshold to detect next lick
  if (Sensor - baseline > thres ) {
    if (bSucc) {
      Sen = 1;
      bSucc = false;
      printLick();
    }
  }
  else bSucc = true;

  runtime = millis();

  if (Sen == 1  && Enable == 1 ) {
    Enable = 0;
    SerOut =  Sensor - baseline;  //output: height of response
    openValve();
    printReaction("H");
  }
  else  if (Sen == 1  && Enable == 2 ) {
    Enable = 0;
    SerOut =  Sensor - baseline;  //output: height of response
    printReaction("F");
  }

  Indx += 1;
  if (Indx > 19) {
    Indx = 0;
  }

  //estimate average baseline noise level of the sensors
  //values should be within a reasonable range
  if (Sen == 0) //and not have crossed the threshold
  {
    if (Sensor < baseline * 10) baseline = (baseline * 39 + Sensor) / 40;
  }
}


void loop()
{
  if (Serial.available() > 1) {
    checkSerial();
  }

  checkSensors();

}



