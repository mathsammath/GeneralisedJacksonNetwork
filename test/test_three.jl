using DataFrames 

"""
A test to investigate the long term proportion of time "on" for each server 
with various set values of R.
"""
function test_three(net::NetworkParameters)
    R_vals = [i*0.2 for i in 1:5] # R-values to test
    cs, ρ = 0.5, 0.5 # c_s and ρ values to be constant
    on_prop = [] #Long term proportion of time "on" associated with above
    for r in R_vals
        new_sim = set_scenario(net, ρ, cs, r) # set new senario based on params 
        # Simulate and push rounded long term proportions into on_prop 
        push!(on_prop, [round(x, digits = 3) for x in sim_net(new_sim, max_time = 1000.0, warm_up_time = 10)[2]])
    end
    df = DataFrame(R = R_vals, long_term_proportion_on = on_prop)
    println(df)
end 