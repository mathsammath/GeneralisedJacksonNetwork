using DataStructures, Random, Distributions
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

struct ExternalArrivalEvent <: Event 
    q::Int # The index of the queue where job goes
end 
 
struct EndOfServiceAtQueueEvent <: Event
    q::Int # The index of the queue where service finished
end

struct BreakdownEvent <: Event 
    q::Int # The index of the queue where breakdown has occured 
end
###############################
###############################
# Network Parameters & State 
###############################
###############################

struct QueueNetworkParameters
    num_queues::Int # The number of queues in our system 
    α_rates::Vector{Any} # External arrival rates (αᵢ's) for queues as an ordered vector
    μ_rates::Vector{Any} # Service rates (μᵢ's) as an ordered vector
    γ_rates::Vector{Any} # On and off paramters 
    scv_arr::Vector{Any} # Squared coefficient of variation of the service processes
end

mutable struct QueueNetworkState <: State 
    jobs_num::Vector{Int} # Number of jobs in each queue, ordered. 
    params::QueueNetworkParameterse # Parameters of queue network system
end 

###################################################
###################################################
# Random Variables for arrivals, services 
# and breakdowns. 
###################################################
###################################################

# next_arrivival_duration RV for next arrival to the system externally 
# In this project we'll consider the durations of times between external arrivals to be exponentially distributed
next_arrival_duration(s::State, q::Int) = rand(Exponential(1/s.params.α_rates[q]))

# next_service_duration RV for next service of the system 
# As for the durations of service times we will set them as gamma distributed with a ratio of the variance and the mean squared 
next_service_duration(s::State, q::Int) = rand(rate_scv_gamma(s.params.μ_rates[q], s.params.scv_arr[q]))

#next_breakdown_duration RV for next breakdown of queue in system 
# Specifically the server changes between on and off and back as follows: 
# on durations are exponentially distributed with mean γ₁^{-1} where γ₁>0
next_breakdown_duration(s::State, q::Int) = rand(Exponential(1/s.params.γ_rates[q]))

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
    ### access trans matrix to work out which queue we add to 
    ### add person to queue 
    ### record a new timed event 
    ### prepare next arrival 
    ### something specific -> engage server if first job? 
end

#process end of service event 
function process_event(time::Float64, state::State, eos_event::EndOfServiceAtQueueEvent)
    ### access queue where service has occured 
    ### record a new timed event 
    ### remove the job from the queue
    ### if another customer in queue, then start new service 
    
    ### transition matrix to work out which queue (or exit) job will go 
    ### add job to new queue 
    ###     if queue has no jobs, start service event (record new timed event)
    ###     else add to end of queue (record new timed event)
end 

#process a breakdown of a server 
function process_event(time::Float64, state::State, brk_event::BreakdownEvent)
    ### access queue where breakdown has occured 
    ### record a new timed event 
    ### within queue where breakdown has occured, pause serving ????
    ### record time for server to come back online???
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

# Total number of jobs in the system (necessary???)
total_in_system(state::TandemQueueNetworkState) = sum(state.queues)