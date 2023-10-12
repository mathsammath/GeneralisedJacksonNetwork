using DataStructures
import Base: isless

#what objects do we need?
#state & event abstract types
abstract type State end 
abstract type Event end 

#timed event (event and time it takes place)
struct TimedEvent
    event::Event
    time::Float64
end

#queue state (number of people in the queue)
mutable struct QueueState <: State 
    number_in_queue::Int #the number of jobs in a queue 
end 

struct ArrivalEvent <: Event end
struct EndOfServiceEvent <: Event end

#system state 
mutable struct SystemState <: State 
    number_queues::Int #the number of queues in the system 
    number_in_system::Int #the number of jobs in the system 
end  

# Process an arrival event
function process_event(time::Float64, state::State, ::ArrivalEvent)
    # Increase number in system
    state.number_in_system += 1
    new_timed_events = TimedEvent[]

    # Prepare next arrival
    push!(new_timed_events,TimedEvent(ArrivalEvent(),time + rand(Exponential(1/λ))))

    # If this is the only job on the server
    state.number_in_system == 1 && push!(new_timed_events,TimedEvent(EndOfServiceEvent(), time + 1/μ))
    return new_timed_events
end

# Process an end of service event 
function process_event(time::Float64, state::State, ::EndOfServiceEvent)
    # Release a customer from the system
    state.number_in_system -= 1 
    @assert state.number_in_system ≥ 0
    return state.number_in_system ≥ 1 ? [TimedEvent(EndOfServiceEvent(), time + 1/μ)] : TimedEvent[]
end

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