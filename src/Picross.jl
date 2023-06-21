module Picross

using GLMakie: GLMakie
using Makie: Makie

struct Problem
    row_blocks::Vector{Vector{Int}}
    column_blocks::Vector{Vector{Int}}
end

struct ProblemState
    grid::Matrix{Bool}
end

function get_blocks_from_line(line::AbstractVector{Bool})
    blocks = Int[]
    last_block_position = -2

    for position in eachindex(line)
        block_is_colored = line[position]
        if block_is_colored
            position_is_next_to_last_block = position == last_block_position + 1
            if position_is_next_to_last_block
                blocks[end] += 1
            else
                push!(blocks, 1)
            end
            last_block_position = position
        end
    end

    blocks
end

function get_blocks_from_grid(grid::AbstractMatrix{Bool})
    row_blocks = map(get_blocks_from_line, eachrow(grid))
    column_blocks = map(get_blocks_from_line, eachcol(grid))

    (; row_blocks, column_blocks)
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
    problem = Problem([[3], [3], [3]], [[3], [3], [3]])
    problem_state = ProblemState([
        1 1 1
        0 1 1
        1 0 1
    ])
    display(show_gui(problem, problem_state))

    get_blocks_from_grid(problem_state.grid)
end

end # module Picross
