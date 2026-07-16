# Molecular Dynamics Simulation of Liquid Water

This directory contains a short molecular dynamics workflow for a periodic box of liquid water simulated with GROMACS.

## System and simulation setup

- **216 SPC water molecules**
- **648 atoms**
- **OPLS-AA force field with the SPC water model**
- Periodic cubic simulation box
- **Temperature:** 298.15 K
- **Pressure:** 1 bar
- **Time step:** 2 fs
- **Number of steps:** 100,000
- **Total simulation time:** 200 ps
- **Thermostat:** Nose–Hoover
- **Barostat:** Parrinello–Rahman
- **Electrostatics:** Particle Mesh Ewald
- **Bond constraints:** LINCS for bonds involving hydrogen

## Short workflow

1. The input structure, topology and MD parameters were prepared in `conf.gro`, `topol.top` and `grompp.mdp`.
2. The run input file was generated with `gmx grompp`.
3. The 200 ps production simulation was performed with `gmx mdrun`.
4. The trajectory was inspected in VMD.
5. Structural and dynamic properties were calculated with GROMACS:
   - oxygen–oxygen radial distribution function,
   - hydrogen-bond count,
   - mean square displacement,
   - diffusion coefficient,
   - density.
6. GROMACS `.xvg` output files were converted into PNG plots using an R script.

Example execution:

```bash
gmx grompp -f grompp.mdp -c conf.gro -p topol.top -o water.tpr
gmx mdrun -s water.tpr -deffnm water -v
Rscript plot_all_xvg.R
```

## Results

### Density

The average density obtained from the trajectory was:

```text
976.573 ± 0.85 kg/m³
```

The density fluctuated during the simulation but remained close to the expected density range for liquid water, indicating that the system stayed in a stable condensed phase.

![Water density](plots/energy.png)

### Hydrogen bonds

The average number of hydrogen bonds was:

```text
373.569 hydrogen bonds per frame
```

For 216 water molecules, this corresponds to approximately:

```text
3.46 hydrogen-bond connections per molecule
```

The hydrogen-bond count fluctuated around a stable mean and did not show a systematic increase or decrease during the simulation.

![Hydrogen bonds](plots/hbnum.png)

### Mean square displacement and diffusion

The mean square displacement increased approximately linearly with time. This indicates normal diffusive motion of water molecules in the liquid phase.

The diffusion coefficient reported by GROMACS was:

```text
D = 3.5421 × 10⁻⁵ cm²/s
  = 3.5421 × 10⁻⁹ m²/s
```

The fit was performed between 20 and 180 ps.

![Mean square displacement](plots/msd_oxygen.png)

### Oxygen–oxygen radial distribution function

The oxygen–oxygen RDF showed a strong first maximum at approximately:

```text
r ≈ 0.28 nm
g(r) ≈ 2.9
```

This peak represents the first coordination shell of neighboring water molecules and is associated with the local hydrogen-bonded structure of liquid water. At larger distances, `g(r)` gradually approached 1, showing that long-range positional order was lost, as expected for a liquid.

![Oxygen–oxygen RDF](plots/rdf_OO.png)

A separate System–System RDF was also calculated. Its sharp peaks near approximately 0.10 and 0.16 nm mainly arise from intramolecular O–H and H–H distances, so the oxygen–oxygen RDF was used as the main structural result.

## Main conclusions

The simulation preserved a stable liquid-water system over 200 ps. The density remained close to the liquid range, the hydrogen-bond network was maintained, the oxygen–oxygen RDF showed the expected short-range organization, and the nearly linear MSD confirmed diffusive molecular motion.
