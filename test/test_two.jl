using DataFrames 

"""
Test function for the arrival rate of the simulation.
"""
function test_two(net::NetworkParameters)
    ρ = [i*0.2 for i in 1:4] # testing multiple cₛ values 
    cs, R = 0.5, 0.5 # ρ and R values remain constant
    sim_A = [] # simulated Aᵢ(T)/T 
    theoretical_λ = [] # theoretical λᵢs
    for i in ρ
        # Set new scenario based on params 
        new_sim = set_scenario(net, i, cs, R)
        # Simulate the above and push values into sim_A
        push!(sim_A, [j/(10^5) for j in sim_net(new_sim, max_time = Float64(10^5), warm_up_time = 10^3)[3]]) 
        # Compute theoretical value for λ from traffic equations
        λ =  inv((I - new_sim.P')) * new_sim.α_vector 
        push!(theoretical_λ, λ) 
    end 
    df = DataFrame(Simulated  = sim_A, theoretical_λ = theoretical_λ)
    println(df)
end 