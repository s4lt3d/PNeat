import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

public static class Genome {
  public List<Synapse> genes = new ArrayList<Synapse>();
  public double fitness = 0;
  public double maxNeuron = 0;
  public double globalRank = 0;
  public double[] mutationRates;
  public Map<Integer, Neuron> network = null;
  
  public Genome() {
    mutationRates = new double[] {
      Pool.instance.connectionMutation,
      Pool.instance.linkMutation,
      Pool.instance.biasMutation,
      Pool.instance.nodeMutation,
      Pool.instance.enableMutation,
      Pool.instance.disableMutation,
      Pool.instance.stepSize
    };
  }
  
  public Genome clone() {
    Genome g = new Genome();
    for(Synapse gene : genes) {
      g.genes.add(gene.clone());
    }
    g.maxNeuron = maxNeuron;
    for(int i = 0; i < 7; i++) {
      g.mutationRates[i] = mutationRates[i];
    }
    
    return g;
  }
  
  public boolean containsLink(Synapse link) {
    for(Synapse gene : genes){
      if(gene.input == link.input && link.output == gene.output){
        return true;
      }
    }
    return false;
  }
  
  public double disjoint(Genome genome) {
    double disjointGenes = 0;
    search: for(Synapse gene : genes) {
      for(Synapse other : genome.genes) {
        if(gene.innovation == other.innovation) {
          continue search;
        }
      }
      disjointGenes++;
    }
    
    return disjointGenes / Math.max(genes.size(), genome.genes.size());
  }
  
  public double[] evaluateNetwork(double[] input) {
    for(int i = 0; i < Pool.instance.inputs; i++) {
      network.get(i).value = input[i];
    }
    
    for(Entry<Integer, Neuron> entry : network.entrySet()) {
      if (entry.getKey() < Pool.instance.inputs + Pool.instance.outputs)
        continue;
      Neuron neuron = entry.getValue();
      
      double sum = 0;
      
      for (Synapsis incoming : neuron.inputs) {
        Neuron other = network.get(incoming.input);
        sum += incoming.weight * other.value;
      }
      
      if(!neuron.inputs.isEmpty()) {
        neuron.value = Neuron.sigmoid(sum);
      }
    }
  }
  
  public void generateNetwork() {
  
  }
  
  public void mutate() {
  
  }
  
  public void mutateEnableDisable(boolean enable) {
  
  }
  
  public void mutateLink(boolean forceBias) {
  
  }
  
  public void mutateNode() {
  
  }
  
  public void mutatePoint() {
  
  }
  
  public boolean sameSpecies(Genome genome) {
    double deltaDisjoint = Pool.instance.deltaDisjoint * disjoint(genome);
    double deltaWeight = Pool.instance.deltaWeights * weights(genome);
    return (deltaDisjoint + deltaWeight) < Pool.instance.deltaThreshold;
  }
  
  
  public double weights(Genome genome) {
    double sum = 0;
    double coincident = 0;
    search: for(Synapse gene : genes) {
      for(Synapse other : genome.genes) {
        if(gene.innovation == other.innovation) {
          sum += Math.abs(gene.weight - other.weight);
          coincident++;
          continue search;
        }
      }
    }
    
    return sum / coincident;
  }
}