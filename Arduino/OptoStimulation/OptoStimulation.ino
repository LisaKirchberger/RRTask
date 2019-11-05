/* OptoStimulation
 * Reads a digintal input on pin 8; this is a TTL input high or low. Output pin - 7, goes to laser on/off. 
/ Opto Setup usually COM8
/ WF Setup usually COM8
*/


int OptoPortIn =  8; // input pin or 8
int OptoPortOut = 9; // output pin or 4
int ShamLight = 11; // SHAM LED LIGHT
int StimFreq = 15; // Enny 5, Lisa 15; rate of stimulation in Hz
int DurationPerPulse = 10; // Enny 100, Lisa 10, duration of light on per pulse in ms. Be careful that this matches with the frequency
long ranNum =  1;

long Onsettm=millis(); // times per pulse and keeps track that Frequency of turning on is not higher than StimFreq Hz
boolean Optostatus= false; // as long as this variable is true, it's playing the program
int OptoVal = 0; // Value for Opto, read from input pin

int timetodelay = 1000/StimFreq - DurationPerPulse;

void setup()
 { Serial.begin(250000);
  pinMode(OptoPortOut, OUTPUT); //Laser/LED
  digitalWrite(OptoPortOut, LOW);
  pinMode(OptoPortIn, INPUT); // TTL pulse, either low or high
  digitalWrite(ShamLight,LOW);
}

void loop() 
  {
     ranNum=random(10000); // 1 in 10 chance that the LED will turn on
       if (ranNum == 1){
         digitalWrite(ShamLight,HIGH); // turn on LED
         delay(DurationPerPulse);
         digitalWrite(ShamLight,LOW);      
   }
    
    OptoVal = digitalRead(OptoPortIn); // Read input pin and determine whether program should play

   // Play program
   // Check whether optoval is high when stimulation is not yet running; it should start
   if (Optostatus == false && OptoVal == HIGH){
      Optostatus = true;     
      }
      // check whether optoval is low; it should stop
   if (OptoVal == LOW){
      digitalWrite(OptoPortOut, LOW);
      Optostatus = false;
      }
   // As long as Optostatus == true, the program should play
   if (Optostatus == true){
        digitalWrite(OptoPortOut,HIGH); // turn on light
        delay(DurationPerPulse);//just wait DurationPerPulse ms
        digitalWrite(OptoPortOut,LOW); // turn off light
        delay(timetodelay);
       }  
              
  }


