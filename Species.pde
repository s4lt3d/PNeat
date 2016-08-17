import java.util.ArrayList;
import java.util.List;

public static class Species {  
  public List<Genome> genomes = new ArrayList<Genome>();
  public double topFitness = 0;
  public double averageFitness = 0;
  public int staleness = 0;
  
  
  public Genome breedChild() {
    Genome child;
    if(Pool.instance.rnd.nextDouble() < Pool.instance.crossover) {
      Genome g1 = genomes.get(Pool.instance.rnd.nextInt(genomes.size()));
      Genome g2 = genomes.get(Pool.instance.rnd.nextInt(genomes.size()));
      child = crossover(g1, g2);
    } else {
      child = genomes.get(Pool.instance.rnd.nextInt(genomes.size())).clone();
    }
    
    child.mutate();
    return child;
    
  }
  
  public void calculateAverageFitness() {
    
  }
  
  public Genome crossover(Genome g1, Genome g2) {
    if(g1.fitness > g2.fitness) {
      Genome tmp = g1;
      g1 = g2;
      g2 = tmp;
    }
    
    Genome child = new Genome();
    outerloop: for(Synapse gene1: g1.genes){
      for(Synapse gene2 : g2.genes) {
        if(gene1.innovation == gene2.innovation) {
          if(Pool.instance.rnd.nextBoolean() && gene2.enabled) {
            child.genes.add(gene2.clone());
            continue outerloop;
          } else {
            break;
          }
        }
      }
      child.genes.add(gene1.clone());
    }
    
    child.maxNeuron = Math.max(g1.maxNeuron, g2.maxNeuron);
    for(int i = 0; i < 7; i++) {
      child.mutationRates[i] = g1.mutationRates[i];
    }
    
    return new Genome();
  } 
}