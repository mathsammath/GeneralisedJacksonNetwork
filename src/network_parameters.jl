using Parameters  
using Accessors 
using LinearAlgebra
using Random 

@with_kw struct NetworkParameters #The @with_kw macro comes from the Parameters.jl package and makes nice constructors
    L::Int
    α_vector::Vector{Float64} #This vector is a vector of α_i which can then be scaled
    μ_vector::Vector{Float64} #This is the vector of service rates considered fixed
    P::Matrix{Float64} #routing matrix
    c_s::Float64 = 1.0 #The squared coefficient of variation of the service times with a default value of 1.0
    γ₁::Float64 = (10^-8) #The rate of breakdown (rate of going from `on` to `off`) default is nothing
    γ₂::Float64 = 1.0 #The rate of repair (`off` to `on`)
end

# Returns the effective service rate vector Rμ (taking breakdowns into consideration)
service_capacity(net::NetworkParameters) = (net.γ₂/(net.γ₁ + net.γ₂)) * net.μ_vectorv

##################################
##################################
# EXAMPLE SCENARIOS 
##################################
##################################

############################
# Three queues in tandem
scenario1 = NetworkParameters(  L=3, 
                                α_vector = [0.5, 0, 0],
                                μ_vector = ones(3),
                                P = [0 1.0 0;
                                     0 0 1.0;
                                     0 0 0])

############################
# Three queues in tandem with option to return back to first queue
scenario2 = @set scenario1.P  = [0 1.0 0; #The @set macro is from Accessors.jl and allows to easily make a 
    0 0 1.0; # modified copied of an (immutable) struct
    0.3 0 0]                                      

############################
# A ring of 5 queues
scenario3 = NetworkParameters(  L=5, 
                                α_vector = ones(5),
                                μ_vector = collect(1:5),
                                P = [0  .8   0    0   0;
                                     0   0   .8   0   0;
                                     0   0   0    .8  0;
                                     0   0   0    0   .8;
                                     .8  0   0    0    0])

############################
# A large arbitrary network
#Generate some random(arbitrary) matrix P
Random.seed!(0)
L = 100
P = rand(L,L)
P = P ./ sum(P, dims=2) #normalize rows by the sum
P = P .* (0.2 .+ 0.7rand(L)) # multiply rows by factors in [0.2,0.9] 

scenario4 = NetworkParameters(  L=L, 
                                α_vector = ones(L),
                                μ_vector = 0.5 .+ rand(L),
                                P = P);                                     