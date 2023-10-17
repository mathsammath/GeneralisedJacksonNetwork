include("simulation_script.jl")

"""
Runs a discrete event simulation of an Open Generalized Jackson Network with Breakdowns and Repairs `net`. 

The simulation runs from time `0` to `max_time`. 

Statistics about the total mean queue lengths are recorded from `warm_up_time` 
onwards and the estimated value is returned. For debug purposes statistics about proportion of time on are also recorded. 

This simulation does NOT keep individual customers state, it only keeps the following minimal state: 
* The number of jobs in each queue.
* If each server is on or off.
* In case the server is off and there is a job "stuck" in it, how much processing time is left on that job. 
"""
function sim_net(net::NetworkParameters; max_time = Float64(10^6), warm_up_time = 10^4, seed::Int64 = 42)
    
    #Set the random seed
    Random.seed!(seed)

    """
    The main simulation function gets an initial state and an initial event
    that gets things going. Optional arguments are the maximal time for the
    simulation, times for logging events, and a call-back function.
    """
    function simulate(init_state::State, init_timed_event::Vector{TimedEvent}
                        ; 
                        max_time::Float64 = 10^6, 
                        log_times::Vector{Float64} = Float64[],
                        callback = (time, state) -> nothing)

        # Log times & queues where services/arrivals occur 
        event_change_times = [] 
        event_change_queues_num = []

        # Log time "on" for servers 
        service_on_times = Array{Float64}(undef, init_state.params.L)

        # Log all arrivals to each node 
        event_arrival_log = ones(init_state.params.L) # Initially one job at each node

        # Global variable for breakdown/repair states 
        global breakdown_states = [false for i in 1:init_state.params.L]

        # The event queue
        priority_queue = BinaryMinHeap{TimedEvent}()

        # Put the standard events in the queue
        for event in init_timed_event
            push!(priority_queue, event)
        end
        push!(priority_queue, TimedEvent(EndSimEvent(), max_time))
        for log_time in log_times
            push!(priority_queue, TimedEvent(LogStateEvent(), log_time))
        end

        # initialize the state
        state = deepcopy(init_state)
        time = 0.0

        # Callback at simulation start
        callback(time, state)

        # The main discrete event simulation loop - SIMPLE!
        while true
            # Get the next event
            timed_event = pop!(priority_queue)

            # Advance the time
            time = timed_event.time

            # Act on the event
            new_timed_events = process_event(time, state, timed_event.event) 

            # If the event was an end of simulation then stop
            if timed_event.event isa EndSimEvent
                break 
            end

            # If event is an arrival or service, add it to log of all arrivals 
            if timed_event.event isa ExternalArrivalEvent || timed_event.event isa EndOfServiceAtQueueEvent
                if timed_event.event.next_q !== nothing 
                    event_arrival_log[timed_event.event.next_q] += 1 
                end
            end 

            if timed_event.time > warm_up_time # Only record data past warm up time
                # If event occurs where a queue length is changed then record it
                if timed_event.event isa EndOfServiceAtQueueEvent || timed_event.event isa ExternalArrivalEvent || 
                                                                            timed_event.event isa ExternalArrivalEventInitial
                    push!(event_change_times, timed_event.time)
                    push!(event_change_queues_num, sum(state.jobs_num)) 
                end

                # Recording time "on" for servers 
                if timed_event.event isa BreakdownEvent 
                    service_on_times[timed_event.q] += timed_event.time
                elseif timed_event.event isa RepairEvent
                    service_on_times[timed_event.q] -= timed_event.time 
                end 
            end

            # The event may spawn 0 or more events which we put in the priority queue 
            for nte in new_timed_events
                push!(priority_queue,nte)
            end

            # Callback for each simulation event
            callback(time, state)
        end

        # Change in time between events where queue length is changed
        delta_log_times = [0; diff(event_change_times)]

        # Estimate total mean queue length 
        est_total_mean_q_length = (delta_log_times ⋅ event_change_queues_num) / max_time

        # Return estimated total mean queue length, service on times, arrival log 
        return est_total_mean_q_length, service_on_times, event_arrival_log
    end;
    
    # Execute the simulation 
    simulate(QueueNetworkState([0 for i in 1:net.L], net), [TimedEvent(ExternalArrivalEventInitial(i), 0.0) for i in 1:net.L],
    max_time = max_time)
end;


#NOTE: Plots notworking for me. Here is th code without the plots. 
function task_four(; reps::Int64=1, max_time::Float64= Float64(5*10^4), warm_up_time::Int64=10^3)
    ρ_grid = 0.1:0.1:0.9
    c_s_values = [0.1, 0.5, 1.0, 2.0, 4.0]
    R_values = [0.25, 0.75, 1.0]

    #Simulate for changing R values for each scenario 
    for scenario in [scenario1, scenario2, scenario3, scenario4]
        R = 0.75
        #scale scenario parameters 
        test_scenarios = [[set_scenario(scenario, ρ, c_s, R) for ρ in ρ_grid] for c_s in c_s_values]
        
        println("Simulating $(scenario), for varying cₛ")
        
        #Consider each ρ
        for c_s_scen_group in test_scenarios 

            #initialise the mean quese lengths array
            mean_queue_lengths = Array{Float64}(undef, length(c_s_scen_group))
            
            #Consider each scenario 
            for (scen_num, scen) in enumerate(c_s_scen_group)
                
                #initialise mean queue length for this scenario 
                mean_queue_length_scen = Array{Float64}(undef,reps)

                 # Consider each rep
                for rep_num in 1:reps
                    # Run simulation
                    mean_queue_length_rep = sim_net(scen)[1]

                    # Combine results for each rep
                    mean_queue_length_scen[rep_num] = mean_queue_length_rep
                end
                #determine mean quese length for this scenario 
                mean_queue_lengths[scen_num] = sum(mean_queue_length_scen)/reps
            end
            #plot(ρ_grid, mean_queue_lengths) with extras
        end
    end
    #this can become one for loop. Will fix up 
    #simulate changing the c_s values
    for scenario in [scenario1]
        c_s = 0.5
        #scale scenario parameters 
        test_scenarios_R = [[set_scenario(scenario, ρ, c_s, R) for ρ in ρ_grid] for R in R_values]
        
        println("Simulating $(scenario), for varying cₛ")
        
        #Consider each ρ
        for R_scen_group in test_scenarios_R 

            #initialise the mean queue lengths array for each case
            mean_queue_lengths_R = Array{Float64}(undef, length(R_scen_group))
            
            #Consider each scenario 
            for (scen_num, scen) in enumerate(R_scen_group)
                
                #initialise mean queue length for this given  scenario 
                mean_queue_length_scen_R = Array{Float64}(undef,reps)

                 # Consider each rep
                for rep_num in 1:reps
                    # Run simulation
                    mean_queue_length_rep_R = sim_net(scen)[1]

                    # Combine results for each rep
                    mean_queue_length_scen_R[rep_num] = mean_queue_length_rep_R
                end
                #determine mean quese length for this scenario 
                mean_queue_lengths_R[scen_num] = sum(mean_queue_length_scen_R)/reps_R
            end
            #plot(ρ_grid, mean_queue_lengths) with extras
        end
    end

end
