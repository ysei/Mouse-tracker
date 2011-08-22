/***
toggles a pin on and off with a specified amount of repetitions
and delay between on and off
run as a thread so the main loop can do other things

arguments:
pin = which pin to turn on the arduino
waitTime = how long to wait before turning it off
reps = number of times to turn the pin on and off
***/
class TogglePin implements Runnable {
  int pin;
  int waitTime;
  int reps;
  
  public TogglePin(int pin, int waitTime, int reps) {
    this.pin = pin;
    this.waitTime = waitTime;
    this.reps = reps;
  }
  
  public void run() {
    for(int i = 0; i < reps; i++) {
      writePin(pin, Arduino.HIGH);
      sleepThread(waitTime);
      writePin(pin, Arduino.LOW);
      sleepThread(waitTime);
    }
  }
  
  // write to the serial port, sleep for 1ms if the serial line is being
  // written to by a different thread
  private void writePin(int pin, int state) {
    if(serialInUse) {
      sleepThread(5);
      writePin(pin, state);
    }
    else {
      serialInUse = true;
      arduino.digitalWrite(pin, state);
      serialInUse = false;
    }
  }

  // puts the thread to sleep for a specified amount of time
  private void sleepThread(int sleepTime) {
    try {
      Thread.sleep(sleepTime);
    }
    catch(InterruptedException ie) {
    }
  }
}

