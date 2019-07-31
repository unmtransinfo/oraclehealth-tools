# `CERNER-TOOLS`

Code and scripts for interacting with Cerner Health Facts.

## Dependencies

 * [`unm_biocomp_util`](https://github.com/unmtransinfo/unm_biocomp_util)

## Compiling

```
mvn clean install
```

# Usage

```
mvn --projects unm_biocomp_cerner exec:java -Dexec.mainClass="edu.unm.health.biocomp.cerner.hf.hf_query"
mvn --projects unm_biocomp_cerner exec:java -Dexec.mainClass="edu.unm.health.biocomp.cerner.hf.hf_patients"
```

## Documentation

```
mvn javadoc:javadoc
```

_(Then see `unm_biocomp_cerner/target/site/apidocs/`.)_

## UNM Cerner HealthFacts paper:

*  [Low serum sodium levels at hospital admission: Outcomes among 2.3 million hospitalized patients](https://journals.plos.org/plosone/article/comments?id=10.1371/journal.pone.0194379), Saleem Al Mawed, V. Shane Pankratz, Kelly Chong, Matthew Sandoval, Maria-Eleni Roumelioti, Mark Unruh, Published: March 22, 2018https://doi.org/10.1371/journal.pone.0194379
