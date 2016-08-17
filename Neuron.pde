
import java.util.ArrayList;
import java.util.List;

public static class Neuron {
  public double value = 0;
  public List<Synapse> inputs = new ArrayList<Synapse>();
  
  public static double sigmoid(double x) {
    return 2.0 / (1.0 + Math.exp(-4.9 * x)) - 1;
  }
}