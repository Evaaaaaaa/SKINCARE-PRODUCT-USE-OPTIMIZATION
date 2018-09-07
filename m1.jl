#You will probably need to run "Pkg.add(...)" before using these packages
using DataFrames, CSV, NamedArrays
#Load the data file (ref: Boyd/263)

#model1
raw1 = CSV.read("product_effects.csv", nullable = false);
# turn DataFrame into an array
pe = convert(Array,raw);
# the ‘‘names’’ of the DataFrame (header) are the effects
eff= names(raw[2:end-1]);
# create a list of product from pe
prdt = pe[1:end,1];

#create a list of price of each product_effects
p = pe[1:end,end]
price = Dict(zip(prdt,p))

requirement= [25,12,48,24,7,4]
# create a dictionary of the min demand of each effects
c = Dict(zip(eff, demand))

# create a NamedArray that specifies how much of each nutrient each food provides
using NamedArrays
prdt_eff = pe[1:end,2:end-1] # rows are products, columns are effects
r = NamedArray(prdt_eff, (prdt, eff), ("products","effects"))

using JuMP,  Clp
m1 = Model(solver=ClpSolver()) # create model named m

#recipe
@variable(m1, x[prdt] >= 0)
@constraint(m1, constr[i in eff], sum(r[t, i] * x[t] for t in prdt) >= c[i])
@objective(m1, Min, sum(x[i]*price[i] for i in prdt))

status = solve(m1)
#println(getvalue(recipe))
println("\nTotal cost will be \$", getobjectivevalue(m1))
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
prdt_igdt = pi[1:end,2:end] # rows are products, columns are ingredients
A = NamedArray(prdt_igdt, (prdt, igdt), ("products","ingredients"))

raw3 = CSV.read("ingredient_effects.csv", nullable = false);
#turn DataFrame into an Array
ie = convert(Array, raw3)
# the ‘‘names’’ of the DataFrame (header) are the adverse effects
#ad_eff = names(raw3[2:end])
ad_eff = [1,2,3]  #3 kind of adverse effects. 1: human cancer risk; 2: human noncancer risk; 3: ecosystem risk
# create a NamedArray that specifies how much of each ad-effects each ingredients provides
igdt_ad = ie[1:end,2:end] # rows are ingredients, columns are adverse effects
d = NamedArray(igdt_ad, (igdt, ad_eff), ("ingredients","adverse effects"))
pd = Dict()
for i in prdt
    for t in ad_eff
        pd[(i,t)] = sum(A[i,k]*d[k,t] for k in igdt)
    end
end
function min_adverse(λ)
    m2 = Model(solver=ClpSolver())
    @variable(m2, x[prdt]>=0) #usage of each product
    @constraint(m2, requirement[j in eff], sum(x[i]*r[i,j]  for i in prdt) >= c[j]) #need to meet the requirement
                                                                                    #for each effects
    @objective(m2, Min, sum(x[i]*(pd[(i,1)] + pd[(i,2)]) for i in prdt) + λ*sum(x[i] * pd[(i,3)] for i in prdt))
    solve(m2)
    human_health = getvalue(sum(x[i]*(pd[(i,1)] + pd[(i,2)]) for i in prdt))
    ecosystem = getvalue(sum(x[i] * pd[(i,3)] for i in prdt))
    plan = getvalue(x)
    return(plan, human_health,ecosystem)
end

function min_cost_n_adverse(λ_1,λ_2)
    m3 = Model(solver=ClpSolver())
    @variable(m3, x[prdt]>=0)
    @constraint(m3, requirement[j in eff], sum(x[i]*r[i,j]  for i in prdt) >= c[j]) #need to meet the requirement
                                                                                    #for each effects
    @objective(m3, Min, sum(x[i]*price[i] for i in prdt) + λ_1*sum(x[i]*(pd[(i,1)] + pd[(i,2)]) for i in prdt) + λ_2*sum(x[i] * pd[(i,3)] for i in prdt))
    solve(m3)
    human_health = getvalue(sum(x[i]*(pd[(i,1)] + pd[(i,2)]) for i in prdt))
    ecosystem = getvalue(sum(x[i] * pd[(i,3)] for i in prdt))
    plan = getvalue(x)
    cost = getvalue(sum(x[i]*price[i] for i in prdt))
    return(cost, plan, human_health,ecosystem)
end

d1 = min_cost_n_adverse(1,1)

Npts = 10
y1 = zeros(Npts)
y2 = zeros(Npts)

for i in 1:10
    result = min_adverse(0.00000000001*10^(i))
    # result = min_adverse(i)
    y1[i] = result[2]  #human health
    y2[i] = result[3]  #ecosystem
end

using PyPlot, Gurobi
# figure(figsize=(8,4))
plot(y1,y2,"b.-")
title(L"Plot of $\Gamma_3(x)$")
xlabel(L"ln(y_1) [ln(cases)]")
ylabel(L"$y_2(PAF\cdot m^3)$")
title("Pareto Curve for Human Health VS Ecosystem Risk")
# grid()
