"""
A test to investigate the long term proportion of time "on" for each server 
with various set values of R.
"""
function test_three(net::NetworkParameters)
    R_vals = [0.1, 0.4, 0.6, 1.0] #R-values to test
    on_prop = [] #Long term proportion of time "on" associated with above
    for r in R_vals
        #NOTE: ρ value currently set to 0.5. What should this be set to?
        new_sim = set_scenario(net, 0.5, 1.0, r)
        push!(on_prop, [round(x, digits = 3) for x in sim_net(new_sim, max_time = 1000.0, warm_up_time = 10)[2]])
    end
    return on_prop
end 