"""
A test to investigate the long term proportion of time "on" for each server 
with various set values of R.
"""
function test_three(net::NetworkParameters)
    R_vals = [i*0.1 for i in 1:9] # R-values to test
    cs, ρ = 0.5, 0.5 # c_s and ρ values to be constant
    on_prop = [] #Long term proportion of time "on" associated with above
    for r in R_vals
        new_sim = set_scenario(net, ρ, cs, r) # set new senario based on params 
        # Simulate and push rounded long term proportions into on_prop 
        push!(on_prop, [round(x, digits = 3) for x in sim_net(new_sim, max_time = 1000.0, warm_up_time = 10)[2]])
    end
    for i in 1:9
        println("For R = ", round(i*0.1, digits = 2) , " long term proportion of time on for each server is given by ", on_prop[i])
    end
end 