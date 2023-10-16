include("network_parameters.jl")

using DataStructures, Random, Distributions, StatsBase
import Base: isless

# State and Event abstract (superclass) types
abstract type Event end
abstract type State end

# Captures an event and the time it takes place
struct TimedEvent
    event::Event
    time::Float64
end

# Comparison of two timed events - this will allow us to use them in a heap/priority-queue
isless(te1::TimedEvent, te2::TimedEvent) = te1.time < te2.time

# This is an abstract function 
"""
It will generally be called as 
       new_timed_events = process_event(time, state, event)
It will generate 0 or more new timed events based on the current event
"""
function process_event end

# Generic events that we can always use
struct EndSimEvent <: Event end # Event that ends the simulation

struct LogStateEvent <: Event end # Record when an event happens

mutable struct ExternalArrivalEvent <: Event end 

struct ExternalArrivalEventInitial <: Event 
    q::Int # Queue initial job is assigned to 
end
 
struct EndOfServiceAtQueueEvent <: Event
    q::Int # The index of the queue where service finished
end

struct BreakdownEvent <: Event 
    q::Int # The index of the queue where breakdown has occured 
end

struct RepairEvent <: Event 
    q::Int # The index of the queue where repair is occuring 
end 

###############################
###############################
# Network Parameters & State 
###############################
###############################
 
mutable struct QueueNetworkState <: State 
    jobs_num::Vector{Int} # Number of jobs in each queue, ordered. 
    params::NetworkParameters # Parameters of queue network system
end 

###################################################
###################################################
# Random Variables for arrivals, services 
# and breakdowns. 
###################################################
###################################################

# next_arrivival_duration RV for next arrival to the system externally 
# In this project we'll consider the durations of times between external arrivals to be exponentially distributed
next_arrival_duration(s::State, q::Int) = rand(Exponential(1/s.params.α_vector[q]))

# next_service_duration RV for next service of the system 
# As for the durations of service times we will set them as gamma distributed with a ratio of the variance and the mean squared 
next_service_duration(s::State, q::Int) = rand(rate_scv_gamma(s.params.μ_vector[q], s.params.c_s))

#next_breakdown_duration RV for next breakdown of queue in system 
# Specifically the server changes between on and off and back as follows: 
# on durations are exponentially distributed with mean γ₁^{-1} where γ₁>0
next_breakdown_duration(s::State, q::Int) = rand(Exponential(1/s.params.γ₁[q]))

#next_repair_duration RV for when servers are broken down.
#off durations are exponentially distributed with mean γ₁² where γ₂>0
next_repair_duration(s::State, q::Int) = rand(Exponential(1/s.params.γ₂[q]))


###############################
###############################
# PROCESSING EVENTS 
###############################
###############################

#Process end of simulation event 
function process_event(time::Float64, state::State, es_event::EndSimEvent)
    println("Ending simulation at time $time.")
    return []
end

#Process log state event
function process_event(time::Float64, state::State, ls_event::LogStateEvent)
    println("Logging state at time $time.")
    println(state)
    return []
end

#process arrival event (external to system)
function process_event(time::Float64, state::State, arrival_event::ExternalArrivalEvent)
    ### determine what queue job goes to 
    q = rand(1:state.params.L)
    ### add person to queue 
    state.jobs_num[q] += 1
    ### record a new timed event 
    new_timed_events = TimedEvent[]
    ### prepare next arrival 
    push!(new_timed_events, TimedEvent(ExternalArrivalEvent(), 
                                        time + next_arrival_duration(state, q)))
    ### if no one else in queue, start new service event 
    state.jobs_num[q] == 1 && push!(new_timed_events, 
                                        TimedEvent(EndOfServiceAtQueueEvent(q), 
                                            time + next_service_duration(state, q)))
    ### return events 
    return new_timed_events
    # few problems here. are we actually doing this properly. randomly have an arrival event, but randomly put them in a queue.
    # perhaps always need to initialise with L arrival events to get started. 
end

#process end of service event 
function process_event(time::Float64, state::State, eos_event::EndOfServiceAtQueueEvent)
    q = eos_event.q
    ### check if queue is broken down
    if breakdown_states[q] == false 
        ### remove the job from the queue
        state.jobs_num[q] -= 1
        @assert state.jobs_num[q] ≥ 0
        ### record a new timed event 
        new_timed_events = TimedEvent[]
        ### if another customer in queue, then start new service 
        if state.jobs_num[q] ≥ 1
            st = next_service_duration(state, q)
            push!(new_timed_events, TimedEvent(EndOfServiceAtQueueEvent(q), time + st)) 
        end
        ### transition matrix to work out which queue (or exit) job will go 
        # row of probabilities from transition matrix with probability of exiting system as additional probability
        trans_row = push!(state.params.P[q, :], 1 - sum(state.params.P[q, :]))
        trans_q = sample(1:state.params.L+1, Weights(trans_row)) #sample random probability from row
        ### if next q is in system, add job to new queue
        if trans_q < state.params.L+1
            state.jobs_num[trans_q] += 1
            ### if queue has no jobs, start service event (record new timed event)
            if state.jobs_num[trans_q] == 1
                push!(new_timed_events, TimedEvent(EndOfServiceAtQueueEvent(trans_q), time + next_service_duration(state, trans_q))) 
            end
        end 
        return new_timed_events
    end 
    # should we be returning something if server is broken down?
end 

#process a breakdown of a server 
function process_event(time::Float64, state::State, brk_event::BreakdownEvent)
    q = brk_event.q
    @assert breakdown_states[q] == false
    ### access global variable and make false 
    breakdown_states[q] = true 
    ### access queue where breakdown has occured 
    ### record a new timed event (REPAIR EVENT AFTER BROKEN DOWN)
    return TimedEvent(RepairEvent(q), time + next_repair_duration(state, q))
end

#process a repair of a server 
function process_event(time::Float64, state::State, rpr_event::RepairEvent)
    q = rpr_event.q
    @assert breakdown_states[q] == true  
    ### repair broken down server 
    breakdown_states[q] = false 
    ### record new timed event 
    return TimedEvent(BreakdownEvent(q), time + next_breakdown_duration(state, q))
end 

"""
Initial queue assignments for jobs to ensure simulation starts correctly.
"""
function process_event(time::Float64, state::State, ext_event::ExternalArrivalEventInitial)
    ### determine what queue job goes to 
    q = ext_event.q
    ### add person to queue 
    state.jobs_num[q] += 1
    ### record a new timed event 
    new_timed_events = TimedEvent[]
    ### prepare next arrival 
    push!(new_timed_events, TimedEvent(ExternalArrivalEvent(), 
                                        time + next_arrival_duration(state, q)))
    ### if no one else in queue, start new service event 
    push!(new_timed_events, TimedEvent(EndOfServiceAtQueueEvent(q), 
                                            time + next_service_duration(state, q)))
    ### return events 
    return new_timed_events
end 


#######################################
#######################################
# HELPER FUNCTIONS 
#######################################
#######################################
"""
A convenience function to make a Gamma distribution with desired rate (inverse of shape) and SCV.
"""
rate_scv_gamma(desired_rate::Float64, desired_scv::Float64) = Gamma(1/desired_scv, desired_scv/desired_rate)

"""
Compute the number of queues in the system 
"""
total_in_system(state::QueueNetworkState) = sum(state.queues)
