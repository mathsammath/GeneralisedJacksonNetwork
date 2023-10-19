#############################################################
#############################################################
#
# This is the main project file for polynomial factorization
#                                                                               
#############################################################
#############################################################

using Parameters, Accessors, LinearAlgebra, Random, DataStructures, Random, Distributions, StatsBase, DataFrames
using Plots  
import Base: isless

include("src/network_parameters.jl")
include("src/computation.jl")
include("src/network_parameters.jl")
include("src/jackson_network.jl")
include("src/simulation_engine.jl")
include("src/task_four.jl")

include("test/test_one.jl")
include("test/test_two.jl")
include("test/test_three.jl")
include("test/test_four.jl")