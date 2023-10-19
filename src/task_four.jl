function task_four(scenario::NetworkParameters, scenario_num; reps::Int64=2, max_time::Float64= Float64(10^5), warm_up_time::Int64=10^3)
    c_s_values = [0.1, 0.5, 1.0, 2.0, 4.0]
    scenario_num == 4 ? (ρ_grid = 0.1:0.05:0.9) : (ρ_grid = 0.1:0.01:0.9)
 
    #consider only for scenario 1 for fixed R and varying c_s
    R = 0.75
    test_scenarios_c_s = [[set_scenario(scenario, ρ, c_s, R) for ρ in ρ_grid] for c_s in c_s_values]

    p = plot(title="Scenario $scenario_num varying cₛ", label="Simulated", xlabel="ρ*", ylabel="Total mean queue length", legend=:topleft)

    #Consider each ρ with a loop through the test_scenarios
    for (c_s_index, c_s_scenario) in enumerate(test_scenarios_c_s)
        total_mean_queue_lengths = []
        #consider varying c_s
        for scen in c_s_scenario 
            total_mean_q_length = []
            #add multiple reps
            for _ in 1:reps
                mean_q_length = sim_net(scen, max_time = Float64(10^4), warm_up_time = 100)[1]
                total_mean_q_length = push!(total_mean_q_length, mean_q_length) 
            end
        total_mean_queue_lengths = push!(total_mean_queue_lengths, sum(total_mean_q_length)/reps) 
        end
        plot!(ρ_grid, total_mean_queue_lengths, label = "cₛ = $(c_s_values[c_s_index])")
    end 
    R_values = [0.25, 0.75, 1.0]
    scenario_num == 4 ? (ρ_grid = 0.1:0.05:0.9) : (ρ_grid = 0.1:0.01:0.9)
 
    #Consider only scenario 1 with varying R
    c_s = 0.5
    test_scenarios_R = [[set_scenario(scenario, ρ, c_s, R) for ρ in ρ_grid] for R in R_values]

    q = plot(title="Scenario $scenario_num varying R", label="Simulated", xlabel="ρ*", ylabel="Total mean queue length", legend=:topleft)

    #consider each ρ with a loop through the test scenarios
    for (R_index, R_scenario) in enumerate(test_scenarios_R)
        total_mean_queue_lengths_R = []
        #consider varying c_s
        for scen in R_scenario 
            total_mean_q_length_R = []
            #add multiple reps
            for _ in 1:reps
                mean_q_length_R = sim_net(scen, max_time = Float64(10^4), warm_up_time = 100)[1]
                total_mean_q_length_R = push!(total_mean_q_length_R, mean_q_length_R) 
            end
        total_mean_queue_lengths_R = push!(total_mean_queue_lengths_R, sum(total_mean_q_length_R)/reps) 
        end
        plot!(ρ_grid, total_mean_queue_lengths_R, label = "R = $(R_values[R_index])")
    end
    plot(p,q)
end