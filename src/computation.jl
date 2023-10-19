"""
Compute the maximal value by which we can scale the α_vector and be stable.
"""
function maximal_alpha_scaling(net::NetworkParameters)
    λ_base = (I - net.P') \ net.α_vector #Solve the traffic equations
    ρ_base = λ_base ./ service_capacity(net) #Determine the load ρ  
    return minimum(1 ./ ρ_base) #Return the maximal value
end

max_scalings = round.(maximal_alpha_scaling.([scenario1, scenario2, scenario3, scenario4]),digits=3)

"""
Use this function to adjust the network parameters to the desired ρ⋆, c_s, and R.
"""
function set_scenario(net::NetworkParameters, ρ::Float64, c_s::Float64 = 1.0, R::Float64 = 1.0)
    (ρ ≤ 0 || ρ ≥ 1) && error("ρ is out of range")  
    (R ≤ 0 || R > 1) && error("R is out of range")  
    net = @set net.γ₁ = net.γ₂ * (1-R)/R
    max_scaling = maximal_alpha_scaling(net)
    net = @set net.α_vector = net.α_vector*max_scaling*ρ
    net = @set net.c_s = c_s
    return net
end;

#Total steady state mean queue lengths as a function of ρ*
#cₛ = R = 1. Mean steady state queue length is ρᵢ/(1-ρᵢ)

ρ_grid = 0.1:0.01:0.9
mean_steady_state_queue_size(ρ) = ρ/(1-ρ)
function steady_state_q_lengths(net::NetworkParameters)
    steady_state_q = [] 
    for i in ρ_grid
        new_sen = set_scenario(net, i)
        λ_arr = (I - new_sen.P') \ new_sen.α_vector
        ρ_arr = λ_arr ./ new_sen.μ_vector 
        append!(steady_state_q, sum(mean_steady_state_queue_size.(ρ_arr)))
    end
    return steady_state_q
end 

#=
plot(ρ_grid, steady_state_q_lengths(scenario1), 
xlabel = "ρ*", ylabel = "Total steady state mean queue lengths",
label = false, lw = 2, c = :black, xlim = (0,1),ylim=(0,20)) 
=#