// GENERATED FILE — do not edit by hand.
// Regenerate with: python3 tool/generate_utci_polynomial.py

/// Bröde et al. (2012) 6th-order UTCI polynomial approximation.
///
/// Inputs:
/// - [tdb] air temperature °C
/// - [v] wind speed at 10 m m/s
/// - [deltaTtr] mean radiant temperature minus air temperature K
/// - [pa] water vapour pressure kPa
double utciPolynomial(
  double tdb,
  double v,
  double deltaTtr,
  double pa,
) {
    return (
        tdb
        + 0.607562052
        + (-0.0227712343) * tdb
        + 8.06470249e-4 * tdb * tdb
        - 1.54271372e-4 * tdb * tdb * tdb
        - 3.24651735e-6 * tdb * tdb * tdb * tdb
        + 7.32602852e-8 * tdb * tdb * tdb * tdb * tdb
        + 1.35959073e-9 * tdb * tdb * tdb * tdb * tdb * tdb
        + (-2.25836520) * v
        + 0.0880326035 * tdb * v
        + 0.00216844454 * tdb * tdb * v
        - 1.53347087e-5 * tdb * tdb * tdb * v
        - 5.72983704e-7 * tdb * tdb * tdb * tdb * v
        - 2.55090145e-9 * tdb * tdb * tdb * tdb * tdb * v
        + (-0.751269505) * v * v
        + (-0.00408350271) * tdb * v * v
        - 5.21670675e-5 * tdb * tdb * v * v
        + 1.94544667e-6 * tdb * tdb * tdb * v * v
        + 1.14099531e-8 * tdb * tdb * tdb * tdb * v * v
        + 0.158137256 * v * v * v
        - 6.57263143e-5 * tdb * v * v * v
        + 2.22697524e-7 * tdb * tdb * v * v * v
        - 4.16117031e-8 * tdb * tdb * tdb * v * v * v
        + (-0.0127762753) * v * v * v * v
        + 9.66891875e-6 * tdb * v * v * v * v
        + 2.52785852e-9 * tdb * tdb * v * v * v * v
        + 4.56306672e-4 * v * v * v * v * v
        - 1.74202546e-7 * tdb * v * v * v * v * v
        - 5.91491269e-6 * v * v * v * v * v * v
        + 0.398374029 * deltaTtr
        + 1.83945314e-4 * tdb * deltaTtr
        - 1.73754510e-4 * tdb * tdb * deltaTtr
        - 7.60781159e-7 * tdb * tdb * tdb * deltaTtr
        + 3.77830287e-8 * tdb * tdb * tdb * tdb * deltaTtr
        + 5.43079673e-10 * tdb * tdb * tdb * tdb * tdb * deltaTtr
        + (-0.0200518269) * v * deltaTtr
        + 8.92859837e-4 * tdb * v * deltaTtr
        + 3.45433048e-6 * tdb * tdb * v * deltaTtr
        - 3.77925774e-7 * tdb * tdb * tdb * v * deltaTtr
        - 1.69699377e-9 * tdb * tdb * tdb * tdb * v * deltaTtr
        + 1.69992415e-4 * v * v * deltaTtr
        - 4.99204314e-5 * tdb * v * v * deltaTtr
        + 2.47417178e-7 * tdb * tdb * v * v * deltaTtr
        + 1.07596466e-8 * tdb * tdb * tdb * v * v * deltaTtr
        + 8.49242932e-5 * v * v * v * deltaTtr
        + 1.35191328e-6 * tdb * v * v * v * deltaTtr
        - 6.21531254e-9 * tdb * tdb * v * v * v * deltaTtr
        - 4.99410301e-6 * v * v * v * v * deltaTtr
        - 1.89489258e-8 * tdb * v * v * v * v * deltaTtr
        + 8.15300114e-8 * v * v * v * v * v * deltaTtr
        + 7.55043090e-4 * deltaTtr * deltaTtr
        - 5.65095215e-5 * tdb * deltaTtr * deltaTtr
        - 4.52166564e-7 * tdb * tdb * deltaTtr * deltaTtr
        + 2.46688878e-8 * tdb * tdb * tdb * deltaTtr * deltaTtr
        + 2.42674348e-10 * tdb * tdb * tdb * tdb * deltaTtr * deltaTtr
        + 1.54547250e-4 * v * deltaTtr * deltaTtr
        + 5.24110970e-6 * tdb * v * deltaTtr * deltaTtr
        - 8.75874982e-8 * tdb * tdb * v * deltaTtr * deltaTtr
        - 1.50743064e-9 * tdb * tdb * tdb * v * deltaTtr * deltaTtr
        - 1.56236307e-5 * v * v * deltaTtr * deltaTtr
        - 1.33895614e-7 * tdb * v * v * deltaTtr * deltaTtr
        + 2.49709824e-9 * tdb * tdb * v * v * deltaTtr * deltaTtr
        + 6.51711721e-7 * v * v * v * deltaTtr * deltaTtr
        + 1.94960053e-9 * tdb * v * v * v * deltaTtr * deltaTtr
        - 1.00361113e-8 * v * v * v * v * deltaTtr * deltaTtr
        - 1.21206673e-5 * deltaTtr * deltaTtr * deltaTtr
        - 2.18203660e-7 * tdb * deltaTtr * deltaTtr * deltaTtr
        + 7.51269482e-9 * tdb * tdb * deltaTtr * deltaTtr * deltaTtr
        + 9.79063848e-11
        * tdb
        * tdb
        * tdb
        * deltaTtr
        * deltaTtr
        * deltaTtr
        + 1.25006734e-6 * v * deltaTtr * deltaTtr * deltaTtr
        - 1.81584736e-9 * tdb * v * deltaTtr * deltaTtr * deltaTtr
        - 3.52197671e-10
        * tdb
        * tdb
        * v
        * deltaTtr
        * deltaTtr
        * deltaTtr
        - 3.36514630e-8 * v * v * deltaTtr * deltaTtr * deltaTtr
        + 1.35908359e-10
        * tdb
        * v
        * v
        * deltaTtr
        * deltaTtr
        * deltaTtr
        + 4.17032620e-10
        * v
        * v
        * v
        * deltaTtr
        * deltaTtr
        * deltaTtr
        - 1.30369025e-9
        * deltaTtr
        * deltaTtr
        * deltaTtr
        * deltaTtr
        + 4.13908461e-10
        * tdb
        * deltaTtr
        * deltaTtr
        * deltaTtr
        * deltaTtr
        + 9.22652254e-12
        * tdb
        * tdb
        * deltaTtr
        * deltaTtr
        * deltaTtr
        * deltaTtr
        - 5.08220384e-9
        * v
        * deltaTtr
        * deltaTtr
        * deltaTtr
        * deltaTtr
        - 2.24730961e-11
        * tdb
        * v
        * deltaTtr
        * deltaTtr
        * deltaTtr
        * deltaTtr
        + 1.17139133e-10
        * v
        * v
        * deltaTtr
        * deltaTtr
        * deltaTtr
        * deltaTtr
        + 6.62154879e-10
        * deltaTtr
        * deltaTtr
        * deltaTtr
        * deltaTtr
        * deltaTtr
        + 4.03863260e-13
        * tdb
        * deltaTtr
        * deltaTtr
        * deltaTtr
        * deltaTtr
        * deltaTtr
        + 1.95087203e-12
        * v
        * deltaTtr
        * deltaTtr
        * deltaTtr
        * deltaTtr
        * deltaTtr
        - 4.73602469e-12
        * deltaTtr
        * deltaTtr
        * deltaTtr
        * deltaTtr
        * deltaTtr
        * deltaTtr
        + 5.12733497 * pa
        + (-0.312788561) * tdb * pa
        + (-0.0196701861) * tdb * tdb * pa
        + 9.99690870e-4 * tdb * tdb * tdb * pa
        + 9.51738512e-6 * tdb * tdb * tdb * tdb * pa
        - 4.66426341e-7 * tdb * tdb * tdb * tdb * tdb * pa
        + 0.548050612 * v * pa
        + (-0.00330552823) * tdb * v * pa
        + (-0.00164119440) * tdb * tdb * v * pa
        - 5.16670694e-6 * tdb * tdb * tdb * v * pa
        + 9.52692432e-7 * tdb * tdb * tdb * tdb * v * pa
        + (-0.0429223622) * v * v * pa
        + 0.00500845667 * tdb * v * v * pa
        + 1.00601257e-6 * tdb * tdb * v * v * pa
        - 1.81748644e-6 * tdb * tdb * tdb * v * v * pa
        - 1.25813502e-3 * v * v * v * pa
        - 1.79330391e-4 * tdb * v * v * v * pa
        + 2.34994441e-6 * tdb * tdb * v * v * v * pa
        + 1.29735808e-4 * v * v * v * v * pa
        + 1.29064870e-6 * tdb * v * v * v * v * pa
        - 2.28558686e-6 * v * v * v * v * v * pa
        + (-0.0369476348) * deltaTtr * pa
        + 0.00162325322 * tdb * deltaTtr * pa
        - 3.14279680e-5 * tdb * tdb * deltaTtr * pa
        + 2.59835559e-6 * tdb * tdb * tdb * deltaTtr * pa
        - 4.77136523e-8 * tdb * tdb * tdb * tdb * deltaTtr * pa
        + 8.64203390e-3 * v * deltaTtr * pa
        - 6.87405181e-4 * tdb * v * deltaTtr * pa
        - 9.13863872e-6 * tdb * tdb * v * deltaTtr * pa
        + 5.15916806e-7 * tdb * tdb * tdb * v * deltaTtr * pa
        - 3.59217476e-5 * v * v * deltaTtr * pa
        + 3.28696511e-5 * tdb * v * v * deltaTtr * pa
        - 7.10542454e-7 * tdb * tdb * v * v * deltaTtr * pa
        - 1.24382300e-5 * v * v * v * deltaTtr * pa
        - 7.38584400e-9 * tdb * v * v * v * deltaTtr * pa
        + 2.20609296e-7 * v * v * v * v * deltaTtr * pa
        - 7.32469180e-4 * deltaTtr * deltaTtr * pa
        - 1.87381964e-5 * tdb * deltaTtr * deltaTtr * pa
        + 4.80925239e-6 * tdb * tdb * deltaTtr * deltaTtr * pa
        - 8.75492040e-8 * tdb * tdb * tdb * deltaTtr * deltaTtr * pa
        + 2.77862930e-5 * v * deltaTtr * deltaTtr * pa
        - 5.06004592e-6 * tdb * v * deltaTtr * deltaTtr * pa
        + 1.14325367e-7 * tdb * tdb * v * deltaTtr * deltaTtr * pa
        + 2.53016723e-6 * v * v * deltaTtr * deltaTtr * pa
        - 1.72857035e-8 * tdb * v * v * deltaTtr * deltaTtr * pa
        - 3.95079398e-8 * v * v * v * deltaTtr * deltaTtr * pa
        - 3.59413173e-7 * deltaTtr * deltaTtr * deltaTtr * pa
        + 7.04388046e-7 * tdb * deltaTtr * deltaTtr * deltaTtr * pa
        - 1.89309167e-8
        * tdb
        * tdb
        * deltaTtr
        * deltaTtr
        * deltaTtr
        * pa
        - 4.79768731e-7 * v * deltaTtr * deltaTtr * deltaTtr * pa
        + 7.96079978e-9
        * tdb
        * v
        * deltaTtr
        * deltaTtr
        * deltaTtr
        * pa
        + 1.62897058e-9
        * v
        * v
        * deltaTtr
        * deltaTtr
        * deltaTtr
        * pa
        + 3.94367674e-8
        * deltaTtr
        * deltaTtr
        * deltaTtr
        * deltaTtr
        * pa
        - 1.18566247e-9
        * tdb
        * deltaTtr
        * deltaTtr
        * deltaTtr
        * deltaTtr
        * pa
        + 3.34678041e-10
        * v
        * deltaTtr
        * deltaTtr
        * deltaTtr
        * deltaTtr
        * pa
        - 1.15606447e-10
        * deltaTtr
        * deltaTtr
        * deltaTtr
        * deltaTtr
        * deltaTtr
        * pa
        + (-2.80626406) * pa * pa
        + 0.548712484 * tdb * pa * pa
        + (-0.00399428410) * tdb * tdb * pa * pa
        - 9.54009191e-4 * tdb * tdb * tdb * pa * pa
        + 1.93090978e-5 * tdb * tdb * tdb * tdb * pa * pa
        + (-0.308806365) * v * pa * pa
        + 0.0116952364 * tdb * v * pa * pa
        + 4.95271903e-4 * tdb * tdb * v * pa * pa
        - 1.90710882e-5 * tdb * tdb * tdb * v * pa * pa
        + 0.00210787756 * v * v * pa * pa
        - 6.98445738e-4 * tdb * v * v * pa * pa
        + 2.30109073e-5 * tdb * tdb * v * v * pa * pa
        + 4.17856590e-4 * v * v * v * pa * pa
        - 1.27043871e-5 * tdb * v * v * v * pa * pa
        - 3.04620472e-6 * v * v * v * v * pa * pa
        + 0.0514507424 * deltaTtr * pa * pa
        + (-0.00432510997) * tdb * deltaTtr * pa * pa
        + 8.99281156e-5 * tdb * tdb * deltaTtr * pa * pa
        - 7.14663943e-7 * tdb * tdb * tdb * deltaTtr * pa * pa
        - 2.66016305e-4 * v * deltaTtr * pa * pa
        + 2.63789586e-4 * tdb * v * deltaTtr * pa * pa
        - 7.01199003e-6 * tdb * tdb * v * deltaTtr * pa * pa
        - 1.06823306e-4 * v * v * deltaTtr * pa * pa
        + 3.61341136e-6 * tdb * v * v * deltaTtr * pa * pa
        + 2.29748967e-7 * v * v * v * deltaTtr * pa * pa
        + 3.04788893e-4 * deltaTtr * deltaTtr * pa * pa
        - 6.42070836e-5 * tdb * deltaTtr * deltaTtr * pa * pa
        + 1.16257971e-6 * tdb * tdb * deltaTtr * deltaTtr * pa * pa
        + 7.68023384e-6 * v * deltaTtr * deltaTtr * pa * pa
        - 5.47446896e-7 * tdb * v * deltaTtr * deltaTtr * pa * pa
        - 3.59937910e-8 * v * v * deltaTtr * deltaTtr * pa * pa
        - 4.36497725e-6 * deltaTtr * deltaTtr * deltaTtr * pa * pa
        + 1.68737969e-7
        * tdb
        * deltaTtr
        * deltaTtr
        * deltaTtr
        * pa
        * pa
        + 2.67489271e-8
        * v
        * deltaTtr
        * deltaTtr
        * deltaTtr
        * pa
        * pa
        + 3.23926897e-9
        * deltaTtr
        * deltaTtr
        * deltaTtr
        * deltaTtr
        * pa
        * pa
        + (-0.0353874123) * pa * pa * pa
        + (-0.221201190) * tdb * pa * pa * pa
        + 0.0155126038 * tdb * tdb * pa * pa * pa
        - 2.63917279e-4 * tdb * tdb * tdb * pa * pa * pa
        + 0.0453433455 * v * pa * pa * pa
        + (-0.00432943862) * tdb * v * pa * pa * pa
        + 1.45389826e-4 * tdb * tdb * v * pa * pa * pa
        + 2.17508610e-4 * v * v * pa * pa * pa
        - 6.66724702e-5 * tdb * v * v * pa * pa * pa
        + 3.33217140e-5 * v * v * v * pa * pa * pa
        + (-0.00226921615) * deltaTtr * pa * pa * pa
        + 3.80261982e-4 * tdb * deltaTtr * pa * pa * pa
        - 5.45314314e-9 * tdb * tdb * deltaTtr * pa * pa * pa
        - 7.96355448e-4 * v * deltaTtr * pa * pa * pa
        + 2.53458034e-5 * tdb * v * deltaTtr * pa * pa * pa
        - 6.31223658e-6 * v * v * deltaTtr * pa * pa * pa
        + 3.02122035e-4 * deltaTtr * deltaTtr * pa * pa * pa
        - 4.77403547e-6 * tdb * deltaTtr * deltaTtr * pa * pa * pa
        + 1.73825715e-6 * v * deltaTtr * deltaTtr * pa * pa * pa
        - 4.09087898e-7
        * deltaTtr
        * deltaTtr
        * deltaTtr
        * pa
        * pa
        * pa
        + 0.614155345 * pa * pa * pa * pa
        + (-0.0616755931) * tdb * pa * pa * pa * pa
        + 0.00133374846 * tdb * tdb * pa * pa * pa * pa
        + 0.00355375387 * v * pa * pa * pa * pa
        - 5.13027851e-4 * tdb * v * pa * pa * pa * pa
        + 1.02449757e-4 * v * v * pa * pa * pa * pa
        + (-0.00148526421) * deltaTtr * pa * pa * pa * pa
        - 4.11469183e-5 * tdb * deltaTtr * pa * pa * pa * pa
        - 6.80434415e-6 * v * deltaTtr * pa * pa * pa * pa
        - 9.77675906e-6 * deltaTtr * deltaTtr * pa * pa * pa * pa
        + 0.0882773108 * pa * pa * pa * pa * pa
        + (-0.00301859306) * tdb * pa * pa * pa * pa * pa
        + 0.00104452989 * v * pa * pa * pa * pa * pa
        + 2.47090539e-4 * deltaTtr * pa * pa * pa * pa * pa
        + 0.00148348065 * pa * pa * pa * pa * pa * pa
    );
}
