# Contact matrix data

The Epistorm data was downloaded from this link: "https://raw.githubusercontent.com/epistorm/Epistorm-Mix/05966ba49c7b49fb1cd902d6b98b3be0bb2785a8/matrices/M_matrix/Total-M-by5_80-matrix.csv"

The contact matrix was first adjusted to reflect the age distribution of the study region. Because our model treats individual schools as distinct population blocks, we further modified contact rates for school-age individuals, assuming that 80% of contacts among school-age agents occur within their own school. Overall contact rates were preserved but redistributed to reflect this within-school concentration.

Since the Epistorm contact matrix uses five-year age intervals (0–4, 5–9, 10–14, etc.), we mapped it to our model's age groups using a weighted average. For any model age group spanning multiple Epistorm intervals, the effective contact rate was computed as a weighted average across overlapping intervals, with weights proportional to the number of ages from each interval represented in the model group. For example, a school enrolling students aged 6–11 spans two Epistorm intervals—(5–9) and (10–14)—contributing 4 and 2 ages, respectively. If the total contact rates for those intervals are $X$ and $Y$, the effective contact rate for the 6–11 age group is:

```math
\frac{4X + 2Y}{6}
```

The file [**epistorm_matrix.R**](./epistorm_matrix.R) contains the exact code used to implement this.

## References

Litvinova, M., Sinclair, S., Kummer, A. G., Ventura, P. C., Foster, T., Shioda, K., Halloran, M. E., Vespignani, A., & Ajelli, M. (2025). *Epistorm-Mix: Mapping Social Contact Patterns for Respiratory Pathogen Spread in the Post-Pandemic United States* (p. 2025.11.20.25340662). medRxiv. <https://doi.org/10.1101/2025.11.20.25340662>
