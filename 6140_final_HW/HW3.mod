# master sets 
set raw; #set of raw materials
set cap; #set of non invertible capacities
set prod; #set of products

#derived sets for problem statement
set material := raw union prod ; #set of materials (raw U prod)
set resources := material union cap ; #set of resources (raw U cap U prod, basically everything)
set supplies := raw union cap; #set of suppply items (raw U prod)

#time periods
param T > 0 integer;    #time period in which demand is created
param Ts > 0 integer;    #time period in which demand is served or sold

## Defining params 
param supply {supplies,1..T} >= 0; #Supply of raw material/capacity in supplies at time T
param demand {material,1..T} >= 0; # Demand for material at time T (or later)
param revenue {material,1..T, 1..Ts} >= 0;# Revenue from selling material M to demand in time T when supplied at Ts
param scr_cost {resources,1..T} >= 0; #Scrapping cost for resource at time t
param inv_cost {material,1..T} >= 0; #Inventory cost for material at time t
param aij {prod,resources} >=0; # how many resources are required for one unit of product

## Defining variables
var demand_served {material,1..T,1..Ts} integer >= 0; # Units of material M sold to demand in T at Ts , Ts more than equal to T
var made {prod,1..T} integer >= 0; # Units of product P made in T
var scr {resources,1..T} integer >= 0; # Units of resource R scrapped in T
var inv {material,1..T} integer >= 0; # Units of material M inventoried in T

## Defining objective 
maximize total_profit:
      sum {t in 1..T} ( sum {mat in material} (sum {ts in t..Ts} revenue [mat,t,ts] * demand_served [mat,t,ts])
                      - sum {r in resources} scr_cost [r,t]*scr [r,t]
                      - sum {m in material} (inv_cost [m,t]*inv [m,t]) );
                      
                      # revenue by selling products of demand t in ts - sum of scrapping cost - sum of inventory cost
                      
## Defining constraints 

#constraint 1.1: Material balance for product for periods more than 2. 

s.t. material_balance_product_1 {j in prod, t in 2..T}:
      sum {i in prod} aij[i,j] * made[i,t] + scr[j,t] + inv[j,t] + sum {ts in 1..t} demand_served [j,t,ts] =  made[j,t] + inv[j,t-1] ;

#constraint 1.2: Material balance for raw for periods more than 2. 

s.t. material_balance_raw_1 {j in raw, t in 2..T}:
     sum {i in prod} aij[i,j] * made[i,t] + scr[j,t] + inv[j,t] + sum {ts in 1..t} demand_served [j,t,ts] = supply[j,t] + inv[j,t-1] ;
      
#constraint 1.3 : Material balance for product for period equal 1. 

s.t. material_balance_product_2 {j in prod}:
      sum {i in prod} (aij[i,j] * made[i,1]) + scr[j,1] + inv[j,1] + demand_served [j,1,1] = made[j,1] ;
      
#constraint 1.4: Material balance for raw for period equal to 1. 

s.t. material_balance_raw_2 {j in raw}:
      sum {i in prod} (aij[i,j]* made[i,1]) + scr[j,1] + inv[j,1] + demand_served [j,1,1] = supply[j,1];
      

#constraint 2 :  balance for capacity

s.t. cap_balance {j in cap, t in 1..T}:
      sum {i in prod} aij[i,j]*made[i,t] + scr[j,t] = supply[j,t] ;
      
#constraint 5: balance for raw material periods more than 2. 

#s.t. raw_balance_1 {j in raw, t in 2..T}:
#      sum {i in prod} (aij[i,j] * made[i,t]) + scr[j,t] + inv[j,t] + sum {ts in 1..t} demand_served [j,t,ts] = supply[j,t] +  inv[j,t-1] ;
      

#constraint 6 : Demand served till time T is less than equal to demand till time T. 
s.t. demand_balance {j in material, t in 1..T}:
      sum {ts in 1..Ts} demand_served [j,t,ts] <=  demand [j,t] ;

