###### PART 1  #######
########################## Base model ########################

# master sets of zip codes and sorting facilities
set zip; #set of zip codes
set sf_current; #current set of sorting facility (around 800)
set sf_potential; #set of potentially new sorting facility (around 100)
set sf = sf_current union sf_potential; #set of all potential sorting facility
set congress_district; # set of all congress districts. 

#parameters
param n > 0 integer;    #Number of sorting facilities
param m > 0 integer;    #Number of zip codes

####### Defining params #######
## Origination and Destination demand volumes. 
param volume_originated {zip} >= 0; #Volume originating from a zip code.  
param volume_destinated {zip} >= 0; #Volume to be delivered to (or destined to) a zip code. 

## Open/close of sorting facilites
param prior_status{sf} >= 0 ; # Current sorting facilities (sf_current) marked as 1 and rest as 0. 
param sf_open {sf_potential} >= 0; #Fixed cost of setting up new sorting facility. 
param sf_shut {sf_current} >= 0; #Fixed cost of shutting down a current facility.

## sorting facility capacities
param capacity{sf} >= 0; # Max capacities for all sorting facilities
param sf_handling_cost{sf} >= 0; # Per unit handling costs at each sorting facility. 

## transportation costs; assuming transportation costs are same in either direction for a pair. 
param zip_to_sf_transportation {zip, sf} >= 0; # Transportation cost from each zip to sorting facilities. 
param sf_to_sf_transportation {sf, sf} >= 0; # Transportation cost from a sorting facility to another sorting facility.

## district to sf mapping
param district_to_sf_mapping {congress_district,sf} >= 0; # Binary mapping, 1 if a sf falls in that congress district else 0.


####### Defining Variables ####### 

var new_status{sf} >= 0 binary; # whether a particular sf is open or close in final answer.
var zip_sf_mapping{zip, sf} >= 0 binary; # which all zipcodes assigned to which all sf in new arrangement. 

###### Defining Objective #######  
minimize total_cost:
      		(sum {i in zip} 
      	 		(volume_originated[i]* sum{j in sf} (zip_to_sf_transportation[i,j]*zip_sf_mapping[i,j])  #cost of first leg of transportation.
      	 		+ (volume_destinated[i]*sum{j in sf} (zip_to_sf_transportation[i,j]*zip_sf_mapping[i,j]))  #cost of last leg of transportation.
                +  #cost of middle leg of transportation.(sf to sf)      	 	
      	 	+ (sum {j in sf, i in zip} sf_handling_cost[j]*(volume_originated[i]*zip_sf_mapping[i,j] + volume_destinated[i]*zip_sf_mapping[i,j])
      	 	# cost of handling at each sf. Note that cost of handling at zipcode level are not considered here as those costs are not 
      	 	# dependent on the variable decision of this problem. 													 
      	 	+ (sum {j in sf_current} sf_shut[j]*(1-new_status[j])) #cost of shutting down an existing sf. 
      	 	+ (sum {j in sf_potential} sf_open[j]*new_status[j]) #cost of opening a new sf. 
      	 				

####### Defining Constraints ####### 

# Constraint_1: One zip code is mapped to one sf only. 
s.t. Constraint_1 {i in zip}:
	sum {j in sf} zip_sf_mapping[i,j] = 1; 
	
# Constraint_2: incoming volume at a hub is within capacity. 
s.t. Constraint_2 {j in sf}:
	sum {i in zip} (volume_originated[i]*zip_sf_mapping[i,j]) <= capacity[j];

# Constraint_3: outgoing volume from a hub is within capacity. 
s.t. Constraint_3 {j in sf}:
	sum {i in zip} (volume_destinated[i]*zip_sf_mapping[i,j]) <= capacity[j];

# Constraint_4 : Current open sf can only be open or close # Redundant though as new_status is defined as binary only. 
s.t. Constraint_4 {j in sf_current}:
	new_status[j] <= 1


###### PART 2  #######
#As shown in table below origination and destination data can be obtained by having to_zip and from_zip cross data. 
#<insert table> 

## To and from demand volumes. 
param volume_from_zip_to_zip {zip, zip} >= 0; #Volume originating from a zip code toward another zip code. 

# Modify Objective function to include cost of movement between  
 
minimize total_cost = cost function in part A 
                    + (sum {i in zip, j in zip, k in sf} volume_from_zip_to_zip[i,j]*sf_to_sf_transportation[zip_sf_mapping[i,k], zip_sf_mapping[j,k]]); 


###### PART 3 #######
# Constraint_5 : Additional constraint to ensure atleast one facility be located within each congressman district
s.t. Constraint_5 {i in congress_district}:
	sum {j in sf} district_to_sf_mapping[i,j]*new_status[j] >= 1
	
###### PART 4 #######
# Constraint_6 : Balancing between congressman district, one of doing that is to restrict each congress district to some range. 
s.t. Constraint_6 {i in congress_district}:
	sum {j in sf} district_to_sf_mapping[i,j]*new_status[j] <= 3 # each district will have between 1,2 or 3 sorting facilities.
	
	
###### PART 5 ######
#Modify your model to select from amongst the solutions that minimize the USPS cost, the solution that minimizes the large mailer costs. 

set bulk_senders: # set of all bulk senders. 
param bulk_to_sf_transportation {bulk_senders, sf} >= 0; # Transportation cost from a bulk senders to send to each sorting facility.
param bulk_to_sf_volume {bulk_senders, zip } >= 0; # Transportation cost from a bulk senders to send to each sorting facility.

# Modify Objective function: 
 
minimize total_cost: C1*cost function in part A 
				    + C2* sum {i in bulk_senders, j in zip} (bulk_to_sf_volume[j,i]*sum {k in sf} zip_sf_mapping[j,k]*bulk_to_sf_transportation[i,k]  	
# C1 and C2 represents the relative weight to be given to USPS and bulk sender's costs. 

 	
###### PART 6 ######
#The bulk mailers also have concerns over fairness. None wants to incur unnecessary costs for the benefit of the others
	
param bulk_senders_costs {bulk_senders} >= 0; # Current costs of bulk senders. 

# Constraint_7 : Putting constriant to ensure total cost for each bulk sender is within certain rainge of current costs.  
s.t. Constraint_7 {i in bulk_senders}:
	sum {j in zip, k in sf} (bulk_to_sf_volume[j,i]*sum {k in sf} zip_sf_mapping[j,k]*bulk_to_sf_transportation[i,k]) <= 1.2*bulk_senders_costs(i) 
	# ensures new costs to be within 20% of original costs. 

	
                     