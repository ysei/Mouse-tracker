class ConvolutionObject {

  float score;
  int kernel_length;
  int skip_size;
  
  int max_x;
  int max_y;
  int max_loc;
  int[] coords;

  public ConvolutionObject() {
    max_x = 0;
    max_y = 0;
    max_loc = 0;
    score = 0;
    kernel_length = 20;
    skip_size = 1;
    coords = new int[3];
  }
  
  int[] getFeatureCoordinates() {
    coords[0] = max_x;
    coords[1] = max_y;
    coords[2] = max_loc;
    
    return coords;
  }

  // find the darkest spot on the image
  void findFeature(Capture cam) {
    // set bmax ridiculously high as an initial threshold
    score = 1000000000;
    for(int x = 0; x < cam.width; x = x + skip_size) {
      for(int y = 0; y < cam.height; y = y + skip_size) {
        int loc = x + y * cam.width;
        float bright = convolve(cam, x, y);
        // this magic number is to keep the dot relatively stable on my
        // test image
        // will need to get determined some other way
        if(bright < (score - 20000)) {
          score = bright;
          max_x = (x + (kernel_length / 2));
          max_y = (y + (kernel_length / 2));
          max_loc = max_x + max_y * cam.width;
        }
      }
    }
    println(score);
  }
  
  void findROIFeature(Capture cam) {
    score = 1000000000;
    for(int x = eyematcher.x0; x < eyematcher.x; x = x + skip_size) {
      for(int y = eyematcher.y0; y < eyematcher.y; y = y + skip_size) {
        int loc = x + y * cam.width;
        float bright = convolve(cam, x, y);
        if(bright < (score - 20000)) {
          score = bright;
          max_x = (x + (kernel_length / 2));
          max_y = (y + (kernel_length / 2));
          max_loc = max_x + max_y * cam.width;
        }
      }
    }
  }

  /**
   * iterates over a square of side length kernel_size summing the bright
   * ness of the pixels starting from (x, y) as the upper left corner of
   * the square
   * 
   * returns total intensity of the square
   **/
  private float convolve(Capture cam, int x, int y) {
    float val = 0;
    for(int i = 0; i < kernel_length; i++) {
      for(int j = 0; j < kernel_length; j++) {
        int xloc = x + i;
        int yloc = y + j;
        int loc = xloc + cam.width * yloc;
        loc = constrain(loc, 0, cam.pixels.length-1);
        val = val + brightness(cam.pixels[loc]);
      }
    }
    return val;
  }
}

