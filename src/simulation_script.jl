include("network_parameters.jl")

using DataStructures, Random, Distributions, StatsBase
import Base: isless

###################################################
###################################################
#   Structs for Events and States of the System 
###################################################
###################################################

# State and Event abstract (superclass) types
abstract type Event end
abstract type State end

# Captures an event and the time it takes place
struct TimedEvent
    event::Event
    time::Float64
end

# Event that ends the simulation
struct EndSimEvent <: Event end 

# Record when an event happens
struct LogStateEvent <: Event end 

# Initial external arrival event 
struct ExternalArrivalEvent <: Event 
    next_q::Int # Queue initial job is assigned to 
end
 
# End of service event 
mutable struct EndOfServiceAtQueueEvent <: Event
    q::Int # Queue where service finished
    next_q::Any # Queue where job moves after service. nothing if job leaves system.
end

# Breakdown event 
struct BreakdownEvent <: Event 
    q::Int # Queue where breakdown has occured 
end

# Repair event 
struct RepairEvent <: Event 
    q::Int # Queue where repair is occuring 
end 

###################################################
###################################################
#         Network Parameters & State 
###################################################
###################################################
 
mutable struct QueueNetworkState <: State 
    jobs_num::Vector{Int} # Number of jobs in each queue, ordered. 
    params::NetworkParameters # Parameters of queue network system
end 

###################################################
###################################################
#      Random Variables for arrivals, services 
#                  and breakdowns. 
###################################################
###################################################

"""
A function, acting as a RV, for the external arrivals to the system.

The duration of times between external arrivals are exponentially distributed, 
with rate parameters, αᵢ, given as parameters of the network system.
"""
next_arrival_duration(s::State, q::Int) = rand(Exponential(1/s.params.α_vector[q]))

"""
A function, acting as a RV, for the service rates of the system.

The service rates are gamma distributed with a ratio of the variance and the mean squared 
(squared coefficient of variation) which is c_s parameter. Rate parameters, μᵢ, given as
paramters of the network system.
"""
next_service_duration(s::State, q::Int) = rand(rate_scv_gamma(s.params.μ_vector[q], s.params.c_s))

"""
A function, acting as a RV, for breakdowns in the system.

Breakdowns occur independently of jobs in the system and independent of servers.
Breakdown are exponentially distributed with rate γ₁, which is given as a parameter
of the network system.
"""
next_breakdown_duration(s::State, q::Int) = rand(Exponential(1/s.params.γ₁[q]))

"""
A function, acting as a RV, for reparis of breakdowns in the system.

Repairs of breakdowns are exponentially distributed with rate γ₂, 
which is given as a parameter of the network system.
"""
next_repair_duration(s::State, q::Int) = rand(Exponential(1/s.params.γ₂[q]))


###################################################
###################################################
#              PROCESSING EVENTS 
###################################################
###################################################

# This is an abstract function 
"""
It will generally be called as 
       new_timed_events = process_event(time, state, event)
It will generate 0 or more new timed events based on the current event
"""
function process_event end

"""
Process end of simulation event.
"""
function process_event(time::Float64, state::State, es_event::EndSimEvent)
    println("Ending simulation at time $time.")
    return []
end

"""
Process log time event.
"""
function process_event(time::Float64, state::State, ls_event::LogStateEvent)
    println("Logging state at time $time.")
    println(state)
    return []
end

"""
Process external arrival events that occur initially in the system.
"""
function process_event(time::Float64, state::State, ext_event::ExternalArrivalEvent) 
    q = ext_event.next_q # Queue where job is added 
    state.jobs_num[q] += 1 # Add job to queue 
    new_timed_events = TimedEvent[] # Record a new timed event 
    # Prepare for next arrival
    push!(new_timed_events, TimedEvent(ExternalArrivalEvent(q), 
                                        time + next_arrival_duration(state, q)))
    # Start new service event, since this will always be first job in queue 
    # If this job is only job in queue then start new service event 
     state.jobs_num[q] == 1 && push!(new_timed_events, TimedEvent(EndOfServiceAtQueueEvent(q, nothing), 
                                                    time + next_service_duration(state, q)))
    return new_timed_events
end 

#=
"""
Process an external arrival event.
"""
function process_event(time::Float64, state::State, arrival_event::ExternalArrivalEvent)
    q = rand(1:state.params.L) # Job is assigned to "random" queue
    arrival_event.next_q = q # Set field
    state.jobs_num[q] += 1 # Add job to queue 
    new_timed_events = TimedEvent[] # Record a new timed event
    # Prepare next arrival
    push!(new_timed_events, TimedEvent(ExternalArrivalEvent(nothing), 
                                        time + next_arrival_duration(state, q)))
    # If this job is only job in queue then start new service event 
    state.jobs_num[q] == 1 && push!(new_timed_events, 
                                        TimedEvent(EndOfServiceAtQueueEvent(q, nothing), 
                                            time + next_service_duration(state, q)))
    return new_timed_events
end
=#

"""
Process an end of service event.
"""
function process_event(time::Float64, state::State, eos_event::EndOfServiceAtQueueEvent)
    q = eos_event.q # Queue where service has occured
    if breakdown_states[q] == false # Proceed only if server is not broken down
        state.jobs_num[q] -= 1 # Remove this job from the queue 
        @assert state.jobs_num[q] ≥ 0 
        new_timed_events = TimedEvent[] # Record a new timed event 

        # If another job is in queue then start new service 
        if state.jobs_num[q] ≥ 1
            st = next_service_duration(state, q)
            push!(new_timed_events, TimedEvent(EndOfServiceAtQueueEvent(q, nothing), time + st)) 
        end

        # Routing matrix, P, determines where job will go after service
        # Probability of exiting system included and assigned to "L+1'th" node 
        trans_row = push!(state.params.P[q, :], 1 - sum(state.params.P[q, :])) 
        # Sample from above, trans_q denotes queue job moves to (or exits system)
        trans_q = sample(1:state.params.L+1, Weights(trans_row)) 
        # If trans_q is in system, proceed by adding job to the queue
        if trans_q < state.params.L+1
            state.jobs_num[trans_q] += 1 # Add job to queue
            eos_event.next_q = trans_q # Set field
            # If this job is only job in queue then start new service event
            if state.jobs_num[trans_q] == 1
                # Record this new timed event
                push!(new_timed_events, TimedEvent(EndOfServiceAtQueueEvent(trans_q, nothing), 
                                            time + next_service_duration(state, trans_q))) 
            end
        end 
        return new_timed_events
    end 
end 

"""
Process a breakdown event.
"""
function process_event(time::Float64, state::State, brk_event::BreakdownEvent)
    q = brk_event.q # Queue where breakdown event occurs
    @assert breakdown_states[q] == false # Ensure server is not already broken down
    breakdown_states[q] = true # Server becomes broken down
    # Prepare for next repair event
    return TimedEvent(RepairEvent(q), time + next_repair_duration(state, q))
end

"""
Process a repair event.
"""
function process_event(time::Float64, state::State, rpr_event::RepairEvent)
    q = rpr_event.q # Queue where breakdown event occurs 
    @assert breakdown_states[q] == true # Ensure server is broken down
    breakdown_states[q] = false # Repair broken down server 
    # Prepare for next breakdown event 
    return TimedEvent(BreakdownEvent(q), time + next_breakdown_duration(state, q))
end 


###################################################
###################################################
#                HELPER FUNCTIONS 
###################################################
###################################################
"""
A convenience function to make a Gamma distribution with desired rate (inverse of shape) and SCV.
"""
rate_scv_gamma(desired_rate::Float64, desired_scv::Float64) = Gamma(1/desired_scv, desired_scv/desired_rate)

"""
Compute the number of queues in the system 
"""
total_in_system(state::QueueNetworkState) = sum(state.queues)

# Comparison of two timed events - this will allow us to use them in a heap/priority-queue
isless(te1::TimedEvent, te2::TimedEvent) = te1.time < te2.time

