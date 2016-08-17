
public static class Synapse {
  public int     input = 0;
  public int     output = 0;
  public double  weight = 0;
  public boolean enabled = true;
  public int     innovation = 0;
  
  public Synapse clone() {
    Synapse s = new Synapse();
    s.input = input;
    s.output = output;
    s.weight = weight;
    s.enabled = enabled;
    s.innovation = innovation;
    return s;
  }
}