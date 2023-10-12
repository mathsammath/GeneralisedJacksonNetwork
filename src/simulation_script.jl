using DataStructures
import Base: isless

# State and Event abstract (superclass) types
abstract type Event end
abstract type State end

#Captures an event and the time it takes place
struct TimedEvent
    event::Event
    time::Float64
end

#Comparison of two timed events - this will allow us to use them in a heap/priority-queue
isless(te1::TimedEvent, te2::TimedEvent) = te1.time < te2.time

#This is an abstract function 
"""
It will generally be called as 
       new_timed_events = process_event(time, state, event)
It will generate 0 or more new timed events based on the current event
"""
function process_event end

#Generic events that we can always use
struct EndSimEvent <: Event end #Event that ends the simulation
struct LogStateEvent <: Event end #Record when an event happens

function process_event(time::Float64, state::State, es_event::EndSimEvent)
    println("Ending simulation at time $time.")
    return []
end

function process_event(time::Float64, state::State, ls_event::LogStateEvent)
    println("Logging state at time $time.")
    println(state)
    return []
end

struct QueueNetworkParameters
    num_queues::Int # The number of queues in our system 
    α::Vector{Any} # External arrival rates (αᵢ's) for queues as an ordered vector
    μ::Vector{Any} # Service rates (μᵢ's) as an ordered vector
    scv_arr::Vector{Any} # Squared coefficient of variation of the service processes
end

mutable struct QueueNetworkState <: State 
    jobs_num::Vector{Int} # Number of jobs in each queue, ordered. 
    params::QueueNetworkParameterse # Parameters of queue network system
end 

#Total number of jobs in the system (necessary???)
total_in_system(state::TandemQueueNetworkState) = sum(state.queues)

#next_arrivival_duration RV for next arrival to the system externally 
#next_service_duration RV for next service of the system 

#PROCESSING EVENTS 
#process arrival event (external to system)
#process end of service event 
#process a breakdown of a server 
    

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