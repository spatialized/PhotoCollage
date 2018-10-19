class Photo2D
{
  PVector location, destination;
  int id;
  int photoWidth, photoHeight;
  File photoFile;
  PImage photo;
  String filePath;
  boolean valid, collision, visible;
  float theta;
  float alpha, brightness;
  float alphaMax, brightnessMax;
  boolean focusedOn, recenter = false;
  int orientation;
  boolean fadeOut = false, fadeIn = false, hiding = false, showing = false;
  int fadeInEndFrame = 0, fadeOutEndFrame = 0, hideEndFrame = 0, showEndFrame = 0;    // Frames
  float hideStartAlpha = -1;
  
  Photo2D(int newID, File newPhotoFile, int newOrientation, boolean isVisible)
  {
    id = newID;
    photoFile = newPhotoFile;
    
    int newX = int(map(random(1000), 0, 1000, photoWidth, width-photoWidth*2));
    int newY = int(map(random(1000), 0, 1000, photoHeight/2, height-photoHeight*2.5));
    
    location = new PVector(newX, newY);
    destination = new PVector(0, 0);

    valid = true;
    collision = false;
    theta = random(2 * PI);
    orientation = newOrientation;
    visible = isVisible;
    
    alpha = 0;
    brightness = 0;
    alphaMax = photoAlpha;
    brightnessMax = photoBrightness;
    
    if(newPhotoFile != null)
    {
      filePath = newPhotoFile.getPath();

      if (!filePath.contains("DS_Store"))
        filePath = photoFile.getPath();
      else
        valid = false;
  
      if (valid)
      {
        photo = requestImage(filePath);    // Start loading asynchronously
      }
    }
  }

  void initSize()
  {
    photoWidth = int(photo.width / scaleFactor);
    photoHeight = int(photo.height / scaleFactor);
  }

  void drawImage()
  {
    int hue = 255;
    int saturation = 255;

    //tint(brightness, alpha);
    //image(photo, location.x, location.y, photoWidth, photoHeight);

    canvas.pushMatrix();
    if (debug && frameCount % 100 == 0)
    {
      //println("translate x:"+location.x);
      //println("translate y:"+location.y);
    }

    //canvas.translate(location.x+photoWidth/2, location.y+photoHeight/2);
    switch(orientation)
    {
    case 0:
      canvas.translate(location.x+photoWidth/2, location.y+photoHeight/2);
      break;
    case 90:
      canvas.translate(location.x+photoHeight/2, location.y+photoWidth/2);
      canvas.rotate(radians(90));
      break;
    case 180:
      canvas.translate(location.x+photoWidth/2, location.y+photoHeight/2);
      canvas.rotate(radians(180));
      break;
    case 270:
      canvas.translate(location.x+photoHeight/2, location.y+photoWidth/2);
      canvas.rotate(radians(270));
    default:
      //canvas.translate(location.x+height/2, location.y+width/2);
      break;
    }

    //if (debug && recenter)
      //canvas.tint(0, 255, brightness, alpha);
    //else 
      canvas.tint(brightness, alpha);

    canvas.image(photo, 0, 0, photoWidth, photoHeight);
    canvas.popMatrix();
  }
  
  void hide()
  {
     hideStartAlpha = alpha;
     hideEndFrame = frameCount + 100;
     hiding = true;
     fadeOut = true;
     fadeOutEndFrame = frameCount + 100;
     println("HIDING:"+id+"   hiding:"+hiding);
  }
  
  void show()
  {
     println("Start alpha:"+alpha);
     showEndFrame = frameCount + 100;
     showing = true;
     fadeIn = true;
     fadeInEndFrame = frameCount + 100;
     println("SHOWING:"+id);
  }

  void animate()
  {
    float r;    // Radius

    if (slowMode)
    {
      r = slowSpeed;
      if (frameCount % 2 == 0)
      {
        location.y += r * sin(theta);
        location.x += r * cos(theta);
      }

      if (location.x > width-photoWidth*2)            // Right
      {
        if (!recenter)
        {
          recenterImage();
          //if(debug)
          //  println("HIT RIGHT X "+location.x+"  past  "+(width-photoWidth*2));
        }
      }
      if (location.x < photoWidth)   // Left
      {
        if (!recenter)
        { 
          recenterImage();
          //if(debug)
          // println("HIT LEFT Y "+location.x+"  past  "+(photoWidth));
        }
      }
      if (location.y > height-photoHeight*2)   // Bottom
      {
        if (!recenter)
        {
          recenterImage();
          //if(debug)
          // println("HIT BOTTOM Y "+location.y+"  past  "+(height-photoHeight*2));
        }
      }
      if (location.y < photoHeight)   // Top
      {
        if (!recenter)
        {
          recenterImage();
          //if(debug) 
           //println("HIT TOP Y"+location.y+"  past  "+(photoHeight));
        }
      }
    } 
    else
    {
      r = fastSpeed;
      location.y += r * sin(theta);
      location.x += r * cos(theta);

   if (location.x > width)            // Right
      {
        if (!recenter)
        {
          recenterImage();
        }
      }
      if (location.x < -photoWidth)   // Left
      {
        if (!recenter)
        { 
          recenterImage();
        }
      }
      if (location.y > height)   // Bottom
      {
        if (!recenter)
        {
          recenterImage();
        }
      }
      if (location.y < 0)   // Top
      {
        if (!recenter)
        {
          recenterImage();
        }
      }

    }
  }

  void update()
  {
    theta += (random(100)-50) * 0.005;      // Change angle

    if (!fadeOut && !fadeIn)  // Normal alpha
    {
      if(visible)
      {
        if (alpha < alphaMax)
          alpha ++;
  
        if (alpha > alphaMax)
          alpha --;
      }
    } 
    else if (fadeOut)      // Alpha when recentering
    {
      if (frameCount <= fadeOutEndFrame)
      {
        if(recenter)
          alpha = map(fadeOutEndFrame - frameCount, 0, 100, 0, 255);
        if(hiding)
          alpha = map(fadeOutEndFrame - frameCount, 0, 100, 0, hideStartAlpha);
      } 
      else
      {
        fadeOut = false;
        
        if(recenter)
        {
          if(visible)
          {
            fadeIn = true;
            fadeInEndFrame = frameCount + 100;
          }
          
          location = destination;
          
          if(debug && detail)
            println("Recentered "+id+" X:"+location.x+" Y:"+location.y);
        }
        
        if(hiding)
        {
          //hiding = false;
          visible = false;
          alpha = 0;
          if(debug)
          {
            print("Hid "+id);
            //println(" alpha:"+alpha);
          }
        }
      }
    } 
    else if (fadeIn)      // Alpha when recentering
    {
      if (frameCount <= fadeInEndFrame)
      {
        alpha = 255 - map(fadeInEndFrame - frameCount, 0, 100, 0, 255);
        //if(debug) println("Fading in:"+alpha);
      } 
      else
      {
        fadeIn = false;
        if(recenter)
          recenter = false;
        if(showing)
          showing = false;
      }
    }

//    if(id == 1 && frameCount % 20 == 0)
//    {
//      print("alpha:"+alpha);
//      print("fadeIn:"+fadeIn);
//      println("fadeOut:"+fadeOut);
//    }

    if (brightness < brightnessMax)
      brightness ++;

    if (brightness > brightnessMax)
      brightness --;

    //if (collision)
    //{
    //  recenterImage();
    //  collision = false;
    //}
  }

  void recenterImage()
  {
    if(debug && detail)
      println("Recentering "+id+" from X:"+location.x, " Y:"+location.y);
  
    recenter = true;
    fadeOut = true;
    //println("X between "+(photoWidth)+" and "+(width-photoWidth*2));
    //println("Y between "+(photoHeight)+" and "+(height-photoHeight*2));
    int newX = int(map(random(1000), 0, 1000, photoWidth, width-photoWidth*2));
    int newY = int(map(random(1000), 0, 1000, photoHeight/2, height-photoHeight*2.5));
    destination = new PVector(newX, newY);    // Make this smoother
    fadeOutEndFrame = frameCount + 100;
  }
}

void drawCollage()
{
  for (Photo2D p : photos)
  {
    if ((p.photo.width != 0) && (p.photo.width != -1))  // If photo has loaded
    {
      if(p.visible)
        p.drawImage();
    }
  }
}

void animatePhotos()
{
  for (Photo2D p : photos)
  {
    if(p.visible)
      p.animate();
  }
}

void updatePhotos()
{
  for (Photo2D p : photos)
    p.update();

  if (frameCount % focusSwitchingFreq == 0 && photos.size() > 0)
    shuffleFocusedPhoto();

  //if(frameCount % 100 == 0 && photos.size() > maxVisible)  // If photos exceed maxVisible
  //{
  //  int visibleCount = 0;
  //  for(Photo2D p : photos)
  //  {
  //    if(p.visible && !p.hiding)
  //      visibleCount++;
  //  }
  //  if(visibleCount > maxVisible)  // If more photos are visible than maxVisible
  //  {
  //    int diff = visibleCount - maxVisible;
  //    hideRandomPhotos(diff);
  //  }
  //  else
  //  {
  //    showRandomPhoto();
  //  }
  //}
}

void hideRandomPhotos(int num)
{
   //println("Hiding "+num+" photos");
  for(int i=0; i<num; i++)
  {
    Photo2D p = new Photo2D(-1, null, -1, false);  // Empty Photo2D
    while (!p.visible && !p.hiding)          // Search until a visible photo is found
    {
      int photoID = int(random(photos.size()));
      p = photos.get(photoID);
    }
    p.hide();
    //println("p.id:"+p.id+" p.hiding:"+p.hiding);
  }
}

void showRandomPhoto()
{
    Photo2D p = new Photo2D(-1, null, -1, true);  // Empty Photo2D
    int count = 0;
    
    while ((p.visible || p.alpha > 0) && count < 20)          // Search until a hidden photo is found
    {
      int photoID = int(random(photos.size()));
      p = photos.get(photoID);
      count++;
    }
    
    if(count >= 20) p = new Photo2D(-1, null, -1, true);
    
    if(p.id != -1)
      p.show();
}

void shuffleFocusedPhoto()
{
  int newID = 0;
  
  while(photos.get(newID).focusedOn || !photos.get(newID).visible)   // So doesn't pick same or hidden photo
    newID = int(random(photos.size())); 
  
  for (Photo2D p : photos)
  {
    if (p.id == newID)
    {
      p.alphaMax = 255;
      p.brightnessMax = 255;
      p.focusedOn = true;
    } 
    else if ( p.focusedOn )
    {
      p.alphaMax = photoAlpha;
      p.brightnessMax = photoBrightness;
      p.focusedOn = false;
    }
  }
}

//void checkCollisions()      // TO DO
//{
//  for (Photo2D p : photos)
//  {
//    if (p.location.x + p.photoWidth > width || p.location.y + p.photoHeight > height) 
//    {
//      p.collision = true;

//      if (debug && detail)
//        println("Collision at photo "+p.id);
//    }
//  }
//}