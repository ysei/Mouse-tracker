/* 
 runs a single trial of the experiment, briefly:
 1) turns on a whisker touching motor for motorOnTime
 2) waits for a delay (currently 3s, may be random later)
 3) turns on both LEDs for 1s
 4) while LEDs are on and for expTimeOut time later detects
 a saccade to the correct (side of whisker touch) or incorrect
 side
 5) if saccade to correct side occurs before expTimeOut and also
 before eye movement to the incorrect side give reward through
 picoPin. Else trial is over.
 runs as its own thread so it can pause independently of the eye
 tracking part of the program
 
 arguments:
 side = which side to cue the mouse with the motor(left = 0, right = 1)
 */
class RunTrial implements Runnable {

  int side;
  int motor_led_delay;

  /**
  * side = which side the animal is cued to saccade to, determines which side the motor cue happens.
  * led_delay = length of time for the delay between the motor cue and the flashing of the leds. how long
  * the animal must remember which side to saccade to
  * 1) Buzz left or right motor
  * 2) wait a random amount of time between DELAY_MIN and DELAY_MAX (motor_led_delay)
  * 3) begin detecting a saccade, abort if saccade happens before the LEDs turn on
  * 3) flash both LEDs
  * 4) continue detecting saccade
  **/
  public RunTrial(int side, int motor_led_delay) {
    this.side = side;
    this.motor_led_delay = motor_led_delay; 
  }

  public void run() {
    experiment.trial_running = true;
    if(side == C_LEFT) {
      new Thread(leftMotor).start();
    }
    else if(side == C_RIGHT) {
      new Thread(rightMotor).start();
    }
    /**
     * begin the saccade detector
     * abort the trial if a saccade happens before the LEDs turn on
     **/
    experiment.detecting_saccade = true;
    experiment.penalize_saccade = true;
    println("Detecting a saccade to the " + decodeSide(side) + " during motor delay.");
    println("motor_led_delay is " + motor_led_delay);
    
    // adding these together is because we want the lights to turn on after the motor turns off
    threadSleep(experiment.MOTOR_ON_TIME + motor_led_delay);
    
    experiment.penalize_saccade = false;
    println("Detecting a saccade to the " + decodeSide(side) + ".");
    
    new Thread(leftLed).start();
    new Thread(rightLed).start();
    
    threadSleep(experiment.INTER_TRIAL_INTERVAL);
    experiment.trial_running = false;
    
    // uncomment below and comment out above if you want the LEDs only to flash on one side
    /*
    if(side == E_LEFT) {
      new Thread(leftLed).start();
    }
    else if (side == E_RIGHT) {
      new Thread(rightLed).start();
    }
    */
  }

  // puts the thread to sleep for sleepTime  
  public void threadSleep(int sleepTime) {
    try {
      Thread.sleep(sleepTime);
    }
    catch(InterruptedException ie) {
    }
  }
}


/**
 * holds information about the overall experiment
 */

public class Experiment {
  int trial_number; 
  
  int LED_ON_TIME;
  int TRIALS;
  int MOTOR_ON_TIME;
  int PICO_ON_TIME;
  int DELAY_MIN;
  int DELAY_MAX;
  int SACCADE_TIMEOUT;
  int INTER_TRIAL_INTERVAL;
  int motor_led_delay;      // time to delay between the motor cue and the LED turning on
  int total_saccade_time;
  
  
  boolean trial_running;
  boolean detecting_saccade;
  boolean penalize_saccade;
  
  Trial[] trials;

  public Experiment() {
    trial_number = 0;
    trials = new Trial[100];
  }
  
  int pickASide() {
    int side = int(random(0, 2));
    if(side == 0) {
      side = C_LEFT;
    }
    else if(side == 1) {
      side = C_RIGHT;
    }
    
    return(side);
  }
  
  void startNewTrial() {
    int side;
    RunTrial run_trial;
    
    if(trial_running) {
      println("Trial is already running!");
    }
    else {
      side = pickASide();
      trial_number = trial_number + 1;
      trial_running = true;
      println("Starting new trial, trial #" + trial_number);
      // delay time between when the motor finishes buzzing and the lights turn on
      motor_led_delay = int(random(DELAY_MIN, DELAY_MAX));
      total_saccade_time = MOTOR_ON_TIME + motor_led_delay + SACCADE_TIMEOUT;
      println("Total saccade time: " + total_saccade_time);
      trials[trial_number] = new Trial(trial_number, side);
      // record the start time of the experiment
      trials[trial_number].start_time = millis();
      run_trial = new RunTrial(side, motor_led_delay);
      new Thread(run_trial).start();
    }
  }
  
  public void stop(int result) {
    trial_running = false;
    detecting_saccade = false;
    penalize_saccade = false;
    
    switch(result) {
      case CORRECT_SACCADE:
        println("Detected correct saccade to " + decodeSide(trials[trial_number].side));
        break;
      case INCORRECT_SACCADE:
        println("Detected incorrect saccade away from " + decodeSide(trials[trial_number].side));
        break;
    }
  }
  
  public Trial getCurrentTrial() {
    return(trials[trial_number]);
  }

  public void readParams(String filename) {  
    String line;
    BufferedReader reader = createReader(filename);
    String[] m;
    
    try {
      while((line = reader.readLine()) != null) {
        m = match(line, "(\\w+) = (\\d+)");
        if(m != null) {
          if(m[1].equals("TRIALS")) {
            TRIALS = Integer.parseInt(m[2]);
          }
          else if(m[1].equals("LED_ON_TIME")) {
             LED_ON_TIME = Integer.parseInt(m[2]);
          }
          else if(m[1].equals("MOTOR_ON_TIME")) {
            MOTOR_ON_TIME = Integer.parseInt(m[2]);
          }
          else if(m[1].equals("PICO_ON_TIME")) {
            PICO_ON_TIME = Integer.parseInt(m[2]);
          }
          else if(m[1].equals("DELAY_MIN")) {
            DELAY_MIN = Integer.parseInt(m[2]);
          }
          else if(m[1].equals("DELAY_MAX")) {
            DELAY_MAX = Integer.parseInt(m[2]);
          }
          else if(m[1].equals("SACCADE_TIMEOUT")) {
            SACCADE_TIMEOUT = Integer.parseInt(m[2]);
          }
          else if(m[1].equals("INTER_TRIAL_INTERVAL")) {
            INTER_TRIAL_INTERVAL = Integer.parseInt(m[2]);
          }
          else {
            println("Unknown parameter in parameter file: " + m[1] + ".");
          }        
        }
      }
    }
    
    catch(IOException e) {
      e.printStackTrace();
      line = null;
    }
  }
}

public class Trial {
  int number;
  int start_time;
  int end_time;
  int saccade_time;
  int result;
  int motor_led_delay;
  int side;
  String videofile;
  
  Trial(int number, int side) {
    number = number;
    start_time = 0;
    end_time = 0;
    saccade_time = 0;
    result = 0;
    int led_delay = 0;
    videofile = null;
    side = side;
  } 
}
  

