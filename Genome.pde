import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

public static class Genome {
  public List<Synapse> genes = new ArrayList<Synapse>();
  public double fitness = 0;
  public int    maxNeuron = 0;
  public int    globalRank = 0;
  public double[] mutationRates;
  public Map<Integer, Neuron> network = null;

  private int connectionIndex = 0;
  private int linkIndex = 1;
  private int biasIndex = 2;
  private int nodeIndex = 3;
  private int enableIndex = 4;
  private int disableIndex = 5;
  private int stepIndex = 6;
  
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
      
      for (Synapse incoming : neuron.inputs) {
        Neuron other = network.get(incoming.input);
        sum += incoming.weight * other.value;
      }
      
      if(!neuron.inputs.isEmpty()) {
        neuron.value = Neuron.sigmoid(sum);
      }
    }
    
    for(Entry<Integer, Neuron> entry : network.entrySet()) {
      if (entry.getKey() < Pool.instance.inputs || entry.getKey() >= Pool.instance.inputs + Pool.instance.outputs)
        continue;
      Neuron neuron = entry.getValue();
      
      double sum = 0;
      
      for (Synapse incoming : neuron.inputs) {
        Neuron other = network.get(incoming.input);
        sum += incoming.weight * other.value;
      }
      
      if(!neuron.inputs.isEmpty()) {
        neuron.value = Neuron.sigmoid(sum);
      }
    }
    
    double[] output = new double[Pool.instance.outputs];
    for(int i = 0; i < Pool.instance.outputs; i++) {
      output[i] = network.get(Pool.instance.inputs + i).value;
    }
    
    return output;
  }
  
  public void generateNetwork() {
    network = new HashMap<Integer, Neuron>();
    for(int i = 0; i < Pool.instance.inputs; i++) {
      network.put(i, new Neuron());
    }
    for(int i = 0; i < Pool.instance.outputs; i++) {
      network.put(Pool.instance.inputs + i, new Neuron());
    }
    
    Collections.sort(genes, new Comparator<Synapse>() {
      public int compare(Synapse o1, Synapse o2) {
        return o1.output - o2.output;
      }
    });
    
    for(Synapse gene : genes) {
      if(gene.enabled) {
        if(!network.containsKey(gene.output)) {
          network.put(gene.output, new Neuron());
        }
        Neuron neuron = network.get(gene.output);
        neuron.inputs.add(gene);
        if(!network.containsKey(gene.input)) {
          network.put(gene.input, new Neuron());
        }
      }
    }
  }
  
  public void mutate() {
    for(int i = 0; i < 7; i++) {
      mutationRates[i] *= Pool.instance.rnd.nextBoolean() ? 0.95 : 1.05263;
    }
    
    if(Pool.instance.rnd.nextDouble() > mutationRates[connectionIndex]) {
      mutatePoint(); 
    }
    
    double prob = 0;
    
    prob = mutationRates[linkIndex];
    while(prob > 0) {
      if(Pool.instance.rnd.nextDouble() < prob) {
        mutateLink(false);
      }
      prob = prob - 1;
    }
    
    prob = mutationRates[biasIndex];
    while(prob > 0) {
      if(Pool.instance.rnd.nextDouble() < prob) {
        mutateLink(true);
      }
      prob = prob - 1;
    }
    
    prob = mutationRates[nodeIndex];
    while(prob > 0) {
      if(Pool.instance.rnd.nextDouble() < prob) {
        mutateNode();
      }
      prob = prob - 1;
    }
    
    prob = mutationRates[enableIndex];
    while(prob > 0) {
      if(Pool.instance.rnd.nextDouble() < prob) {
        mutateEnableDisable(true);
      }
      prob = prob - 1;
    }
    
    prob = mutationRates[disableIndex];
    while(prob > 0) {
      if(Pool.instance.rnd.nextDouble() < prob) {
        mutateEnableDisable(false);
      }
      prob = prob - 1;
    }
  }
  
  public void mutateEnableDisable(boolean enable) {
    List<Synapse> candidates = new ArrayList<Synapse>();
    
    for(Synapse gene : genes) {
      if(gene.enabled != enable) {
        candidates.add(gene);
      }
    }
    
    if(candidates.isEmpty()) {
      return;
    }
    
    Synapse gene = candidates.get(Pool.instance.rnd.nextInt(candidates.size()));
    gene.enabled = !gene.enabled;
  }
  
  public void mutateLink(boolean forceBias) {
    int neuron1 = randomNeuron(false, true);
    int neuron2 = randomNeuron(true, false);
    
    Synapse newLink = new Synapse();
    newLink.input = neuron1;
    newLink.output = neuron2;
    
    if(forceBias) {
      newLink.input = Pool.instance.inputs - 1;
    }
    
    if(containsLink(newLink)) {
      return;
    }
    
    newLink.innovation = ++Pool.instance.innovation;
    newLink.weight = Pool.instance.rnd.nextDouble() * 4 - 2;
    
    genes.add(newLink);
  }
  
  public void mutateNode() {
    if(genes.isEmpty()) {
      return;
    }
    
    Synapse gene = genes.get(Pool.instance.rnd.nextInt(genes.size()));
    if(!gene.enabled) {
      return;
    }
    
    gene.enabled = false;
    
    maxNeuron++;
    
    Synapse gene1 = gene.clone();
    gene1.output = maxNeuron;
    gene1.weight = 1;
    gene1.innovation = ++Pool.instance.innovation;
    gene1.enabled = true;
    genes.add(gene1);
    
    Synapse gene2 = gene.clone();
    gene2.input = maxNeuron;
    gene2.innovation = ++Pool.instance.innovation;
    gene2.enabled = true;
    genes.add(gene2);
  }
  
  public void mutatePoint() {
    for(Synapse gene : genes) {
      if(Pool.instance.rnd.nextDouble() < Pool.instance.perturbation) {
        gene.weight += Pool.instance.rnd.nextDouble() * mutationRates[stepIndex] * 
                        2 - mutationRates[stepIndex];  
      } else {
        gene.weight = Pool.instance.rnd.nextDouble() * 4 - 2;
      }
    }
  }
  
  public int randomNeuron(boolean nonInput, boolean nonOutput) {
    List<Integer> neurons = new ArrayList<Integer>();
    
    if(!nonInput) {
      for(int i = 0; i < Pool.instance.inputs; i++) {
        neurons.add(i);
      }
    }
    
    if(!nonOutput) {
      for(int i = 0; i < Pool.instance.outputs; i++) {
        neurons.add(Pool.instance.inputs + i);
      }
    }
    
    for(Synapse gene : genes) {
      if((!nonInput || gene.input >= Pool.instance.inputs) && 
         (!nonInput || gene.input > Pool.instance.inputs + Pool.instance.outputs)) {
        neurons.add(gene.input);   
      }
      
      if((!nonOutput || gene.output >= Pool.instance.inputs) && 
         (!nonOutput || gene.output > Pool.instance.inputs + Pool.instance.outputs)) {
        neurons.add(gene.output);   
      }
    }
    
    return neurons.get(Pool.instance.rnd.nextInt(neurons.size()));   
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