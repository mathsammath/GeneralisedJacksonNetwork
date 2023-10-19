###################################################################
###################################################################
# A file with instructions for how to run the main simulation code 
###################################################################
###################################################################

println("The main simulation function, sim_net, requires a network parameter as an arguement.")
println("This repo has four network paramter scenarios, named scenario1, scenario2 etc.")
println("When we run the simulation function with one of these scenarios, the simulation will run for a ")
println("default time of 10^6 seconds, recording relevant statistics for estimated total mean queue length only")
println("after a 'warm up time' of 10^4 seconds.")
println()

println("The paramters of scenario1 are given by")
println(scenario1)

println("When we run the simulation for scenario1, we return three pieces of information:")
println("    (1) The estimated total mean queue length")
println("    (2) The total 'on' times of each server")
println("    (3) The total arrivals to each server")
println()

println("Running the simulation for scenario1 we have")
println(sim_net(scenario1))

println("The simulation can handle servers breaking down. We can change the parameters")
println("of scenario1 to have breakdowns.")
new_scenario = set_scenario(scenario1, 0.5, 0.5, 0.2)
println(new_scenario)

println("The output of the simulation will change when we have breakdowns.")
println(sim_net(new_scenario))