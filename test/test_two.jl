"""
Test function for the arrival rate of the simulation.
"""
function test_two(net::NetworkParameters)
    cs = [0.1, 0.3, 0.7, 1.0] #multiple 
    ρ = 0.5 #check if this should be different 
    sim_Aᵢ = []
    λᵢ = []
    max_time = 1000.0 #better way? 
    for i in cs
        new_sim = set_scenario(net, ρ, i, 1.0)
        push!(sim_Aᵢ, [i/max_time for i in sim_net(new_sim, max_time = max_time, warm_up_time = 10)[3]]) #simulate 
        λ =  (I - new_sim.P') \ new_sim.α_vector #theoretical 
        push!(λᵢ, λ) #theoretical 
    end 
    #absolutetly need to change the way this output is presented 
    for i in 1:length(sim_Aᵢ)
        println(sim_Aᵢ[i])
        println(λᵢ[i])
    end
end 
