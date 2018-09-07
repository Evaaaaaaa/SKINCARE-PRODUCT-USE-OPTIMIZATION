#You will probably need to run "Pkg.add(...)" before using these packages
using DataFrames, CSV, NamedArrays
#Load the data file (ref: Boyd/263)

raw2 = CSV.read("product_ingredients.csv", nullable = false);
# turn DataFrame into an array
pi = convert(Array,raw2)
# the ‘‘names’’ of the DataFrame (header) are the ingredients
igdt= names(raw2[2:end])

# create a NamedArray that specifies how much of each ingredient each product provides
pi_m = pi[1:end,2:end] # rows are products, columns are ingredients
pi_a = NamedArray(pi_m, (prdt, igdt), ("products","ingredients"))

raw3 = CSV.read("ingredient_effects.csv", nullable = false);
#turn DataFrame into an Array
ie = convert(Array, raw3)
# the ‘‘names’’ of the DataFrame (header) are the adverse effects
ad_eff = names(raw3[2:end])

# create a NamedArray that specifies how much of each ad-effects each ingredients provides
ie_m = ie[1:end,2:end] # rows are products, columns are ingredients
ie_a = NamedArray(ie_m, (igdt, ad_eff), ("ingredients","adverse effects"))
