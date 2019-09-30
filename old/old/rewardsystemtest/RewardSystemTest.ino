
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
   delay(3000);
   digitalWrite(Reward1, HIGH); //right
   delay(150);
   digitalWrite(Reward1, LOW);
   delay(500);
   digitalWrite(Reward2, HIGH); //left
   delay(176);
   digitalWrite(Reward2, LOW);
   rewards = rewards + 1;
 }
}
