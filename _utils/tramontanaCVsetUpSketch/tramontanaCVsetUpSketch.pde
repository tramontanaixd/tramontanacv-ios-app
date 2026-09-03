import websockets.*;

WebsocketClient wsc;
int now;
boolean newEllipse;

void setup(){
  size(200,200);
  
  newEllipse=true;
  
  wsc= new WebsocketClient(this, "ws://10.0.1.3:9088");
  now=millis();
}

void draw(){
  if(newEllipse){
    ellipse(random(width),random(height),10,10);
    newEllipse=false;
  }
    
    
  //if(millis()>now+5000){
    
  //  now=millis();
  //}
}

void webSocketEvent(String msg){
 println(msg);
 newEllipse=true;
}
void keyPressed()
{
  //VALID MESSAGES
    //lockAE
    //unlockAE
    //captureBg
    //blur --> value:(float)0.5
    //threshold --> value:(int)128
    //blobs --> min:(int)[1 .. 9999], max:(int)[1 .. 9999], num:(int)[1 .. 50]
    
  if(key == 'a')
  {
   wsc.sendMessage("{\"m\":\"lockAE\"}");
  }
  else if(key == 'q')
  {
   wsc.sendMessage("{\"m\":\"unlockAE\"}");
  }
  
  else if(key == 'w')
  {
    wsc.sendMessage("{\"m\":\"captureBg\"}");
  }
  
  else if(key == 'e')
  {
   wsc.sendMessage("{\"m\":\"blur\",\"val\":0.5}");
  }
   else if(key == 'd')
  {
    wsc.sendMessage("{\"m\":\"blur\",\"val\":15}");
   
  }
   else if(key == 'r')
  {
    wsc.sendMessage("{\"m\":\"threshold\",\"val\":200}");
  }
  else if(key == 'f')
  {
    wsc.sendMessage("{\"m\":\"threshold\",\"val\":1}");
    
  }
  else if(key == 't')
  {
    wsc.sendMessage("{\"m\":\"blobs\",\"max\":200,\"min\":5,\"num\":3}");
  }
  else if (key == 'g')
  {
    wsc.sendMessage("{\"m\":\"blobs\",\"max\":5000,\"min\":40,\"num\":2}");
  }
  else if (key == 'z')
  {
    wsc.sendMessage("{\"m\":\"save\"}");
  }
  else if (key == 'p')
  {
    wsc.sendMessage("{\"m\":\"mFac\"}");
  }
  else if (key == 'l')
  {
    wsc.sendMessage("{\"m\":\"mCV\"}");
  }
   else if (key == 'o')
  {
    wsc.sendMessage("{\"m\":\"cam\",\"id\":1}");
  }
   else if (key == 'k')
  {
    wsc.sendMessage("{\"m\":\"cam\",\"id\":0}");
  }
  
}
