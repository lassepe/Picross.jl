module Picross

using GLMakie: GLMakie
using Makie: Makie

struct Problem
    row_blocks::Vector{Int}
    column_blocks::Vector{Int}
end

struct ProblemState
    grid::Matrix{Int}
end

function show_gui(problem::Problem, problem_state::ProblemState)
    @assert length(problem.row_blocks) == size(problem_state.grid, 1)
    @assert length(problem.column_blocks) == size(problem_state.grid, 2)
    Makie.heatmap(problem_state.grid; axis=(; aspect=1))
end

function main()
    problem = Problem([3, 3, 3], [3, 3, 3])
    problem_state = ProblemState(
        [0 1 0
            1 0 0
            0 0 1])
    show_gui(problem, problem_state)
end

end # module Picross
