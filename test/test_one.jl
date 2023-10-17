"""
Test function for theoretical vs. simulated mean queue lengths
"""
function test_one(net::NetworkParameters) 
    ρ_grid = 0.1:0.01:0.9
    theoretical_ρ = steady_state_q_lengths(net) #theoretical vals
    mean_lengths = []
    for ρ in ρ_grid 
        # Set new scenario based on ρ*
        new_net = set_scenario(net, ρ)
        # Simulate for above and record simulated mean queue length
        push!(mean_lengths, sim_net(new_net, max_time = Float64(10^4), warm_up_time = 10))
    end 
    abs_err = [] # Absolute error between theoretical and simulated 
    for i in 1:length(ρ_grid)
        push!(abs_err, abs(theoretical_ρ[i] - mean_lengths[i]))
    end 
    # Plot simulated mean queue length 
    plt = plot(ρ_grid, mean_lengths, 
        xlabel = "ρ*", ylabel = "Total steady state mean queue lengths",
        label = false, lw = 2, c = :black, xlim = (0,1),ylim=(0,20)) 
    # Plot, on same axis, theoretical mean queue length 
    plot!(ρ_grid, theoretical_ρ, 
        xlabel = "ρ*", ylabel = "Total steady state mean queue lengths",
        label = false, lw = 2, linecolour = :red, xlim = (0,1),ylim=(0,20)) 
    #RETURN ABSOLUTE ERROR?????
end 