/************************************************/
/*
/*  Live-updating Animated Photo Collage 
/*  David Gordon
/*  
/*  Version 1.0    3/3/16
/*
/*  Created for Anthony Garcia's Recital, 3/8/16
/*  UCSB Art & Architecture Museum
/*
/************************************************/

// TO DO:
//
// >>> Make sure when focus switches it doesn't pick same image
// >>>  Memory issues -> need at least 50 photos            
//  Fix: If too many photos load at once, doesn't work
// change frequency of image height/width checks       OK?
//  

import com.drew.imaging.*;
import com.drew.imaging.jpeg.*;
import com.drew.metadata.*;
import com.drew.metadata.exif.*;
import com.drew.metadata.iptc.*;
import com.drew.metadata.jpeg.*;

import java.util.Objects;
import codeanticode.syphon.*;

// Debugging
boolean debug = true;
boolean detail = false;
boolean memory = false;

// File System
String photoFolder;                // Where the photos are stored
String dataFolder = "data/";        // Only for testing now
String sPath;
File pFolder;
File[] photoFiles, lastPhotoFiles;
ArrayList<File> photosToLoad;

// Network
SyphonServer server;              // For sending video frames to Resolume

// Graphics
boolean startCollage = false;
ArrayList<Photo2D> photos, photosLoading;
//int numPhotos = -1;
float slowSpeed = 0.1, fastSpeed = 1.75;
int photoAlpha = 110, photoBrightness = 140;

float scaleFactor;        // Image scaling factor

boolean initializedPhotos = false, initializedPhotosOnce = false;
PGraphics canvas;
Metadata metadata;

// Modes
boolean slowMode = true, focusMode = true;

// Settings
int photoUpdateFreq = 40;  // Frame rate to update folder 
int focusSwitchingFreq = 200; // Frame rate to select a different photo to focus on (focusMode == true)
int maxVisible = 40, maxToLoadAtOnce = 1;          // Maximum photos visible at a time

void settings() {
  size(800, 600, P2D);
  PJOGL.profile=1;
}

void setup()
{
  frameRate(30);
  colorMode(HSB);
  canvas = createGraphics(800, 600, P2D);
  //  sPath = sketchPath("");

  selectFolder("Select a folder containing images:", "folderSelected");

  //  photoFolder = sPath + dataFolder;

  scaleFactor = 12000 / width;
  photosToLoad = new ArrayList();
  
  server = new SyphonServer(this, "Processing Syphon");
}

void draw()
{
  if (startCollage)
  {
    boolean photosInitialized = initializedPhotos;        // Save current value of initializedPhotos

    if (!initializedPhotos && frameCount % 50 == 0)       // If waiting for photos to initialize, check status
      initializedPhotos = checkPhotosLoaded();            

    //if (initializedPhotos && !photosInitialized)          // Check if photos just finished loading, i.e. were not initialized until last check
    if (initializedPhotos && frameCount % 50 == 0 && photosLoading.size() > 0)                              // Check if all photos waiting to load have been initialized
    {
      if (photosLoading.size() > 0)
      {
        for (Photo2D p : photosLoading)    
        {
          p.initSize();             // Update height and width for each photo
          if(debug && detail)
            println("Added 1 to photos.");
          photos.add(p);            // Add new photos
        }
      }

      photosLoading = new ArrayList();

      if (!initializedPhotosOnce)
        initializedPhotosOnce = true;

      if (debug)
        println("Photos finished loading...");
    }

    if (frameCount % photoUpdateFreq == 0)   // Reload photo folder
    {
      if(photosToLoad.size() == 0)
        loadPhotoFolder();                    
      else
        loadPhotosToLoad();
    }

    canvas.beginDraw();
    canvas.background(0); 

    if (initializedPhotosOnce) 
      drawCollage();            // Draw the collage to the canvas

    canvas.endDraw();
    image(canvas, 0, 0);        // Draw the canvas on screen

    server.sendImage(canvas);

    updatePhotos();
    animatePhotos();
  }

  if (frameCount % 100 == 0)
  {
    if(startCollage)
      println("Photos.size():"+photos.size());
    
    if(debug && memory) printMem();
  }
}

// Print memory usage
void printMem() {
  int maxMemMB = int(Runtime.getRuntime().maxMemory()/1024/1024);
  int totalMemMB = int(Runtime.getRuntime().totalMemory()/1024/1024);
  int freeMemMB = int(Runtime.getRuntime().freeMemory()/1024/1024);
  println("memory [MB]:" + " max: " + maxMemMB + " | total: " + totalMemMB + " | free: " + freeMemMB);
}