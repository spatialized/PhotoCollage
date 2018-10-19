void folderSelected(File selection) {
  if (selection == null) 
    println("Window was closed or the user hit cancel.");
  else 
  {
    if (debug)
      println("You selected " + selection.getAbsolutePath());

    photoFolder = selection.getAbsolutePath();
    photos = new ArrayList();      // Empty current photo list
    loadPhotoFolder();

    startCollage = true;
  }
}

void keyPressed()
{
  if(key == 'f')
  {
    slowMode = !slowMode; 
  }
}