import processing.serial.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import cc.arduino.*;
import java.util.Arrays;

Minim minim;
AudioPlayer song;
BeatDetect beat;
BeatListener bl;
Arduino arduino;
FFT fft;
PImage img;


int maxInUse = 4;
int count = 8;
int dataIn = 2;
int load = 3;
int clock = 4;

byte max7219_reg_noop        = 0x00;
byte max7219_reg_digit0      = 0x01;
byte max7219_reg_digit1      = 0x02;
byte max7219_reg_digit2      = 0x03;
byte max7219_reg_digit3      = 0x04;
byte max7219_reg_digit4      = 0x05;
byte max7219_reg_digit5      = 0x06;
byte max7219_reg_digit6      = 0x07;
byte max7219_reg_digit7      = 0x08;
byte max7219_reg_decodeMode  = 0x09;
byte max7219_reg_intensity   = 0x0a;
byte max7219_reg_scanLimit   = 0x0b;
byte max7219_reg_shutdown    = 0x0c;
byte max7219_reg_displayTest = 0x0f;

public int log(int x, int base){
  return (int) (Math.log(x) / Math.log(base));
}
public void putByte(byte data) {
  byte i = 8;
  byte mask;
  while(i > 0) {
    mask = (byte)(0x01 << (i - 1));      // get bitmask
    arduino.digitalWrite( clock, Arduino.LOW);   // tick
    if ( (data & mask) != 0){            // choose bit
      arduino.digitalWrite(dataIn, Arduino.HIGH);// send 1
    }else{
      arduino.digitalWrite(dataIn, Arduino.LOW); // send 0
    }
    arduino.digitalWrite(clock, Arduino.HIGH);   // tock
    --i;                         // move to lesser bit
  }
}
void maxSingle( byte reg, byte col) {    
//maxSingle is the "easy"  function to use for a single max7219

  arduino.digitalWrite(load, Arduino.LOW);       // begin     
  putByte(reg);                  // specify register
  putByte(col);//((data & 0x01) * 256) + data >> 1); // put data   
  arduino.digitalWrite(load, Arduino.LOW);       // and load da stuff
  arduino.digitalWrite(load, Arduino.HIGH); 
}

void maxAll (byte reg, byte col) {    // initialize  all  MAX7219's in the system
  int c = 0;
  arduino.digitalWrite(load, Arduino.LOW);  // begin     
  for ( c =1; c<= maxInUse; c++) {
  putByte(reg);  // specify register
  putByte(col);//((data & 0x01) * 256) + data >> 1); // put data
    }
  arduino.digitalWrite(load, Arduino.LOW);
  arduino.digitalWrite(load, Arduino.HIGH);
}
void maxAll (int reg, int col) {    // initialize  all  MAX7219's in the system
  int c = 0;
  arduino.digitalWrite(3, Arduino.LOW);  // begin    
  putByte((byte) reg);  // specify register
  putByte((byte) col);//((data & 0x01) * 256) + data >> 1); // put data
  arduino.digitalWrite(3, Arduino.LOW);
  arduino.digitalWrite(3,Arduino.HIGH);
}
void maxOne(byte maxNr, byte reg, byte col) {    
  int c = 0;
  arduino.digitalWrite(load, Arduino.LOW);     

  for ( c = maxInUse; c > maxNr; c--)
    putByte((byte) 0);

  putByte(reg);  // specify register
  putByte(col);//((data & 0x01) * 256) + data >> 1); // put data 

  for ( c =maxNr-1; c >= 1; c--) 
    putByte((byte) 0);

  arduino.digitalWrite(load, Arduino.LOW); // and load da stuff
  arduino.digitalWrite(load, Arduino.HIGH); 
}

void setup() {
  count = 8;
  minim = new Minim(this);
  arduino = new Arduino(this, Arduino.list()[4], 57600);
  arduino.pinMode(dataIn, Arduino.OUTPUT);
  arduino.pinMode(clock,  Arduino.OUTPUT);
  arduino.pinMode(load,   Arduino.OUTPUT);

  arduino.digitalWrite(13, Arduino.HIGH);  

//initiation of the max 7219
  maxAll(max7219_reg_scanLimit, 0x07);      
  maxAll(max7219_reg_decodeMode, 0x00);  // using an led matrix (not digits)
  maxAll(max7219_reg_shutdown, 0x01);    // not in shutdown mode
  maxAll(max7219_reg_displayTest, 0x00); // no display test
   for (int e=1; e<=8; e++) {    // empty registers, turn all LEDs off 
    maxAll(e,0);
  }
  maxAll(max7219_reg_intensity, 0x0f & 0x0f);
  song = minim.loadFile("Star Wars.mp3", 512);                                                                                                                                                                                                                                                                                                                                                                                        
 
  song.play();

  beat = new BeatDetect();
  fft = new FFT(song.bufferSize(), song.sampleRate());
  bl = new BeatListener(beat, song);
}

void draw() {
  fft.forward(song.mix);
  int size = fft.specSize();
  int segmentSize = Math.round(size / count);
  int total = 0;
  int average = 0;
  int[] obj_array = new int[size];
  int[] values = new int[count];
  arduino.digitalWrite( clock, Arduino.LOW);   // tick

  for(int i = 0; i < size; i++)
    obj_array[i] = Math.round(fft.getBand(i));

  for(int i = 0 ; i < count ; i++){
    int[] segment = Arrays.copyOfRange(obj_array, i*segmentSize, (i+1)*segmentSize);
    for(int obj : segment)
      values[i] += obj;
    total += values[i];
  }
  average = Math.round(total / count);
  
  for(int i = 0 ; i < count ; i++){
    long v = Math.round(Math.log(5 * values[i]));
    int n = 0;
    for(int j = 0 ; j < v ; j++)
     n +=  Math.pow(2, j);
    n = Math.min(n, 255);
    maxAll(count - i, n); 
  }
  arduino.digitalWrite( clock, Arduino.LOW);   // tick

}

void stop() {
  song.close();
  minim.stop();
  super.stop();
}
