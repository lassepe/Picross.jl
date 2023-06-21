module Picross

using GLMakie: GLMakie
using Makie: Makie
using Combinatorics: Combinatorics
using ImageInTerminal: ImageInTerminal
using Images: Gray, colorview

Base.@kwdef struct Problem
    row_blocks::Vector{Vector{Int}}
    column_blocks::Vector{Vector{Int}}
end

struct ProblemState
    grid::Matrix{Bool}
end

function get_blocks_from_line(line::AbstractVector)
    blocks = Int[]
    last_block_position = -2

    for position in eachindex(line)
        block_is_colored = line[position] > 0
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

function get_problem_description_from_image(image::AbstractMatrix)
    row_blocks = map(get_blocks_from_line, eachrow(image))
    column_blocks = map(get_blocks_from_line, eachcol(image))
    Problem(; row_blocks, column_blocks)
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
    gap_size_possibilities = unique(
        reduce(vcat, [collect(Combinatorics.permutations(p)) for p in free_space_partitions]),
    )

    # at the extremes we can also have gaps of size zero (which we have accounted for through the offset of +2 above)
    for p in gap_size_possibilities
        p[begin] -= 1
        p[end] -= 1
    end

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

function prune_options(options::Vector{Vector{Bool}}, current_state::Vector{Int})
    filter(options) do option
        all(zip(option, current_state)) do (option, state)
            state == -1 || option == state
        end
    end
end

function intersect_line_options(options::Vector{Vector{Bool}})
    fills = reduce(.&, options)
    crosses = reduce(.&, (map(!, o) for o in options))
    (; fills, crosses)
end

# TODO: continue here -- get those fields for which we have a unique intersection
function solve(problem::Problem; verbose = false, maximum_number_of_iterations = 1000)
    # 1. generate the internal solver state
    solver_state = fill(-1, length(problem.row_blocks), length(problem.column_blocks))
    # 2. derive the initial options for each row and column
    row_options = map(
        blocks -> get_possible_lines_from_blocks(blocks, length(problem.column_blocks)),
        problem.row_blocks,
    )
    column_options = map(
        blocks -> get_possible_lines_from_blocks(blocks, length(problem.row_blocks)),
        problem.column_blocks,
    )
    # 3. iterate over rows and columns and push conclusions to internal state
    iteration = 0
    while any(∉([0, 1]), solver_state)
        # rows...
        for (ii, row_options_ii) in enumerate(row_options)
            pruned_row_options = prune_options(row_options_ii, solver_state[ii, :])
            if isempty(pruned_row_options)
                @info "Pruned options are empty. Problem not solvable"
                return false
            end
            fills, crosses = intersect_line_options(pruned_row_options)
            solver_state[ii, fills] .= 1
            solver_state[ii, crosses] .= 0
        end
        # columns...
        for (jj, column_options_jj) in enumerate(column_options)
            pruned_column_options = prune_options(column_options_jj, solver_state[:, jj])
            if isempty(pruned_column_options)
                @info "Pruned options are empty. Problem not solvable"
                return false
            end
            fills, crosses = intersect_line_options(pruned_column_options)
            solver_state[fills, jj] .= 1
            solver_state[crosses, jj] .= 0
        end
        iteration += 1
        if iteration > maximum_number_of_iterations
            @info "Too many iterations. Giving up"
            return false
        end
        if verbose
            @info "Iteration $(iteration)"
            colorview(Gray, Matrix{Float64}(solver_state)) |> display
        end
    end
    ProblemState(Matrix{Bool}(solver_state))
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

end # module Picross
