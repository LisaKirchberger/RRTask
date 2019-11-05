/* Mask Blinking at a certain frequency usually 
/ Opto Setup usually COM7
/ WF Setup usually COM11
*/


long randNumber;
int pin = 12;
int Freq = 15;              // in Hz, Lisa 15, Enny 5
int DurationPerPulse = 10;  // in ms, Lisa 10, Enny 100
int StimDur = 1000;         // in ms
int MinPauseDur = 500;        // in ms, Lisa 500
int MaxPauseDur = 2000;        // in ms, Lisa 2000
int cycle = 1;
int cyclenum = Freq * StimDur/1000;
int timetodelay = 1000/Freq - DurationPerPulse;

void setup() {
  // setup code, to run once:
  pinMode(pin, OUTPUT);

}


void loop() {
  // main code here, to run repeatedly:
  
  while (cycle < cyclenum+1){
    // Flash LED at certain frequency
    digitalWrite(pin, HIGH);   // turn the LED on
    delay(DurationPerPulse);
    digitalWrite(pin,LOW); // turn off LED
    delay(timetodelay);
    cycle++;
  }
  cycle = 1;


  // wait between stimulations
  randNumber = random(MinPauseDur, MaxPauseDur);
  delay(randNumber);              // wait 
  
}
