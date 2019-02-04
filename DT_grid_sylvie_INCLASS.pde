// processing library triangulate by 
// Paul Bourke, Florian Jenett, Tom Carden, Nicolas Clavaud. 
// (c) 2010
//color averaging from Benjamin Leonard at https://www.openprocessing.org/sketch/136203/
import org.processing.wiki.triangulate.*;
import gab.opencv.*;
import processing.video.*;
import java.awt.Rectangle;

ShimodairaOpticalFlow SOF;
Capture video;
OpenCV opencv;

ArrayList triangles = new ArrayList();
ArrayList points = new ArrayList();
ArrayList fills = new ArrayList();

Rectangle[] faces;

void setup() {
  size(1152, 700, P3D);
  smooth();
  video = new Capture(this, 1152, 700);
  opencv = new OpenCV(this, 1152, 700);
  opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE); 
  String[] cameras = Capture.list();

  if (cameras.length == 0) {
    println("There are no cameras available for capture. Exiting application");
    exit();
  } else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(cameras[i]);
    }
    // The camera can be initialized directly using an 
    // element from the array returned by list():
    Capture cam = new Capture(this, width, height, cameras[0]);
    cam.start();

    SOF = new ShimodairaOpticalFlow(cam);
  }
  video.start();
  //noLoop();

  for (float x = 0; x < width; x+= 30) {
    for (float y = 0; y < height; y+= 30) {
      points.add(new PVector(x, y, 0));
    }
  }
  // get the triangulated mesh
  triangles = Triangulate.triangulate(points);

  for (int i = 0; i < triangles.size(); i++)
    fills.add(color(random(255), random(255), random(255)));
}

void draw() {
  //background(0);//200);
  //lights();
  opencv.loadImage(video);
  //faces = opencv.detect();
  image(video, 0, 0 );
  video.loadPixels();

  // calculate optical flow
  SOF.calculateFlow(); 

  //int index = 0;
  //long redBucket = 0;
  //long greenBucket = 0;
  //long blueBucket = 0;

  // draw the mesh of triangles

  //fill(255);
  //for (int i = 0; i < triangles.size(); i++) {
  //  //fill((color) fills.get(i));
  //  Triangle t = (Triangle)triangles.get(i);
  //  vertex(t.p1.x, t.p1.y, t.p1.z);
  //  vertex(t.p2.x, t.p2.y, t.p2.z);
  //  vertex(t.p3.x, t.p3.y, t.p3.z);
  //  // *** maybe look at the RGB camera image based on these positions

  //}

  //update fill colors
  fills.clear();
  for (int i = 0; i < triangles.size(); i++) {
    Triangle t = (Triangle)triangles.get(i);
    color c = video.get(int(t.p1.x), int(t.p1.y));
    fills.add(c);
  }

  stroke(255, 40);
  strokeWeight(1.0);
  beginShape(TRIANGLES);
  for (int i = 0; i < triangles.size(); i++) {
    fill((color) fills.get(i), 235);
    Triangle t = (Triangle)triangles.get(i);
    vertex(t.p1.x, t.p1.y, t.p1.z);
    vertex(t.p2.x, t.p2.y, t.p2.z);
    vertex(t.p3.x, t.p3.y, t.p3.z);
  }
  endShape();
  //for (int i = 0; i < triangles.size(); i++) {


  //  color c = video.pixels[index];

  //  redBucket += red(c);
  //  greenBucket += green(c);
  //  blueBucket += blue(c);

  //  index++;    

  //  long redAverage = redBucket / index;
  //  long greenAverage = greenBucket / index;
  //  long blueAverage = blueBucket / index;
  //  color rgbAverage = color(redAverage, greenAverage, blueAverage);

  //  Triangle t = (Triangle)triangles.get(i);
  //  vertex(t.p1.x, t.p1.y, t.p1.z);
  //  vertex(t.p2.x, t.p2.y, t.p2.z);
  //  vertex(t.p3.x, t.p3.y, t.p3.z);
  //  fill(rgbAverage);
  //}
  video.updatePixels();


  //here's how you move point/vertices around
  for (int i = 0; i < points.size(); i++) {
    PVector p = (PVector) points.get(i);
    p.x += random(-1, 1);
    p.y += random(-1, 1);
  }

  // update poitn positions based on optical flow
  for (int i = 0; i < SOF.flows.size() - 2; i+=2) {
    PVector force_start = SOF.flows.get(i);
    PVector force_end = SOF.flows.get(i+1);
    PVector force_vector = PVector.sub(force_end, force_start);
    //if (force_vector.mag() < 20.0) //ignore smaller force vectors TRY WITH OR WITHOUT
    //continue;
    for (int t = 0; t < points.size(); t++) {
      PVector p = (PVector) points.get(t);

      force_vector.mult(0.9); // if too much movement

      if (p.dist(force_start) < 5)
        p.add(force_vector);
    }
  }

  // update the triangle fills based on the RGB camera image, or maybe do this up here ^***
  //fills.clear(); // empty the fills
  //for (float x = 0; x < width; x+= 30) {
  //  for (float y = 0; y < height; y+= 30) {
  //    // get the color from the RGB camera image (x, y)); // look up processing "pixels"
  //    // add the color you just got to the fills arraylist
  //  }
  //}


  // if you want to change the number of points
  // regenerate the points
  // then clear out and regenerate the triangles v
  //triangles.clear();
  //triangles = Triangulate.triangulate(points);
}

void keyPressed() {
  filter(INVERT);
  noStroke();
  beginShape(TRIANGLES);
  for (int i = 0; i < triangles.size(); i++) {
    Triangle t = (Triangle)triangles.get(i);
    vertex(t.p1.x, t.p1.y, t.p1.z);
    vertex(t.p2.x, t.p2.y, t.p2.z);
    vertex(t.p3.x, t.p3.y, t.p3.z);
  }
  endShape();
}
