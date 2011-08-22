class EyeMatcher {

  int x0, y0;
  int x, y;

  PImage setupImage;

  boolean eye_is_set;
  boolean frame_is_frozen;


  EyeMatcher() {
    x0 = 0;
    y0 = 0;
    x = 0;
    y = 0;
    eye_is_set = false;
    frame_is_frozen = false;
    setupImage = createImage(cam.width, cam.height, RGB);
  }

  void Setup() {

    /**
     * freeze the image on the screen if the key 'e' is pressed so we can hilight the ROI of the eye
     **/
    if(!frame_is_frozen) {
      image(cam, 0, 0);
      if(key == 'e') {
        cam.loadPixels();
        setupImage.copy(cam, 0, 0, cam.width, cam.height, 0, 0, cam.width, cam.height);
        setupImage.updatePixels();
        image(setupImage, 0, 0);
        frame_is_frozen = true;
      }
    }
    /**
     * draw the current rectangle for the ROI. if 'd' is pressed, set that as the ROI
     */
    else if(frame_is_frozen) {
      image(setupImage, 0, 0);
      DisplayROI();
      if(key == 'd') {
        eye_is_set = true;
        println("X0: " + x0 + " Y0: " + y0 + " x: " + x + " y: " + y);
        // set the saccade bars to the default (20% of the way from the edge of the ROI box)
        saccade_detector.setBars(true);
        frame_is_frozen = false;
      }
    }
  }
  
  void DisplayROI() {
    noFill();
    stroke(WHITE);
    rectMode(CORNERS);
    rect(x, y, x0, y0);
  }
}

void mouseDragged() {

  /***
   * During the initial selection of the ROI of the eye when the mouse is dragged, make the square bigger
   ***/
  if(eyematcher.frame_is_frozen) {
    eyematcher.x = mouseX;
    eyematcher.y = mouseY;
  }
}

void mouseClicked() {
  /**
   * Click to set the origin point for creating the eye ROI area
   **/
  if(eyematcher.frame_is_frozen) {
    eyematcher.x0 = mouseX;
    eyematcher.y0 = mouseY;
    eyematcher.x = mouseX;
    eyematcher.y = mouseY;
  }
}

void keyPressed() {
  if(key == ']') {
    thresh = thresh + 1;
    if(thresh > 255) {
      thresh = 0;
    }
  }
  
  if(key == '[') {
    thresh = thresh - 1;
    if(thresh < 0) {
      thresh = 255;
    }
  }
}


