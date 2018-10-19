void loadPhotoFolder()                  // Load photos up to limit  to load at once, save those over limit to load later
{
  int numPhotos = -1;
  File[] uniqueFiles = new File[1];
  initializedPhotos = false;            // Have the photos in the folder been initialized?
  photosLoading = new ArrayList();      // Empty current photo list

  if (photoFolder == null)
  {
    println("No photo folder!");
    exit();
  }

  pFolder = new File(photoFolder); 
  photoFiles = new File[0];  

  if (initializedPhotosOnce)
  {
    uniqueFiles = GetUniqueFileList(lastPhotoFiles, pFolder.listFiles());      // Compare last photo list with current one

    if (uniqueFiles.length > 0)
      photoFiles = MergeFileArrays(lastPhotoFiles, uniqueFiles);
    else
      photoFiles = pFolder.listFiles();
  } 
  else
  {
    photoFiles = pFolder.listFiles();
  }

  lastPhotoFiles = photoFiles;     // Save list of currently loaded photo files

  if (!initializedPhotosOnce)      // When function is first called, all files are unique
    uniqueFiles = photoFiles;

  try                             // Add unique images to display
  {
    numPhotos = uniqueFiles.length;
//    loadMetadataFiles(uniqueFiles);    // For testing

    for (int i=0; i<numPhotos; i++)
    {
      if (!uniqueFiles[i].getPath().contains("DS_Store"))
      {  
        if(i < maxToLoadAtOnce)
        {
          int orientation = loadMetadata(uniqueFiles[i]);
          photosLoading.add(new Photo2D(i, uniqueFiles[i], orientation, true));    // Add to list of photos to load
          if (debug && detail)
            println("Added "+ uniqueFiles[i].getPath()+" to photosLoading...");
        }
        else
        {
          photosToLoad.add(uniqueFiles[i]);    // Add to list of photos to load
          if (debug && detail)
            println("Added "+ uniqueFiles[i].getPath()+" to photosToLoad...");
        }
      } 
      else
      {
        if (debug && detail)
          println("Skipped "+ uniqueFiles[i].getPath()+"...");
      }
    }

    if (debug && detail)
      println("Prepared "+numPhotos+" photos for loading...");

    if (numPhotos == 0)
      initializedPhotos = true;      // Set initialized photos back to true if no new photos to load
  }
  catch(NullPointerException npe)
  {
    println("Error: 'data' folder not found! "+npe);
    exit();
  }
}

void loadPhotosToLoad()          // Load photos previously over limit to load at once
{
  int numToLoad = 0;
  ArrayList<File> photosSetToLoad = new ArrayList();

  try                             // Add unique images to display
  {
    println("photosToLoad.size(): "+ photosToLoad.size());

    if(photosToLoad.size() < maxToLoadAtOnce)
      numToLoad = photosToLoad.size();
    else
      numToLoad = maxToLoadAtOnce;
    
    if(debug)
    println("Will load "+ numToLoad+" from photosToLoad.");
    
    for (int i=0; i<numToLoad; i++)
    {
      File f = photosToLoad.get(i);
      int orientation = loadMetadata(f);

      photosLoading.add(new Photo2D(i, f, orientation, true));    // Add to list of photos to load
      if (debug && detail)
        println("Added "+ f+" to photosLoading...");
      
      photosSetToLoad.add(f);
    }
    
    if(photosToLoad.size() < maxToLoadAtOnce)
      photosToLoad = new ArrayList();
    else
    {
      //println("ERROR HERE");
        //println("numToLoad:"+numToLoad);
        //println("photosToLoad.size():"+photosToLoad.size());
      for (File f : photosSetToLoad)
      {
        //print("i:"+i);
        //println("photosToLoad.size():"+photosToLoad.size());
        photosToLoad.remove(f);
      }
    }
  }
  catch(NullPointerException npe)
  {
    if(debug)
    println("Error: 'data' folder not found! "+npe);
    exit();
  } 
}

boolean checkPhotosLoaded()
{
  boolean photosLoaded = true;

  if (initializedPhotos)
    return true;
  else
  {
    for (Photo2D p : photosLoading)
    {
      if ((p.photo.width == 0) || (p.photo.width == -1))
        photosLoaded = false;
    }
  }

  return photosLoaded;
}

File[] GetUniqueFileList(File[] lastFiles, File[] newFiles)
{
  ArrayList<File> uniqueList = new ArrayList();

  for (File n : newFiles)    // Iterate through new files
  {
    boolean isUnique = true;

    //if(debug && detail && frameCount % 50 == 0)
    //  println("Checking "+n.getPath());

    for (File f : lastFiles)    // Iterate through last files
    {
      if (Objects.equals(f.getPath(), n.getPath()))
      {
        isUnique = false;

        // if (debug && detail)
        //   println(n.getPath()+" isn't unique: "+f.getPath()+" exists.");
      }
    }

    if (isUnique)
    {
      if (debug)
        println("Identified new photo:"+n.getPath());

      uniqueList.add(n);
    }
  }

  File[] unique = new File[uniqueList.size()];
  int index = 0;

  for ( File u : uniqueList )
  {
    unique[index] = uniqueList.get(index);
    index++;
  }

  return unique;
}

File[] MergeFileArrays(File[] array1, File[] array2)
{
  int aLen = array1.length;
  int bLen = array2.length;
  File[] c= new File[aLen+bLen];
  System.arraycopy(array1, 0, c, 0, aLen);
  System.arraycopy(array2, 0, c, aLen, bLen);
  return c;
}

int loadMetadata(File pf)
{
  int orientation = -1;
  Metadata metadata = null;
  
  try
  {
    metadata = JpegMetadataReader.readMetadata(pf);
  }
  catch (JpegProcessingException ex)
  {
    if(debug) println("JpegProcessingException:" + pf.getName());
  }
  catch (IOException ex)
  {
    if(debug) println("IOException:" + pf.getName());
  }
  catch (NoClassDefFoundError ex)
  {
    if(debug && detail) println("IOException:" + pf.getName());
  }
  if (metadata != null)
  {
    orientation = extractOrientation(metadata);
  }
  else if(debug) println("Null metadata!");
  
  //println("Orientation:"+orientation);
  return orientation;
}

int extractOrientation(Metadata metadata)
{
  Directory directory = null;
  
  //if(metadata.containsDirectory(JpegDirectory.class))
  if(metadata.containsDirectory(ExifIFD0Directory.class))
    directory = metadata.getDirectory(ExifIFD0Directory.class); 
  
   String tagString = "";

   for (Tag tag : directory.getTags()) 
   {
     if (tag.getTagName().equals("Orientation"))
     {
       tagString = tag.toString();
       //if(debug && detail)  println("tag:"+tag);
     }
   }

  if (tagString.equals("[Exif IFD0] Orientation - Right side, top (Rotate 90 CW)"))
  {
   return 90;
  } else if (tagString.equals("[Exif IFD0] Orientation - Top, left side (Horizontal / normal)"))
  {
   return 0;
  } else if (tagString.equals("[Exif IFD0] Orientation - Bottom, right side (Rotate 180)"))
  {
  return 180;
  } else if (tagString.equals("[Exif IFD0] Orientation - Right side, top (Rotate 90 CW)"))
  {
  return 0;
  }


   if (directory.hasErrors()) {
     for (String error : directory.getErrors()) {
       System.err.println("ERROR: " + error);
     }
   }
  
  
  return -1;
}


void loadMetadataFiles(File[] imageFiles)
{
 int numImages = imageFiles.length;

 for (int count = 0; count < numImages; count++)
 {
   File pf = null;
   Metadata metadata = null;
   //ExifProcessing exifProcessing = new ExifProcessing();

   try
   {
     pf = imageFiles[count];
     metadata = JpegMetadataReader.readMetadata(pf);
     //metadata = null;
   }

   catch (JpegProcessingException ex)
   {
     // println("JpegProcessingException:" + pf.getName());
   }
   catch (IOException ex)
   {
     // println("IOException:" + pf.getName());
   }
   //catch (InvocationTargetException ex)
   //{
   //  // println("IOException:" + pf.getName());
   //}
   catch (NoClassDefFoundError ex)
   {
     // println("IOException:" + pf.getName());
   }
   //catch (IOException ex)
   //{
   //  // println("IOException:" + pf.getName());
   //}

   if (metadata != null)
   {

     extractOrientations(metadata);
   }
 }
}

void extractOrientations(Metadata metadata)
{
 for (Directory directory : metadata.getDirectories()) 
 {
   String tagString = "";
    //println("Directory:"+directory.getDescription
   for (Tag tag : directory.getTags()) 
   {
     if (tag.getTagName().equals("Orientation"))
     {
       tagString = tag.toString();

       //if(debug && detail)
         println("tag:"+tag);
         println("tagString:"+tagString);
     }
   }

   if (directory.hasErrors()) {
     for (String error : directory.getErrors()) {
       System.err.println("ERROR: " + error);
     }
   }
 }


}