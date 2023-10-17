"""
Qualitative test for relation between R and mean queue lengths 
"""
function test_four(net::NetworkParameters)
    R = [1.0, 0.8, 0.5, 0.3, 0.1]
    ρ = 0.5
    mean_queue_lengths = []
    max_time = Float64(10^5)
    for r in R 
        new_net = set_scenario(net, ρ, 0.1, r)
        push!(mean_queue_lengths, sim_net(new_net, max_time = max_time, warm_up_time = 100)[1])
    end 
    return mean_queue_lengths
end 