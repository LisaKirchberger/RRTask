
int Reward1 = 10; //output
int Reward2 = 11;

int rewards = 0;

void setup()                    
{
   pinMode(Reward1, OUTPUT);  //fluid output
   pinMode(Reward2, OUTPUT);  //fluid output
}

void loop()
{
 if(rewards < 101){
   delay(1000);
   digitalWrite(Reward2, HIGH); //left
   delay(250); // valve delay
   digitalWrite(Reward2, LOW);
   rewards = rewards + 1;
 }
}
