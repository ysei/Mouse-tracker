/* Reads in the configuration files and returns a hash of the parameters of the experiment
*  Expects a list of key-value pairs in the following format:
*  KEY = VALUE
*  = must be currounded by spaces, also no blank spaces in the file ATM
*/

/*void read_config(String filename) {
  String line;
  BufferedReader reader = createReader(filename);
  String[] m;
  
  try {
    while((line = reader.readLine()) != null) {
      m = match(line, "(\\w+) = (\\d+)");
      if(m != null) {
        params.put(m[1], m[2]);
        println(m[1] + ": " + params.get(m[1]));
      }
    }
  }
  catch(IOException e) {
    e.printStackTrace();
    line = null;
  }
}*/

/*void write_results(String filename) {
  PrintWriter output = createWriter(filename);
  
  Iterator i = params.entrySet().iterator();
  
  while(i.hasNext()) {
    Map.Entry entry = (Map.Entry)i.next();
    output.println(entry.getKey() + ", " + entry.getValue());
  }
  
  output.flush();
  output.close();
}*/

  
  
