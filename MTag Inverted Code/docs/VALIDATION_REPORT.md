# Validation record

Independent Python/SciPy regression test using the distributed synthetic CSV inputs and the source-equivalent dipole equation:

- Position estimation error (metres): `1.430e-17`
- Squared residual norm: `7.200e-35`
- Synthetic geometry and observations contain no original sensor geometry or raw observations.
- Static MATLAB interface review performed; no MATLAB/Octave runtime was available here. **MATLAB smoke test remains required before paper submission.**
- The legacy zero-mask behavior and historical skip threshold have been intentionally separated into explicit options.

This check is not a cross-runtime test of MATLAB `lsqnonlin` and is not evidence of experimental reproducibility.
