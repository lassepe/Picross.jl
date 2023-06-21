module Picross

using GLMakie: GLMakie
using Makie: Makie
using Combinatorics: Combinatorics

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

# TODO
function is_valid(problem, problem_state)
    current_blocks = get_blocks_from_grid(problem_state.grid)
end

"""
Enumerate all possible ways to fill in the current line given the blocks.
"""
function get_possible_lines_from_blocks(blocks::Vector{Int}, line_length::Int)
    min_free_space = length(blocks) - 1
    free_space = line_length - sum(blocks)
    @assert(
        free_space >= min_free_space,
        """
        The blocks $(blocks) are too long for a line of length $(line_length).
        Need at least $(min_free_space),
        but only $(free_space) is left.
        """
    )
    # go over all possibilities of distributing the excess free space between the blocks
    # Note: +2 for virtual gaps in each end
    free_space_partitions = collect(Combinatorics.partitions(free_space + 2, length(blocks) + 1))
    gap_size_possibilities =
        unique(reduce(vcat, [Combinatorics.permutations(p) for p in free_space_partitions]))

    # at the extremes we can also have gaps of size zero (which we have accounted for through the offset of +2 above)
    for p in gap_size_possibilities
        p[begin] -= 1
        p[end] -= 1
    end

    # TODO: continue here -- generate all boolean lines
    map(gap_size_possibilities) do gap_size_possibility
        line = zeros(Bool, line_length)
        current_position = 1
        for (block, gap) in zip(blocks, gap_size_possibility)
            current_position += gap
            line[current_position:(current_position + block - 1)] .= true
            current_position += block
        end
        line
    end
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
        1 0 1
        0 1 1
        1 0 1
    ])
    display(show_gui(problem, problem_state))

    get_blocks_from_grid(problem_state.grid)
end

end # module Picross
