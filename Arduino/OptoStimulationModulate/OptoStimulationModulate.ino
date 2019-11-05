  /* OptoStimulation
   * Reads a digital input on pin 8; this is a TTL input high or low. 
   * Output pin A0 is analog and goes to laser  
  / Opto Setup usually COM14
  / WF Setup usually COM12
  */
  
  
  int OptoPortIn =  8; // input pin
  int OptoPortOut = A0; // output pin or 4
  int OptoValue = 255; //output value of analogwrite, can be between 0 and 255
  int StimFreq = 15; // Lisa 15, Enny 5; rate of stimulation in Hz
  int DurationPerPulse =10;// 10; // Lisa 10, Enny 100; duration of light on per pulse in ms. Be careful that this matches with the frequency
  boolean Optostatus= false; // as long as this variable is true, it's playing the program
  int TriggerVal = 0; // read from input pin
  int timetodelay = 1000/StimFreq - DurationPerPulse;
  
  void setup()   { 
    Serial.begin(250000);
    pinMode(OptoPortOut, OUTPUT); //Laser 
    analogWrite(OptoPortOut, 0);
    pinMode(OptoPortIn, INPUT); // TTL pulse, either LOW or HIGH
  }
  
  void loop() 
    {
      // Read input pin and determine whether program should play
      TriggerVal = digitalRead(OptoPortIn); 
  
       // Check whether TriggerVal is high when stimulation is not yet running; it should start
       if (Optostatus == false && TriggerVal == HIGH){
          Optostatus = true;     
          }


       // check whether TriggerVal is low; it should stop
       if (Optostatus == true && TriggerVal == LOW){
          analogWrite(OptoPortOut,0); // turn off light
          Optostatus = false;
          }  
  
        // check for communication from serial port if the Optovalue should be set to a different value
        if (Optostatus == false && TriggerVal == LOW && Serial.available() > 1){
                char Message = Serial.read();
                 switch ( Message ) {
                     case 'C':            // change the OptoValue
                          OptoValue = Serial.parseInt();
                          break;
                      case 'P':          // print which OptoValue was used
                          Serial.println(OptoValue);
                          break;
                     }
               }

       // As long as Optostatus == true, the program should play
       if (Optostatus == true){
          analogWrite(OptoPortOut,OptoValue); // turn on Laser
          delay(DurationPerPulse);//just wait DurationPerPulse ms
          analogWrite(OptoPortOut,0); // turn off Laser
          delay(timetodelay); // wait until next trial
           }  
                
    }
  
