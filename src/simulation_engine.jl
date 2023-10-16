"""
The main simulation function gets an initial state and an initial event
that gets things going. Optional arguments are the maximal time for the
simulation, times for logging events, and a call-back function.
"""
function simulate(init_state::State, init_timed_event::TimedEvent
                    ; 
                    max_time::Float64 = 10.0, 
                    log_times::Vector{Float64} = Float64[],
                    callback = (time, state) -> nothing)

    ### Global for repair states 
    global breakdown_states = [i for i in 1:num_queues]

    # The event queue
    priority_queue = BinaryMinHeap{TimedEvent}()

    # Put the standard events in the queue
    push!(priority_queue, init_timed_event)
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

        # The event may spawn 0 or more events which we put in the priority queue 
        for nte in new_timed_events
            push!(priority_queue,nte)
        end

        # Callback for each simulation event
        callback(time, state)
    end
end;

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
function sim_net(net::NetworkParameters; max_time = 10^6, warm_up_time = 10^4, seed::Int64 = 42)::Float64
    
    #Set the random seed
    Random.seed!(seed)
    
    #The function would execute the simulation here - and this would use multiple other functions, types, and files

    estimated_total_mean_queue_length = 12.3 #the function would estimate this value (12.3 is just a place-holder)

    return estimated_total_mean_queue_length
end;