import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;

Table table;
TableRow row;

float time = 0.0;

String[] dates;
float[] latitudes;
float[] longitudes;
float[] temperatures;
int rowCount;

/* for temperature color mapping */
float minTemp;
float maxTemp;
int colMax = 0xffff0000;
int colMed = 0xff00ff00;
int colMin = 0xff0000ff;
int curCol;

PFont f;

// Sonification
Minim minim;
AudioOutput out;
Oscil wave;

// Visualization
PImage bg;
int dayIterator;
int traceLength;
float[] prevLatitudes;
float[] prevLongitudes;
color[] prevTemperatures;
String[] polygons; 

void setup() {
  size(1536, 768, P3D);
  background(255);
  table = loadTable("white_rumped_sandpiper_pr_temps_nodup_polygon.csv", "header, csv");
  rowCount = table.getRowCount();
  dates = new String[rowCount];
  latitudes = new float[rowCount];
  longitudes = new float[rowCount];
  temperatures = new float[rowCount];
  traceLength = 10;
  prevLatitudes = new float[traceLength];
  prevLongitudes = new float[traceLength];
  prevTemperatures = new color[traceLength];
  polygons = new String[rowCount];

  for (int i=0; i < table.getRowCount(); i++) {
    row = table.getRow(i);
    //dates[i] = row.getString("DATETIME");
    latitudes[i] = row.getFloat("AVG LAT");
    longitudes[i] = row.getFloat("AVG LON");
    temperatures[i] = row.getFloat("TEMPERATURE");
    polygons[i] = row.getString("VERTICES");
  } 

  minim = new Minim(this);
  // use the getLineOut method of the Minim object to get an AudioOutput object
  out = minim.getLineOut();
  // create a sine wave Oscil, set to 440 Hz, at 0.5 amplitude
  wave = new Oscil( 440, 0.5f, Waves.SINE );
  // patch the Oscil to the output
  //wave.patch( out );

  bg = loadImage("world-map.jpg");
  dayIterator = 0;
  frameRate(8);
}

void draw() {
 // background(bg);
  background(0);
  stroke(255);
  strokeWeight(2);
  line(0,height/2,width,height/2);
  float amt = (temperatures[dayIterator]-266.09) / (306.85-266.09); // (current_temp - min_temp) / (max_temp - min_temp) 
  color tempColor = lerpColor( color(155, 222, 232), color(255, 102, 26), amt);

  if ( dayIterator == rowCount-1 ) {
    exit();
  }

  float x = ((float(width)/360.0) * (180 + longitudes[dayIterator]));
  float y = ((float(height)/180.0) * (90 - latitudes[dayIterator]));

  // centroid
  stroke(0);
  fill(255, 0, 0);
  ellipse( x, y, 15, 15);
  
  // polygon
  fill(tempColor);
  String verticesString = polygons[dayIterator];
  float[] vertices = parseVerticesString(verticesString);
  
  fill(255,0,0);
  beginShape();
  for(int i=0;i<vertices.length;i+=2){
    vertex(((float(width)/360.0) * (180 + vertices[i+1])), ((float(height)/180.0) * (90 - vertices[i])));
  }
  endShape(CLOSE);

  //temperature
  noStroke();
  fill(tempColor);
  ellipse(x, y, 50, 50);

  // sonification
  wave.setAmplitude(map(x,0, width,1,0));
  wave.setFrequency(map(y,0, height,110,880));

  // textual information
  fill(255);
  textSize(20);
  //text(dates[dayIterator], 40, height-70);

  // past traces
  if ( dayIterator > traceLength ) {
    for (int i=0;i<traceLength;i++) {
      prevLatitudes[i] = ((float(width)/360.0) * (180 + longitudes[dayIterator - i-1]));
      prevLongitudes[i] = ((float(height)/180.0) * (90 - latitudes[dayIterator - i-1]));
      amt = (temperatures[dayIterator-i-1]-266.09) / (306.85-266.09);
      prevTemperatures[i] = lerpColor(color(155, 222, 232), color(255, 102, 26), amt);
    }
    for (int i=0; i<traceLength; i++) {
      
      //trace
      fill( 255, 255 -(i*20));
      stroke( 255, 255 -(i*20));
      ellipse(prevLatitudes[i], prevLongitudes[i], 12-i*2, 12-i*2);
      
      //temperature
      fill(prevTemperatures[i]);
      noStroke();
      ellipse(prevLatitudes[i], prevLongitudes[i], 30-i*2, 30-i*2);
      
      if ( i < traceLength - 1 ) {
        stroke(255);
        strokeWeight(2);
        line(prevLatitudes[i], prevLongitudes[i], prevLatitudes[i+1], prevLongitudes[i+1]);
      }
      
    }
  }
  dayIterator +=1;
}

float[] parseVerticesString(String vertexString){
  /* returns an array of consecutive latitude and longtidue values */
  String[] vertices = split(vertexString,"&");
  float[] result = new float[vertices.length * 2];
  for(int i=0;i<vertices.length;i++){
    String[] values = split(vertices[i],"*");
    result[i*2] = float(values[0]);
    result[(i*2)+1] = float(values[1]);
  }
  return result;
}

// max & min temps
// white_rumped_sandpiper_pr_temps_nodup_clusteredfinal     ( 266.09, 306.85 )