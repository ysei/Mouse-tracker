class SaccadeDetector {

  int left_bar_loc;
  int right_bar_loc;

  SaccadeDetector() {
    left_bar_loc = 0 + int(cam.width * 0.2);
    right_bar_loc = int(cam.width - cam.width * 0.2);
  }
  
  void setBars(boolean def) {
    if(def) {
      int x_distance = eyematcher.x - eyematcher.x0;
      left_bar_loc = int(eyematcher.x0 + x_distance * 0.2);
      right_bar_loc = int(eyematcher.x - x_distance * 0.2);
    }
    else {
    }
  }
  
  /**
  * returns the location of the eye-- if it is to the left of the bar, return C_LEFT, right of the bar, C_RIGHT
  * in the center, C_CENTER
  **/
  int whereIsEye(int x) {
    if(x < left_bar_loc) {
      return(C_LEFT);
    }
    else if(x > right_bar_loc) {
      return(C_RIGHT);
    }
    else {
      return(C_CENTER);
    }
  }
  
  boolean didSaccadeHappen(int x) {
    int eye_location = whereIsEye(x);
    
    if(eye_location != C_CENTER) {
      return(true);
    }
    else {
      return(false);
    }
  }
  
  /**
  * returns if a saccade is correct
  **/
  int saccadeResult(int x, int side) {
    int eye_location = whereIsEye(x);
    
    if(eye_location == side) {
      return(CORRECT_SACCADE);
    }
    else if(eye_location == -side) {
      return(INCORRECT_SACCADE);
    }
    else {
      return(NO_SACCADE);
    }
  }
  
  /* check to see if the saccade has timed out */
  /* this is not right! fix it it has to be timed up with the start of hte light going on,
  not the start of the exeriment
  */
  boolean didSaccadeTimeout(float start_time) {
    float elapsed = millis() - start_time;
    if(elapsed > (experiment.total_saccade_time)) {
      return(true);
    }
    else {
      return(false);
    }
  }
  
  /**
  * just puts up the saccade boundary bars on the image as a visual reference
  **/
  void DisplayBars() {
    int rect_width = 1;
    int rect_height = eyematcher.y - eyematcher.y0;
    noStroke();
    fill(255, 0, 0);
    rectMode(CORNER);
    rect(saccade_detector.left_bar_loc, eyematcher.y0, rect_width, rect_height);
    rect(saccade_detector.right_bar_loc - rect_width, eyematcher.y0, rect_width, rect_height);
  }
}
