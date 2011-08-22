import processing.serial.*;
import cc.arduino.*;
import processing.video.*;

final int LEFT_LED_PIN = 12;
final int RIGHT_LED_PIN = 11;
final int LEFT_MOTOR_PIN = 10;
final int RIGHT_MOTOR_PIN = 9;
final int PICO_PIN = 8;
final int TEST_PIN = 2;

final int WHITE = 255;
final int BLACK = 0;

final int C_LEFT = -1;
final int C_RIGHT = 1;
final int C_CENTER = 0;

int ERROR = -100;

final int CORRECT_SACCADE = 1;
final int INCORRECT_SACCADE = -1;
final int NO_SACCADE = 0;
final int SACCADE_TIMED_OUT = 0;

final int ISIGHT_CAMERA_DEVICE = 6;
final int IR_CAMERA_DEVICE = 7;
final int ARDUINO_DEVICE = 0;

Arduino arduino;
int thresh = 100;

float exp_start_time = 0;

boolean serialInUse = false;

Experiment experiment;
EyeMatcher eyematcher;

TogglePin leftLed;
TogglePin rightLed;
TogglePin leftMotor;
TogglePin rightMotor;
TogglePin pico;
TogglePin testPin;

Capture cam;
ConvolutionObject conv_object;
SaccadeDetector saccade_detector;

// how many pixels from the border to pu the threshold bar, may
// need to get more dynamically determined later (mouse click on
// image maybe)
int bar_offset = 40;

void setup() {

  experiment = new Experiment();
  experiment.readParams("setup.txt");

  leftLed = new TogglePin(LEFT_LED_PIN, experiment.LED_ON_TIME, 5);
  rightLed = new TogglePin(RIGHT_LED_PIN, experiment.LED_ON_TIME, 5);
  leftMotor = new TogglePin(LEFT_MOTOR_PIN, experiment.MOTOR_ON_TIME, 1);
  rightMotor = new TogglePin(RIGHT_MOTOR_PIN, experiment.MOTOR_ON_TIME, 1);
  pico = new TogglePin(PICO_PIN, experiment.PICO_ON_TIME, 1);
  testPin = new TogglePin(TEST_PIN, experiment.LED_ON_TIME, 20);

  arduino = new Arduino(this, Arduino.list()[ARDUINO_DEVICE], 57600);
  arduino.pinMode(LEFT_LED_PIN, Arduino.OUTPUT);
  arduino.pinMode(RIGHT_LED_PIN, Arduino.OUTPUT);
  arduino.pinMode(LEFT_MOTOR_PIN, Arduino.OUTPUT);
  arduino.pinMode(RIGHT_MOTOR_PIN, Arduino.OUTPUT);
  arduino.pinMode(PICO_PIN, Arduino.OUTPUT);
  arduino.pinMode(TEST_PIN, Arduino.OUTPUT);

  size(640, 480);
  String[] devices = Capture.list();
  println(devices);
  // may be necessary to change which device this looks at
  cam = new Capture(this, width, height, devices[ISIGHT_CAMERA_DEVICE]);
  eyematcher = new EyeMatcher();

  conv_object = new ConvolutionObject();
  saccade_detector = new SaccadeDetector();

  // This is necessary to get the first commands sent to the arduino
  // to sync up while the arduino serial connection initializes
  // otherwise the first trial gets messed up
  try {
    Thread.sleep(1000);
  }
  catch(InterruptedException ie) {
  } 
  noLoop();
}


/**
 * main loop
 **/

int[] coords;
void draw() {

  /**
   * checks to see if the initial setup of the eye location is complete. if not, it does it.
   * user freezes the frame with 'e', sets a ROI around the eye clicking the mouse and dragging
   * and finally unfreezes the frame with 'd'
   **/
  if(!eyematcher.eye_is_set) {
    if(cam.available()) {
      cam.filter(GRAY);
      cam.read();
    }
    eyematcher.Setup();
    loop();
  }

  /**
   * if eye setup is complete, check to see if an experiment has been queued by the user with 'g'
   **/
  else if(eyematcher.eye_is_set) {

    // returns the coordinates of the center of the pupil for this frame
    coords = trackEye();

    // experiment will get turned on and off based on a timeout or
    // successful saccade or not, parameters TBD
    if(!experiment.trial_running) {
      if(key == 'g') {
        if((millis() - exp_start_time) > experiment.INTER_TRIAL_INTERVAL) {
          experiment.startNewTrial();
          exp_start_time = millis();
          key = 'p';
        }
      }
    }

    if(experiment.detecting_saccade) {
      if(saccade_detector.didSaccadeTimeout(exp_start_time)) {
        println("Saccade timeout!" + experiment.total_saccade_time);
        experiment.trial_running = false;
        experiment.detecting_saccade = false;
      }
      else {
        int result = saccade_detector.detectSaccade(coords[0], experiment.getCurrentTrial().side);
        // if saccade is successful
        if(result == 1) {
          // give reward
          println("reward!");
          new Thread(pico).start();
        }
        else if(result == -1) {
          println("failure");
          // no reward
        }
      }
    }
    loop();
  }
}

int[] trackEye() {
  if(cam.available()) {
    cam.read();
    cam.loadPixels();

    /**
     * threshold the pixels in the area of interest to make it easier for the tracker to
     * follow the pupil
     **/
    for(int x = eyematcher.x0; x < eyematcher.x; x = x + 1) {
      for(int y = eyematcher.y0; y < eyematcher.y; y = y + 1) {
        int loc = x + y * cam.width;
        if(green(cam.pixels[loc]) > thresh) {
          cam.pixels[loc] = color(WHITE);
        }
        else {
          cam.pixels[loc] = color(BLACK);
        }
      }
    }

    cam.updatePixels();

    //conv_object.findFeature(cam);
    conv_object.findROIFeature(cam);
    coords = conv_object.getFeatureCoordinates();

    cam.updatePixels();
    image(cam, 0, 0, width, height);
    eyematcher.DisplayROI();
    fill(WHITE);
    stroke(BLACK);
    ellipse(coords[0], coords[1], 10, 10);
    saccade_detector.DisplayBars();
    rectMode(CORNER);
    return(coords);
  }
  return(coords);
}

/**
 * decode the side to something human-parsable
 */
String decodeSide(int side) {
  if(side == C_LEFT) {
    return("left");
  }
  else if(side == C_RIGHT) {
    return("right");
  }
  else {
    println("Invalid side passed to decodeSide: " + side);
    exit();
    return("error");
  }
}



