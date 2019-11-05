/* Mask Blinking at a certain frequency usually 
/ Opto Setup usually COM15
/ WF Setup usually COM11
*/

// change these variables according to preference
const int Freq = 15;                          // in Hz, Lisa 15, Enny 5
const int DurationPerPulse = 10;              // in ms, Lisa 10, Enny 100
const int StimDur = 1000;                     // in ms, Lisa 1000
const int MinPauseDur = 500;                  // in ms, Lisa 500
const int MaxPauseDur = 2000;                 // in ms, Lisa 2000

// do not touch these variables
const int pin = 12;
const int cyclenum = Freq * StimDur/1000;     // number of cycles fitting in StimDur
const int timetodelay = 1000/Freq - DurationPerPulse;   //time between 2 pulses
unsigned long randNumber;                     // random ITI
long startTiming;                    // here we store all onset times relative to trial start
int cycle = 1;                                // functions as a counter

// for timekeeping
unsigned long trialstartTime = millis();
unsigned long startTime = millis(); 
unsigned long currTime = millis();

void setup() {
  // setup code, to run once:
  pinMode(pin, OUTPUT);
  Serial.begin(57600);
}

void checkSerial() 
{
  char Message = Serial.read();
  switch (Message) { 
    case 'T':            //marks the beginning of a trial
      //reset the Trialtimer
      trialstartTime = millis();
      break;    
  }
}

void loop() {
  // main code here, to run repeatedly:
  
  // send relative start time through the serial port:
  startTiming = millis() - trialstartTime;
  Serial.write((byte*)&startTiming,4);
  

  // Flash LED at certain frequency
  while (cycle < cyclenum+1){
    
    //      turn the LED on
    digitalWrite(pin, HIGH);   
    // wait for time LED is supposed to be on and check Serial port if a new Trial is starting 
    startTime = millis(); 
    currTime = millis();
    while (currTime - startTime <= DurationPerPulse){
          currTime = millis();
          if (Serial.available() > 1) {
              checkSerial();
          }
     } 

    //      turn the LED off
    digitalWrite(pin,LOW);
    // wait for time LED is supposed to be off and check Serial port if a new Trial is starting 
    startTime = millis(); 
    currTime = millis();
    while (currTime - startTime <= timetodelay){
          currTime = millis();
          if (Serial.available() > 1) {
                checkSerial();
          }
     } 

     //     move on to next cycle
    cycle++;
  }
  cycle = 1;


  // Pause between Flashes for a random ITI
  randNumber = random(MinPauseDur, MaxPauseDur);
  startTime = millis(); 
  currTime = millis();
  while (currTime - startTime <= randNumber){
    currTime = millis();
    if (Serial.available() > 1) {
          checkSerial();
     }
  } 
  
}
