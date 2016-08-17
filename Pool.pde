import java.util.ArrayList;
import java.util.List;
import java.util.Collections;
import java.util.Comparator;
import java.util.Random;

public static class Pool {
  public int population = 50;
  public int staleSpecies = 15;
  public int inputs = 4;
  public int outputs = 1;
  public int timeout = 20;
  
  public double deltaDisjoint = 2;
  public double deltaWeights = 0.4;
  public double deltaThreshold = 1;
  
  public double connectionMutation = 0.25;
  public double linkMutation = 2;
  public double biasMutation = 0.4;
  public double nodeMutation = 0.5;
  public double enableMutation = 0.2;
  public double disableMutation = 0.4;
  public double stepSize = 0.1;
  public double perturbation = 0.9;
  public double crossover = 0.75;
  
  public Random rnd = new Random();
  
  public List<Species> species = new ArrayList();
  public int generation = 0;
  public int innovation = outputs;
  public double maxFitness = 0;
  
  static Pool instance = null;
  
  public Pool() {
    instance = new Pool();
  }
    
 
  public void addToSpecies(Genome child) {
    for(Species species : instance.species){
      if(child.sameSpecies(species.genomes.get(0))){
        species.genomes.add(child);
        return;
      }
    }
    
    Species childSpecies = new Species();
    childSpecies.genomes.add(child);
    species.add(childSpecies);
  }
  
  public void cullSpecies(boolean cutToOne) {
    for(Species species : instance.species) {
      Collections.sort(species.genomes, new Comparator<Genome>() {
        public int compare(Genome o1, Genome o2){
          double cmp = o2.fitness - o1.fitness;
          return cmp == 0.0 ? 0 : cmp > 0 ? 1 : -1;
        }
      });
      
      double remaining = Math.ceil(species.genomes.size() - 1);
      if(cutToOne == true){
        remaining = 1;
      }
      
      while(species.genomes.size() > remaining) {
        species.genomes.remove(species.genomes.size() - 1);
      }
    }
  }
 
  public void initializePool() {
    for(int i = 0; i < instance.population; i++) {
      Genome newGenome = new Genome();
      newGenome.maxNeuron = instance.inputs;
      newGenome.mutate();
      addToSpecies(newGenome);
    }
  }
  
  public void rankGlobally() {
    List<Genome> global = new ArrayList<Genome>();
    for(Species species : instance.species) {
      for(Genome genome : species.genomes) {
        global.add(genome);
      }
    }
    
    Collections.sort(global, new Comparator<Genome>() {
        public int compare(Genome o1, Genome o2){
          double cmp = o2.fitness - o1.fitness;
          return cmp == 0.0 ? 0 : cmp > 0 ? 1 : -1;
        }
    });
    
    for(int i = 0; i < global.size(); i++) {
      global.get(i).globalRank = i;
    }
  }
  
  public void removeStaleSpecies() {
    List<Species> survived = new ArrayList<Species>();
    for(Species species : instance.species){
        
      Collections.sort(species.genomes, new Comparator<Genome>() {
          public int compare(Genome o1, Genome o2){
            double cmp = o2.fitness - o1.fitness;
            return cmp == 0.0 ? 0 : cmp > 0 ? 1 : -1;
          }
      });
      
      if(species.genomes.get(0).fitness > species.topFitness) {
        species.topFitness = species.genomes.get(0).fitness;
        species.staleness = 0;
      } else {
        species.staleness++;
      }
      
      if(species.staleness < instance.staleSpecies ||
         species.topFitness >= maxFitness) {
        survived.add(species);
      }      
    }
    
    species.clear();
    species.addAll(survived);
  }
  
  public double totalAverageFitness() {
    double total = 0; 
    for(Species species : instance.species) {
      total += species.averageFitness;
    }
    return total;
  }
  
  public void removeWeakSpecies() {
    List<Species> survived = new ArrayList<Species>();
    double sum = totalAverageFitness();
    for(Species species : instance.species) {
      double breed = Math.floor(species.averageFitness / sum * instance.population);
      if(breed >= 1) {
        survived.add(species);
      }
    }
    
    species.clear();
    species.addAll(survived);
    
  }
  
  public void newGeneration() {
    cullSpecies(false);
    rankGlobally();
    removeStaleSpecies();
    rankGlobally();
    
    for(Species species : instance.species) {
      species.calculateAverageFitness();
    }
    
    removeWeakSpecies();
    
    double sum = totalAverageFitness();
    List<Genome> children = new ArrayList<Genome>();
    for(Species species : instance.species) {
      double breed = Math.floor(species.averageFitness / sum * instance.population) - 1;
      for(int i = 0; i < breed; i++) {
        children.add(species.breedChild());
      }
    }
    
    for(Genome child : children) {
      addToSpecies(child);
    }
    generation++;
  }
  
  
  
}