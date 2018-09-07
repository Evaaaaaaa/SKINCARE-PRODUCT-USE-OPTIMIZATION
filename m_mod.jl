#You will probably need to run "Pkg.add(...)" before using these packages
using DataFrames, CSV, NamedArrays
#Load data file
raw = CSV.read("product_effects.csv", nullable = false);
# turn DataFrame into an array
pe = convert(Array,raw);
# the ‘‘names’’ of the DataFrame (header) are the effects
eff= names(raw[2:end-1]);
# create a list of product from pe
prdt = pe[1:end,1];

#create a list of price of each product_effects
p = pe[1:end,end]
price = Dict(zip(prdt,p))

demand= [25,12,48,24,7,4]
# create a dictionary of the min demand of each effects
dmd = Dict(zip(eff, demand))

# create a NamedArray that specifies how much of each nutrient each food provides
using NamedArrays
pe_m = pe[1:end,2:end-1] # rows are products, columns are effects
pe_a = NamedArray(pe_m, (prdt, eff), ("products","effects"))

using JuMP,  Clp
m1 = Model(solver=ClpSolver()) # create model named m

#recipe
@variable(m1, x[prdt] >= 0)
@constraint(m1, constr[i in eff], sum(pe_a[t, i] * x[t] for t in prdt) >= dmd[i])
@objective(m1, Min, sum(x[i]*price[i] for i in prdt))

status = solve(m1)

for i in prdt
    if getvalue(x[i]) != 0
      println("The amount of ", i, " is: ", getvalue(x[i]))# print result
    end
end
println("The amount of all other products are 0 \nThe total cost will be \$", getobjectivevalue(m1))

#model2
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
