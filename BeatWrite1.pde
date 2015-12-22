

/**
  * This sketch demonstrates how to use the BeatDetect object in FREQ_ENERGY mode.<br />
  * You can use <code>isKick</code>, <code>isSnare</code>, </code>isHat</code>, <code>isRange</code>, 
  * and <code>isOnset(int)</code> to track whatever kind of beats you are looking to track, they will report 
  * true or false based on the state of the analysis. To "tick" the analysis you must call <code>detect</code> 
  * with successive buffers of audio. You can do this inside of <code>draw</code>, but you are likely to miss some 
  * audio buffers if you do this. The sketch implements an <code>AudioListener</code> called <code>BeatListener</code> 
  * so that it can call <code>detect</code> on every buffer of audio processed by the system without repeating a buffer 
  * or missing one.
  * <p>
  * This sketch plays an entire song so it may be a little slow to load.
  */

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
int count;
FFT fft;

PImage img;

class Obj implements Comparable<Obj>{
 private int index;
 private float value;
 private boolean sortByIndex;
 Obj(int i, float j, boolean k){
   index = i;
   value = j; 
   sortByIndex = k;
 }
 public int getIndex(){return this.index;}
 public int getValue(){return Math.round(this.value);}
 @Override
 public int compareTo(Obj that){
   return !this.sortByIndex ? this.getValue() - that.getValue()
                            : this.getIndex() - that.getIndex();
 }
 
}
void setup() {
  size(1675, 350, P3D);
  count = 8;
  minim = new Minim(this);
  arduino = new Arduino(this, Arduino.list()[4], 57600);
  println(Arduino.list());
  song = minim.loadFile("test.mp3", 2048); // original 4096
  img = loadImage("laDefense.jpg");
  
  song.play();

  beat = new BeatDetect(song.bufferSize(), song.sampleRate());
  
  beat.setSensitivity(100); //original 1000
  
  // Fast Fourier Transform for Freq. Spectrum 
  fft = new FFT(song.bufferSize(), song.sampleRate());
  
  // make a new beat listener, so that we won't miss any buffers for the analysis
  bl = new BeatListener(beat, song);  
  for(int i = 2 ; i < 2 + count ; i++)
    arduino.pinMode(i, Arduino.OUTPUT); 
}

void draw() {
  background(img);
  // Retrun to all black background using background(0);
  fill(255);
  smooth();
  stroke(255);
  fft.forward(song.mix);
  Obj[] obj_array = new Obj[fft.specSize()];
  for(int i = 0; i < fft.specSize(); i++){
    obj_array[i] = new Obj(i, fft.getBand(i), false);
    line(i, height, i, height - fft.getBand(i)*4);
  }
  Arrays.sort(obj_array);
  int l = obj_array.length;
  int avg = 0;
  Obj[] tmp = Arrays.copyOfRange(obj_array, l - count, l);

  for(int i = 0 ; i < count ; i++){
     avg += tmp[i].value;
     tmp[i].sortByIndex = true;
  }
  avg = avg / count;
  Arrays.sort(tmp);
  
  for(int i = 0 ; i < count ; i++)
    arduino.digitalWrite(i+2, tmp[i].value > avg * 1.2 ? Arduino.HIGH : Arduino.LOW);
}

void stop() {
  for(int i = 2 ; i < 2 + count ; i++)
    arduino.digitalWrite(i, Arduino.LOW);
  // always close Minim audio classes when you are finished with them
  song.close();
  // always stop Minim before exiting
  minim.stop();
  // this closes the sketch
  super.stop();
  
}
