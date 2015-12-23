import ddf.minim.analysis.*;
import cc.arduino.*;
import java.util.Arrays;
Minim minim;
AudioPlayer song;
BeatDetect beat;
BeatListener bl;
Arduino arduino;
int count;
FFT fft;

PImage img;

public double l2(int a){
  return Math.log(a) / Math.log(2);
}

void setup() {
  count = 8;
  minim = new Minim(this);
  arduino = new Arduino(this, Arduino.list()[4], 57600);
  song = minim.loadFile("test2.mp3", 512);
  
  song.play();
  
  beat = new BeatDetect();
  fft = new FFT(song.bufferSize(), song.sampleRate());
  bl = new BeatListener(beat, song);  
  for(int i = 0 ; i < count ; i++)
    arduino.pinMode(i+2, Arduino.OUTPUT); 
}

void draw() {
  fft.forward(song.mix);
  int[] obj_array = new int[fft.specSize()];
  for(int i = 0; i < fft.specSize(); i++){
    obj_array[i] = Math.round(fft.getBand(i));
  }
  int segmentSize = Math.round(fft.specSize() / count),
      total = 0, 
      average = 0;
  int[] values = new int[count];
  for(int i = 0 ; i < count ; i++){
    int[] segment = Arrays.copyOfRange(obj_array, i*segmentSize, (i+1)*segmentSize);
    for(int obj : segment)
      values[i] += obj;
    total += values[i];
  }
  average = Math.round(total / count);
  for(int i = 0 ; i < count ; i++)
    arduino.digitalWrite(i+2, l2(values[i]) > Math.log(average) ? Arduino.HIGH : Arduino.LOW);
}

void stop() {
  for(int i = 0 ; i < count ; i++)
    arduino.digitalWrite(i+2, Arduino.LOW);
  song.close();
  minim.stop();
  super.stop();
}
