
import processing.video.*;

Capture cam;
PFont f;
PImage theImage;
PImage thePoster;
boolean imageSet;
boolean imageSet2;
int pixelGradientRad = 3; // should be odd

boolean saveAnimation = false;
boolean saveAnimationForReal = false;

int sampleRectHeight = 10;
int sampleRectWidth = 5;
int sampleColors = 9;
boolean scaleColors = true;
boolean displayColors = false;
boolean displayCam = false;
color colorVector = color(255, 0,0);
color [] colorVectors = new color[sampleColors];

String symbols = "#x@%+=-. ";
//String symbols = "$@B%8&WM#*oahkbdpqwmZO0QLCJUYXzcvunxrjft/\\|()1{}[]?-_+~<>i!lI;:,\"^`'. ";
boolean asciiInvert = true;
boolean asciiFlag = true;
boolean trueColorFlag = false;

int updateCounter = 0;
int updateRate = 5;

int colorUpdateCounter = 0;
int colorUpdateRate = 10000;

float brightness2(color c) {
   return (red(c) + blue(c) + green(c))/3.0f; 
}

void printCam() {
  println();
  for(int j = 0; j < cam.height; j+=sampleRectHeight) {
   for(int i = 0; i < cam.width; i+=sampleRectWidth) {
         int x = (i*thePoster.width)/cam.width;
         int y = (j*thePoster.height)/cam.height;
         color c = cam.pixels[(x*cam.width/thePoster.width) + (y*cam.height/thePoster.height)*cam.width];
         print(colorToSymbol(c));
      }
      println();
   }
}

void drawAsciiCam() {
  background(0);
  fill(255);
  textFont(f);
  textAlign(CENTER, CENTER);
  for(int j = 0; j < cam.height; j+=sampleRectHeight) {
   for(int i = 0; i < cam.width; i+=sampleRectWidth) {
         int x = (i*thePoster.width)/cam.width;
         int y = (j*thePoster.height)/cam.height;
         color c = cam.pixels[(x*cam.width/thePoster.width) + (y*cam.height/thePoster.height)*cam.width];
         if(asciiFlag) {
           float greyShade = greyShade(c);
           if(trueColorFlag) {
             fill(c); 
           }
           else if(displayColors) {
             fill(getColor(greyShade));
           }
           text(colorToSymbol(c), i, j);
         }
         else {
             float greyShade = greyShade(c);
             
             int saturation = (int)round((symbols.length() - 1)*greyShade/255.0);
             float saturation2 = saturation*255/(symbols.length()-1);
             if(trueColorFlag) {
                fill(c); 
             }
             else if(!asciiInvert) {
                fill(255 - saturation2); 
             }
             else {
               fill(saturation2);
             }
             
             if(displayColors) {
               fill(getColor(greyShade));
             }
             rect(i, j, sampleRectWidth, sampleRectHeight);
         }
      } 
   }
}

float greyShade(color c) {
   float redPart = 0.299;
  float greenPart = 0.587;
  float bluePart = 0.114;
  return ((red(c) * redPart) + (green(c) * greenPart) + (blue(c) * bluePart));
} 

char colorToSymbol(color c) {
  float greyShade = greyShade(c);
  int saturation = (int)floor((greyShade/255.0f)*symbols.length());
  if(saturation >= symbols.length()) saturation = symbols.length() - 1;
  if(asciiInvert) {
    return symbols.charAt(symbols.length() - 1 - saturation);
  }
  else {
      return symbols.charAt(saturation);
  }
}

void initColors() {
  color [] colorVectors2 = new color[sampleColors];
  float [] colorVectorLuminance = new float[sampleColors];
  int[] colorVectorIndexes = new int[sampleColors];
  float maxLuminance = 0;
  
  if(!scaleColors) {
    for(int i = 0; i < sampleColors; i++) {
       colorVectors2[i] = color((int) random(0,255), (int) random(0,255), (int) random(0,255));
       colorVectorLuminance[i] = greyShade(colorVectors2[i]);
       if(greyShade(colorVectors2[i]) > maxLuminance) {
          maxLuminance = greyShade(colorVectors2[i]); 
       }
       colorVectorIndexes[i] = -1;
    }
    
    // sort by increasing brightness
    for(int i = 0; i < sampleColors; i++) {
      float minLuminance = maxLuminance;
      int minIndex = -1;
      // find min luminance not already indexed
      for(int j = 0; j < sampleColors; j++) {
         if(colorVectorLuminance[j] <= minLuminance) {
            boolean indexFound = false;
            for(int k = 0; k < sampleColors; k++) {
               if(colorVectorIndexes[k] == j) {
                  indexFound = true;
                  break;
               } 
            }
            if(!indexFound) {
               minLuminance = colorVectorLuminance[j];
               minIndex = j; 
            }
         } 
      }
      
      colorVectorIndexes[i] = minIndex;
    }
    
    for(int i = 0; i < sampleColors; i++) {
       colorVectors[i] = colorVectors2[colorVectorIndexes[i]]; 
    }
  }
  else {
     // generate random colors, then scale to appropriate brightness
     for(int i = 0; i < sampleColors; i++) {
       color c = color((int) random(0,255), (int) random(0,255), (int) random(0,255));
       float scalar = (i*255.0f/(sampleColors-1))/greyShade(c);
       colorVectors[i] = color(red(c)*scalar, green(c)*scalar, blue(c)*scalar);
     } 
  }

}

color getColor(float intensity) {
   return colorVectors[(int)round((colorVectors.length-1) * intensity/255.0)];
}

void setup() {
  size(640, 512);

  String[] cameras = Capture.list();
  int preferred_camera_index = 0;
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(cameras[i]);
      if(cameras[i].toLowerCase().contains("640x") && cameras[i].toLowerCase().contains("fps=30")) {
          preferred_camera_index = i;
          break;
      }
    }
    
    println("Preferred camera " + preferred_camera_index + " : " + cameras[preferred_camera_index]);
    
    // The camera can be initialized directly using an 
    // element from the array returned by list():
    cam = new Capture(this, cameras[preferred_camera_index]);
    String cam_str = cameras[preferred_camera_index];
    // extract dimensions
    String size_str = new String("size=");
    String fps_str = new String(",fps=");
    int size_index = cam_str.indexOf(size_str);
    int fps_index = cam_str.indexOf(fps_str);
    String size_substr = cam_str.substring(size_index + size_str.length(), fps_index);
    int wide = Integer.parseInt(size_substr.substring(0, size_substr.indexOf("x")));
    int tall = Integer.parseInt(size_substr.substring(size_substr.indexOf("x") + 1, size_substr.length()) );
    size(wide, tall);
    cam.start();     
  }
  imageSet = false;
  imageSet2 = false;
 
  initColors();
  int fontsize = 2*sampleRectWidth;
  f = createFont("Courier New Bold",fontsize,false); 
    
  for(int i = 0; i < symbols.length(); i++) {
    print(symbols.charAt(i)); 
  }
   println();
   
   printDirections();
}

void draw() {
  imageSet = false;
  int posterWidth = 0;
  int posterHeight = 0;
  if(millis() > updateCounter) {
      updateCounter = millis() + updateRate + (floor(random(0, updateRate)));
  }
  else {
     return; 
  }
  
  if(millis() > colorUpdateCounter) {
      colorUpdateCounter = millis() + colorUpdateRate + (floor(random(0, colorUpdateRate)));
      initColors();
  }
  
  if (cam.available() == true && imageSet == false) {
    cam.read();
    imageSet = true;
    imageSet2 = true;
    posterWidth = cam.width/sampleRectWidth;
    posterHeight = cam.height/sampleRectHeight;
    theImage = createImage(posterWidth, posterHeight, RGB);
    theImage.copy(cam, 0, 0, cam.width, cam.height, 0, 0, posterWidth, posterHeight);
    thePoster = createImage(posterWidth, posterHeight, RGB);
    
   
    theImage.loadPixels();
    for(int i = 0; i < posterWidth; i++) {
      for(int j = 0; j < posterHeight; j++) {
        color c = theImage.pixels[i*posterHeight + j];
        float intensity = brightness(c);
        int intensityIndex = floor(intensity/255.0 * sampleColors);
        thePoster.pixels[i*posterHeight + j] = colorVectors[intensityIndex];
      }
    }
    thePoster.updatePixels();
  }
  else {
   // cam has failed
  }
  
  if(imageSet2 == true) {
     if(displayCam) {
       image(cam, 0, 0); 
     }
     else {
       drawAsciiCam();
     }
     
  }
  else {
     // image generation has failed 
  }
  

}

void printDirections() {
   println("Commands:");
   println("\tSPACE\tRefresh colors (random color mode must be enabled)");
   println("\tt\tenable and disable true color display on ascii images");
   println("\tr\tenable and disable random color map display");
   println("\tc\tenable and disable ASCII character display");
   println("\to\tenable and disable original camera image display");
   println("\ti\tenable and disable monochrome intensity inversion (color mode must be disabled)");
   println("\ts\tenable and disable scaling of random colors to match appropriate intensities (color mode must be enabled)");
   println("\tp\tprint current random colors to console (hex)");
   println("\ta\tprint current camera frame rendered in ASCII to console"); 
   println("\tq\tquit"); 
}

void keyPressed() {
   if(key == ' ') {
      colorUpdateCounter = millis();
   } 
   if(key == 'p' || key == 'P') {
      for(int i = 0; i < sampleColors; i++) {
         print(hex(colorVectors[i]) + ", ");
      } 
      println("");
   }
   if(key == 'a' || key == 'A') {
       printCam();
   }
   
   if(key == 'i' || key == 'I') {
       asciiInvert = !asciiInvert;
   }
   
   if(key == 'c' || key == 'C') {
       asciiFlag = !asciiFlag;
   }
   
   if(key == 's' || key == 'S') {
       scaleColors = !scaleColors;
       colorUpdateCounter = millis();
   }
   
   if(key == 'r' || key == 'R') {
       displayColors = !displayColors;
   }
   
   if(key == 'q' || key == 'Q') {
       exit();
   }
   
   if(key == 'o' || key == 'O') {
       displayCam = !displayCam;
   }
   
   if(key == 't' || key == 'T') {
       trueColorFlag = !trueColorFlag;
   }
}

