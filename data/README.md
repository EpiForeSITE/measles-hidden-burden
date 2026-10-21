# Contact matrix data

Run `make data` from the repository root: [`utaz_data.R`](./utaz_data.R) builds the population, POLYMOD contact matrix, and vaccination data (see the main [README](../README.md#data)), and `epistorm_matrix.R` then builds the Epistorm-Mix matrix.

The Epistorm data was downloaded from this link: "https://raw.githubusercontent.com/epistorm/Epistorm-Mix/05966ba49c7b49fb1cd902d6b98b3be0bb2785a8/matrices/M_matrix/Total-M-by5_80-matrix.csv"

[`epistorm_matrix.R`](./epistorm_matrix.R) builds the Epistorm-Mix contact matrix for the model's 15 groups with the same method used for the POLYMOD matrix in the `measles` package (`multigroup.vaccine::contactMatrixAgeSchool()`):

1. **Single years of age.** The 5-year Epistorm matrix is expanded to single years of age (each 5-year column is divided evenly among its ages).
2. **Model age groups.** The matrix is collapsed to the 9 model age groups (under 1, 1–4, 5–11, 12–13, 14–17, 18–24, 25–44, 45–69, 70+): for each pair of groups, the contacts are summed over the column ages and averaged over the row ages. For example, a group spanning ages 6–11 covers 4 ages of the (5–9) interval and 2 of the (10–14) interval; if their contact rates are $X$ and $Y$, the group's rate is:

   ```math
   \frac{4X + 2Y}{6}
   ```

3. **Reciprocity.** The age matrix is made reciprocal for the study population (2024 Census age counts for Hildale UT, Colorado City AZ and Centennial Park AZ, read from `utaz_population.rds`, created by [`utaz_data.R`](./utaz_data.R)) with `measles::make_cmat_symmetric()`, so that the total contacts from group *i* to group *j* equal those from *j* to *i*.
4. **Schools.** Each school-age group (5–11, 12–13 and 14–17) is split into its three schools (`contactMatrixAgeSchool2()`, adapted from `multigroup.vaccine::contactMatrixAgeSchool()`):
   - contacts of other groups with a school-age group are divided among its schools in proportion to their enrollment, rescaled to the census age counts;
   - within an age group, 70% of contacts are with the agent's own school (`schportion = 0.7`), and the rest are spread across the schools of that age group in proportion to their size.

The script checks that the result is reciprocal and has the same groups and population as the POLYMOD matrix, and saves it to `utaz_contacts_epistorm.rds`.

## References

Litvinova, M., Sinclair, S., Kummer, A. G., Ventura, P. C., Foster, T., Shioda, K., Halloran, M. E., Vespignani, A., & Ajelli, M. (2025). *Epistorm-Mix: Mapping Social Contact Patterns for Respiratory Pathogen Spread in the Post-Pandemic United States* (p. 2025.11.20.25340662). medRxiv. <https://doi.org/10.1101/2025.11.20.25340662>
