"""
Test function for theoretical vs. simulated mean queue lengths
"""
function test_one(net::NetworkParameters) 
    ρ_grid = 0.1:0.01:0.9
    theoretical_ρ = steady_state_q_lengths(net) #theoretical ρ values
    mean_lengths = [] #total mean queue lengths via simulation 
    for ρ in ρ_grid 
        # Set new scenario based on ρ*
        new_net = set_scenario(net, ρ)
        # Simulate for above and record simulated mean queue length
        push!(mean_lengths, sim_net(new_net, max_time = Float64(10^6), warm_up_time = 10^4)[1])
    end 

    abs_err = [] # Absolute error between theoretical and simulated 
    for i in 1:length(ρ_grid)
        push!(abs_err, abs(theoretical_ρ[i] - mean_lengths[i]))
    end 

    # Plot simulated mean queue length 
    plt1 = plot(ρ_grid, mean_lengths, 
        xlabel = "ρ*", ylabel = "Total steady state mean queue lengths",
        label = "Simulated", lw = 2, c = :black, xlim = (0,1),ylim=(0,20)) 
    # Plot, on same axis, theoretical mean queue length 
    plot!(ρ_grid, theoretical_ρ, 
        xlabel = "ρ*", ylabel = "Total steady state mean queue lengths",
        label = "Theoretical", lw = 2, linecolour = :red, xlim = (0,1),ylim=(0,20)) 

    plt2 = plot(ρ_grid, abs_err, 
        xlabel = "ρ*", ylabel = "Absolute Error",
        label = "Simulated", lw = 2, xlim = (0,1), ylim=(0,2)) 
        
    plot(plt1, plt2)
end 