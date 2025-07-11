"""
Qualitative test for relation between R and mean queue lengths 
"""
function test_four(net::NetworkParameters)
    R = [i*0.025 for i in 1:39] # R-values to test
    cs, ρ = 0.5, 0.5 # cₛ and ρ values to remain constant
    mean_queue_lengths = []  
    for r in R 
        new_net = set_scenario(net, ρ, cs, r)
        push!(mean_queue_lengths, sim_net(new_net, max_time = Float64(10^5), warm_up_time = 10^3)[1])
    end 

    # Plot simulated mean queue lengths on same plot 
    plot(R, mean_queue_lengths, 
        xlabel = "R", ylabel = "Total mean queue lengths",
        label = "Simulated", lw = 2, xlim = (0,1),ylim=(2, 5)) 
end 