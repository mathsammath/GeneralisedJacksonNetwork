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

        # Global variable for breakdown/repair states 
        global breakdown_states = [false for i in 1:net.L]

        # Times & Queues numbers where events occur 
        event_change_times = [] 
        event_change_queues_num = []
        # Breakdown and Repair events. Inner list represents ith server 
        brk_rep_events = [[] for i in 1:net.L]
        # Logging total arrivals at each server. Every server is initialised with one job. 
        event_arrival_log = ones(init_state.params.L) 

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

            # If the event was an end of simulation then stop
            if timed_event.event isa EndSimEvent
                break 
            end

            # If event is an arrival, add it to log of all arrivals 
            if timed_event.event isa ExternalArrivalEvent                 
                event_arrival_log[timed_event.event.next_q] += 1 
            end

            # Only record data for total mean queue length past warm up time
            if timed_event.time > warm_up_time 
                # If event occurs where a queue length is changed then record it
                if timed_event.event isa EndOfServiceAtQueueEvent # Must ensure servers are "on"                                   
                    breakdown_states[timed_event.event.q] == false && push!(event_change_times, timed_event.time)
                    breakdown_states[timed_event.event.q] == false && push!(event_change_queues_num, sum(state.jobs_num)) 
                else 
                    push!(event_change_times, timed_event.time)
                    push!(event_change_queues_num, sum(state.jobs_num)) 
                end
            end

            # Add events to list of lists 
            if timed_event.event isa BreakdownEvent || timed_event.event isa RepairEvent
                push!(brk_rep_events[timed_event.event.q], timed_event)
            end 

            # Act on the event
            new_timed_events = process_event(time, state, timed_event.event) 

            # If new_timed_events contains an EndOfServiceAtQueueEvent, we need to add 
            # the queue that this job goes to, to our log of arrivals 
            if timed_event.event isa EndOfServiceAtQueueEvent
                if timed_event.event.next_q !== nothing 
                    event_arrival_log[timed_event.event.next_q] += 1
                end
            end  

            # The event may spawn 0 or more events which we put in the priority queue 
            if new_timed_events !== nothing 
                for nte in new_timed_events
                    push!(priority_queue,nte)
                end
            end 

            # Callback for each simulation event
            callback(time, state)
        end

        # COMPUTING TOTAL ON TIME FOR SERVERS 
        # Log time "on" for servers 
        service_on_times = [[Float64(0)] for i in 1:net.L]
        # For all queues, check if last event is repair. if not, add repair event.
        for lst_event in brk_rep_events 
            if !isempty(lst_event) && lst_event[end].event isa BreakdownEvent
                #if its a breakdown, add a repair event so we can do computation
                push!(lst_event, TimedEvent(RepairEvent(lst_event[end].event.q), max_time))
            end 
        end  
        # Now we can compute the difference in times to get the total "off" time 
        for i in 1:net.L
            if !isempty(brk_rep_events[i])
                for j in 1:length(brk_rep_events[i])
                    if brk_rep_events[i][j].event isa RepairEvent
                        service_on_times[i][1] += brk_rep_events[i][j].time
                    elseif brk_rep_events[i][j].event isa BreakdownEvent
                        service_on_times[i][1] -= brk_rep_events[i][j].time
                    end 
                end
            end 
        end 
        # Compute total time time servers are "on" 
        times_final = Float64[] 
        for t in service_on_times
            push!(times_final, max_time - t[1])
        end 

        # COMPUTING ESTIMATED TOTAL MEAN QUEUE LENGTH 
        # Change in time between events where queue length is changed
        delta_log_times = [0; diff(event_change_times)]
        est_total_mean_q_length = (delta_log_times ⋅ event_change_queues_num) / max_time

        # Return estimated total mean queue length, service on times, arrival log 
        return est_total_mean_q_length, times_final, event_arrival_log
    end;

    #INITIAL CONDITIONS 
    initial_conditions = [TimedEvent(ExternalArrivalEvent(i), 0.0) for i in 1:net.L]
    for i in 1:net.L
        push!(initial_conditions, TimedEvent(RepairEvent(i), 0.0))
    end 
    
    # Execute the simulation 
    simulate(QueueNetworkState([0 for i in 1:net.L], net), initial_conditions, max_time = max_time)
end;

