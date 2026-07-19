# Molecular Dynamics Simulation of the Ribonuclease S-Peptide

## Project overview

This project presents a molecular dynamics workflow for the isolated
20-residue ribonuclease S-peptide in explicit water using GROMACS.

The main objective was to investigate whether the peptide retains its
characteristic alpha-helical region in aqueous solution and to analyse its
structural stability, compactness, backbone conformations and electrostatic
contacts.

## Software and methods

The workflow used:

- GROMACS for system preparation, energy minimization, equilibration,
  production molecular dynamics and trajectory analysis,
- VMD for trajectory inspection, secondary-structure analysis and
  salt-bridge analysis,
- R for processing GROMACS XVG files and generating publication-style plots.

## System preparation

The initial S-peptide structure, corresponding to residues 1–20 of
ribonuclease A, was prepared using the AMBER03 force field and the TIP3P
water model.

Hydrogen atoms and the molecular topology were generated with `gmx pdb2gmx`.
The peptide was placed in a periodic simulation box with a nominal minimum
solute-to-box distance of 0.5 nm and solvated with explicit water.

The final system contained:

- 20 amino-acid residues,
- 295 peptide atoms,
- 961 TIP3P water molecules,
- 3178 atoms in total.

The prepared peptide had a total charge of 0.000 e, so neutralizing
counterions were not required. No additional salt was added to the system.

A position-restraint topology was generated automatically during topology
preparation.

## Simulation workflow

1. Extraction and preparation of the 20-residue S-peptide structure.
2. Generation of the AMBER03 topology and TIP3P solvent parameters.
3. Construction of the periodic simulation box.
4. Solvation of the peptide with explicit water.
5. Generation of standard GROMACS index groups.
6. Steepest-descent energy minimization.
7. A 10 ps position-restrained NVT equilibration at 300 K.
8. A 300 ps unrestrained NPT molecular dynamics simulation at 300 K and a
   reference pressure of 1 bar.
9. Correction of periodic boundary conditions and centering of the peptide.
10. Structural and energetic trajectory analysis.

## Energy minimization

Energy minimization was performed using the steepest-descent algorithm with
a maximum-force convergence criterion of 2000 kJ mol⁻¹ nm⁻¹.

The minimization converged after 116 steps.

Final values:

- potential energy: approximately −40,643 kJ/mol,
- maximum force: approximately 1232 kJ mol⁻¹ nm⁻¹.

The maximum force was below the specified convergence threshold, indicating
successful removal of the strongest steric clashes and unfavourable initial
contacts.

## Position-restrained equilibration

A 10 ps position-restrained NVT simulation was performed at 300 K.

During this stage, the peptide heavy atoms were maintained close to their
reference positions, while the water molecules were allowed to reorganize
around the peptide.

The potential energy decreased during the first approximately 2 ps and then
fluctuated around a relatively stable mean value of approximately
−41,200 kJ/mol, suggesting relaxation of the solvated system.

## Production molecular dynamics

The position restraints were removed for the full molecular dynamics stage.

The production simulation was performed under NPT conditions for 300 ps
using:

- a 2 fs integration time step,
- a temperature of 300 K,
- a reference pressure of 1 bar,
- the Berendsen barostat,
- Particle Mesh Ewald electrostatics,
- 1.0 nm electrostatic and van der Waals cutoffs,
- LINCS constraints on bonds involving hydrogen atoms.

## Trajectory analysis

The following analyses were performed:

- potential-energy analysis,
- temperature, pressure, density and volume analysis,
- Cα RMSD,
- radius of gyration,
- Ramachandran analysis,
- secondary-structure analysis using VMD Timeline,
- salt-bridge analysis using VMD Timeline,
- visual inspection of the centred trajectory.

## Results

### Cα RMSD

The Cα RMSD increased during the first part of the simulation, indicating
conformational relaxation relative to the starting structure.

The RMSD reached a maximum of approximately 0.46 nm around 160 ps. During
the final 50 ps, it fluctuated mainly between approximately 0.24 and
0.32 nm, with a final value of approximately 0.31 nm.

The average RMSD over the complete trajectory was approximately:

- RMSD = 0.30 ± 0.09 nm.

These results indicate substantial conformational adjustment followed by
partial stabilization. However, a clear long-term RMSD plateau was not
reached during the 300 ps trajectory.

### Radius of gyration

The radius of gyration remained within a relatively narrow range of
approximately 0.95–1.05 nm.

The average radius of gyration was:

- Rg = 1.00 ± 0.02 nm.

The relatively stable Rg indicates that the peptide remained compact and did
not undergo global unfolding or structural collapse.

The combination of changing RMSD and stable Rg suggests internal
conformational rearrangement rather than large-scale expansion of the
peptide.

### Ramachandran analysis

The Ramachandran plot showed a dominant population in the right-handed
alpha-helical region, centred approximately around φ = −60° and ψ = −40°.

A second population was observed in the extended or beta-like region and
was mainly associated with flexible non-helical residues.

The distribution supports the presence of a stable central alpha-helical
segment together with conformationally flexible terminal regions.

## Thermodynamic stability of the production simulation

The thermodynamic properties of the system were analysed from the
`full.edr` energy file generated during the 300 ps unrestrained NPT
simulation.

### Potential energy

The potential energy fluctuated around an average value of approximately:

- **Potential energy: −41,425 kJ/mol**

No continuous increase or decrease was observed during the trajectory.
Instead, the energy remained distributed around a stable mean value,
indicating that the solvated peptide system did not undergo energetic
instability during the production simulation.

### Temperature

The average temperature was:

- **Temperature: 299.8 K**

This value is very close to the reference temperature of 300 K. The
temperature showed normal short-timescale fluctuations but no systematic
heating or cooling, indicating effective temperature coupling.

### Density

The average system density was:

- **Density: 1025.1 kg/m³**

Density fluctuated around a stable mean value throughout the simulation.
No continuous increase or decrease was observed, suggesting that the
solvated system maintained a stable overall packing density.

### Volume

The average simulation-box volume was:

- **Volume: 31.56 nm³**

The volume exhibited moderate fluctuations expected for an NPT simulation
but remained within a relatively narrow range. No progressive expansion or
collapse of the simulation box was detected.

### Pressure

The frame-averaged pressure was:

- **Pressure: 13.7 bar**

Instantaneous pressure showed large fluctuations, ranging over several
hundred bar in both directions. Such fluctuations are expected for a small
molecular system because pressure is calculated from rapidly changing
microscopic forces.

Although the average pressure was not exactly equal to the reference value
of 1 bar, no systematic pressure drift was observed. The stable density and
volume indicate that the system did not undergo uncontrolled compression or
expansion.

Because the simulation was only 300 ps long, the calculated mean pressure
should be interpreted cautiously.

### Overall thermodynamic assessment

The potential energy, temperature, density and volume remained stable
throughout the production trajectory. Together, these results indicate that
the simulation was numerically stable and that the system maintained the
intended thermodynamic conditions over the analysed timescale.

However, the short simulation duration and large pressure fluctuations mean
that the trajectory should be interpreted as an initial short-timescale
molecular dynamics analysis rather than fully converged thermodynamic
sampling.

### Secondary structure

VMD Timeline analysis showed that the central region of the S-peptide,
approximately residues Ala4–Met13, retained predominantly alpha-helical
character.

The Ala4–Arg10 segment was especially stable. Short and transient
interruptions were observed around Gln11 and His12.

The terminal regions showed greater conformational flexibility and were
mainly assigned as coil or turn structures. No persistent beta-sheet
formation was observed.

### Salt bridges

Electrostatic contacts involving Glu2 were observed throughout the
trajectory.

The Glu2–Arg10 interaction was recurrent but dynamic, with intermittent
breaking and reformation. A persistent Glu2–Lys7 contact was also detected
by the VMD Timeline analysis.

These interactions may contribute to stabilization of the N-terminal and
central helical regions, although quantitative distance and occupancy
analysis would be required for a more rigorous assessment.

## Conclusions

The 300 ps molecular dynamics simulation showed that the isolated
ribonuclease S-peptide remained compact and retained a substantial part of
its central alpha-helical structure in explicit water.

The peptide underwent noticeable conformational relaxation, as indicated by
the Cα RMSD, but did not display global unfolding, as shown by the
relatively stable radius of gyration.

The central helical region was more stable than the terminal residues.
Electrostatic contacts involving Glu2, Lys7 and Arg10 were dynamic and may
contribute to local helix stabilization.

Because the RMSD did not reach a clear long-term plateau, the simulation
should be interpreted as an initial short-timescale exploration rather than
a fully converged conformational study.

## Limitations and future improvements

This workflow follows the original tutorial setup and therefore retains a
short 300 ps production simulation, the Berendsen barostat and a 0.5 nm
solute-to-box distance. These settings are sufficient for demonstrating the
basic GROMACS workflow, but they limit the physical interpretation of the
results.

Future improvements could include:

1. **Extending the production simulation beyond 300 ps**

   A longer simulation on the nanosecond timescale would provide more complete
   conformational sampling of the S-peptide. It would allow slower processes,
   such as helix–coil transitions, terminal rearrangements and repeated
   breaking and reformation of salt bridges, to be observed.

   The current 300 ps trajectory mainly describes early structural relaxation
   and is too short to demonstrate full RMSD convergence or equilibrium
   conformational behaviour.

2. **Performing multiple independent simulation replicas**

   Several simulations with different initial velocity seeds would help
   determine whether the observed RMSD changes, secondary-structure stability
   and salt-bridge behaviour are reproducible or depend on one particular
   starting trajectory.

3. **Increasing the duration of the equilibration stages**

   Longer NVT and NPT equilibration stages would allow the solvent,
   temperature, density and simulation-box dimensions to stabilize more fully
   before the production trajectory begins.

   This would reduce the contribution of initial relaxation to the production
   results and provide a more clearly equilibrated starting structure.

4. **Using a production-quality pressure-coupling method**

   The Berendsen barostat efficiently drives the system towards the target
   pressure and was retained to reproduce the tutorial workflow. However, it
   suppresses the natural pressure and volume fluctuations of the NPT ensemble.

   A future workflow could use the Berendsen barostat only during equilibration
   and then switch to a barostat such as Parrinello–Rahman or C-rescale for the
   production simulation. This would provide more physically meaningful
   pressure and volume fluctuations and improve NPT ensemble sampling.

5. **Increasing the solvent buffer around the peptide**

   The current system was prepared with a nominal minimum peptide-to-box
   distance of 0.5 nm. Increasing this distance to approximately 1.0 nm would
   place more solvent between the peptide and its periodic images.

   A larger solvent buffer would reduce the risk of artificial interactions
   between the peptide and its own periodic copies, especially when the
   elongated peptide rotates or changes conformation during the simulation.

   This modification would require rebuilding the box, resolvating the system
   and repeating all minimization, equilibration and production steps.

6. **Checking peptide separation from periodic images**

   The minimum distance between the peptide and its periodic copies should be
   monitored throughout the trajectory. This would verify whether the 0.5 nm
   initial buffer remained sufficient after peptide rotation and structural
   rearrangement.

7. **Quantifying salt-bridge stability**

   The VMD Timeline analysis provides a qualitative view of salt-bridge
   formation. A more rigorous analysis should calculate:

   - interatomic distances over time,
   - the percentage of frames in which each salt bridge is present,
   - average and minimum contact distances,
   - breaking and reformation events.

   This would allow the Glu2–Arg10 and Glu2–Lys7 interactions to be described
   quantitatively rather than only visually.

8. **Including an explicit salt concentration**

   The prepared peptide had a total charge of 0.000 e, so neutralizing
   counterions were not required. However, no additional salt was included
   in the current system.

   Adding a defined ionic strength, for example using an appropriate NaCl
   concentration, could provide a more realistic aqueous environment.
   The presence of ions could also influence electrostatic interactions,
   including the stability and occupancy of the Glu2–Arg10 and Glu2–Lys7
   contacts.

9. **Comparing force fields and water models**

   The current simulation uses AMBER03 with TIP3P water. Repeating the
   simulation with other modern protein force fields or water models would
   help determine how strongly the observed alpha-helical stability depends on
   the selected parameter set.

10. **Validating secondary-structure populations over longer trajectories**

    The present trajectory indicates that the central alpha-helical region is
    largely preserved, but 300 ps is insufficient to estimate reliable
    secondary-structure populations.

    Longer and replicated simulations would allow the percentage of alpha-helix,
    coil, turn and extended conformations to be calculated with greater
    confidence.

Overall, the current simulation should be interpreted as a short,
tutorial-based demonstration of peptide preparation, equilibration, molecular
dynamics and trajectory analysis. The proposed changes would improve
conformational sampling, reduce periodic-boundary artefacts and provide more
physically reliable thermodynamic and structural conclusions.
