# `bfra` - a matlab package for baseflow recession analysis

Baseflow recession analysis refers to a set of methods in hydrologic science designed to infer watershed properties that cannot be observed from something that can be observed - streamflow. The underlying theory is based on idealized solutions to the one-dimensional (lateral) groundwater flow equation ("Boussinesq equation"). Its application is meant for shallow unconfined riparian aquifers, those that discharge subsurface flow into adjacent stream channels. The theory makes various strong assumptions, including that the aquifer extent is much larger in the lateral direction than the vertical, and that capillarity can be more or less ignored. This reduces the three-dimensional Richard's equation to one dimension and eliminates unsaturated flow considerations. The theory has been validated with laboratory experiments and may work better than you expect. When applied to entire catchments ("watersheds"), the theory becomes an effective one, meaning the inferred properties are those that give the same solution to the Boussinesq equation that one would obtain for a single hillslope with those same properties and geometric similarity.

## Install

Run `Setup.m` (type `Setup` at the command line then press enter). If running in Octave, check `.octaverc`.

## Usage

See examples in the `examples/` directory.

Type `help +bfra` at the command line then press enter to see a list of the `bfra` package contents. Also see `Contents.m`.

## Reference

forthcoming