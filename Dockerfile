FROM registry.gitlab.com/ase/ase:ase-abinit AS abinit
FROM registry.gitlab.com/ase/ase:ase-dftbplus AS dftbplus
FROM registry.gitlab.com/ase/ase:ase-dftd3 AS dftd3
FROM registry.gitlab.com/ase/ase:ase-espresso AS espresso
FROM registry.gitlab.com/ase/ase:ase-exciting AS exciting
FROM registry.gitlab.com/ase/ase:ase-kim AS kim
FROM registry.gitlab.com/ase/ase:ase-lammps AS lammps
FROM registry.gitlab.com/ase/ase:ase-mopac AS mopac
FROM registry.gitlab.com/ase/ase:ase-nwchem AS nwchem
FROM registry.gitlab.com/ase/ase:ase-octopus AS octopus
FROM registry.gitlab.com/ase/ase:ase-plumed AS plumed
FROM registry.gitlab.com/ase/ase:ase-psi4 AS psi4
FROM registry.gitlab.com/ase/ase:ase-siesta AS siesta

FROM registry.gitlab.com/ase/ase:ase-main

RUN pip install git+https://gitlab.com/ase/ase-datafiles.git

# Directory where individual calculator installs are placed
# Note: in ENV commands, $HOME is /
ENV CALC=/home/ase/calculators

COPY --from=dftbplus /home/ase/calculators/dftbplus/bin/dftb+/ $CALC/dftbplus/bin/
# XXX Move somewhere higher?
#COPY --from=octopus /octopus ./octopus

# Install KIM API and kimpy (required for KIM calculator)
COPY --from=kim /home/ase/calculators/kim/ $CALC/kim/
COPY --from=nwchem /home/ase/calculators/nwchem $CALC/nwchem

# Install psi4
COPY --from=psi4 /home/ase/build/psi4-1.3.2 $CALC/psi4

COPY --from=espresso /home/ase/calculators/espresso $CALC/espresso

COPY --from=abinit /home/ase/calculators/abinit/ $CALC/abinit
COPY --from=dftd3 /home/ase/calculators/dftd3 $CALC/dftd3

COPY --from=plumed /home/ase/calculators/plumed $CALC/plumed
COPY --from=plumed /home/ase/build/plumed-*.tar.gz $CALC/plumed/
RUN pip install --no-deps $CALC/plumed/plumed-*.tar.gz

# Install LAMMPS and set python search path so ase can find
# lammps.py (and lammps.py can find liblammps.so)
COPY --from=lammps /home/ase/calculators/lammps/ $CALC/lammps/
ENV PYTHONPATH=${PYTHONPATH}:$CALC/lammps/python/
ENV LD_LIBRARY_PATH=$CALC/lammps/lib

COPY --from=exciting /home/ase/build/exciting/build/serial/exciting $CALC/exciting/bin/
COPY --from=exciting /home/ase/build/exciting/species $CALC/exciting/species

COPY --from=octopus /home/ase/calculators/octopus/ $CALC/octopus
COPY --from=siesta /home/ase/calculators/siesta $CALC/siesta

COPY --from=mopac /home/ase/calculators/mopac $CALC/mopac
ENV LD_LIBRARY_PATH=$CALC/mopac/lib:${LD_LIBRARY_PATH}

COPY ase.conf $HOME/ase.conf
ENV ASE_CONFIG $HOME/ase.conf

# XXX We should try to do this via configfile or something similar
ENV EXCITINGROOT $CALC/exciting

ENV PYTHONPATH $CALC/psi4/lib:$PYTHONPATH

# GPAW (unwisely) tries to guess MPI at runtime and links it with
# ctypes.  It would be better to remember MPI at compile time if that's
# possible. This could cause other codes to crash if the linked MPI is
# any different from someone else's MPI. We work around this problem by
# pointing it to a file which does not exist:
ENV GPAW_MPI /tmp/does_not_exist
# This may not have any effect since there's actually only one MPI
# on this docker now.

RUN pip install --no-deps $CALC/kim/kimpy-*.whl
ENV PLUMED_KERNEL=/home/ase/calculators/plumed/lib/libplumedKernel.so
RUN pip install deepdiff

