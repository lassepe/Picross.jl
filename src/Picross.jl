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
    figure, axis, heatmap = Makie.heatmap(
        problem_state.grid'[:, end:-1:begin];
        axis = (;
            aspect = Makie.DataAspect(),
            xticks = 0.5:1:(length(problem.row_blocks) + 0.5),
            yticks = 0.5:1:(length(problem.column_blocks) + 0.5),
            xgridwidth = 5,
            ygridwidth = 5,
            xgridcolor = :black,
            ygridcolor = :black,
        ),
    )
    Makie.translate!(heatmap, 0, 0, -100)

    figure
end

function main()
    problem = Problem([3, 3, 3], [3, 3, 3])
    problem_state = ProblemState([
        1 0 1
        0 0 1
        0 0 1
    ])
    show_gui(problem, problem_state)
end

end # module Picross
