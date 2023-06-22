module Picross

using Combinatorics: Combinatorics
using ImageInTerminal: ImageInTerminal
using Images: Gray, colorview, load, imresize
using SparseArrays: spzeros

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

function get_problem_from_image(image::AbstractMatrix)
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
    free_space_partitions = Combinatorics.partitions(free_space + 2, length(blocks) + 1)
    gap_size_possibilities = Set{Vector{Int}}()
    for p in free_space_partitions
        for c in Combinatorics.permutations(p)
            # at the extremes we can also have gaps of size zero (which we have accounted for through the offset of +2 above)
            c[begin] -= 1
            c[end] -= 1
            push!(gap_size_possibilities, c)
        end
    end

    line_options = Set{Vector{Bool}}()

    for gap_size_possibility in gap_size_possibilities
        line = spzeros(Bool, line_length)
        current_position = 1
        for (block, gap) in zip(blocks, gap_size_possibility)
            current_position += gap
            line[current_position:(current_position + block - 1)] .= true
            current_position += block
        end
        push!(line_options, line)
    end

    line_options
end

function prune_options!(options::Set{Vector{Bool}}, current_state::Vector{Int})
    filter!(options) do option
        all(zip(option, current_state)) do (option, state)
            state == -1 || option == state
        end
    end
end

function intersect_line_options(options::Set{Vector{Bool}})
    fills = reduce(.&, options)
    crosses = reduce(.&, (map(!, o) for o in options))
    (; fills, crosses)
end

# TODO: continue here -- get those fields for which we have a unique intersection
function solve(problem::Problem; verbose = false, maximum_number_of_iterations = 1000)
    # 1. generate the internal solver state
    solver_state = fill(-1, length(problem.row_blocks), length(problem.column_blocks))
    # 2. derive the initial options for each row and column
    verbose && @info "Generating initial row options"
    row_options = Dict(
        map(
            ((ii, blocks),) ->
                ii => get_possible_lines_from_blocks(blocks, length(problem.column_blocks)),
            enumerate(problem.row_blocks),
        ),
    )

    verbose && @info "Generating initial column options"
    column_options = Dict(
        map(
            ((jj, blocks),) ->
                jj => get_possible_lines_from_blocks(blocks, length(problem.row_blocks)),
            enumerate(problem.column_blocks),
        ),
    )

    open_rows = Set(keys(row_options))
    open_columns = Set(keys(column_options))

    # 3. iterate over rows and columns and push conclusions to internal state
    iteration = 0
    while !isempty(open_rows) || !isempty(open_columns)
        if !isempty(open_rows)
            ii = pop!(open_rows)
            prune_options!(row_options[ii], solver_state[ii, :])
            if isempty(row_options[ii])
                @info "Row options are empty. Problem not solvable"
                return nothing
            end
            fills, crosses = intersect_line_options(row_options[ii])
            updated = (fills .| crosses) .& (solver_state[ii, :] .< 0)
            union!(open_columns, findall(updated))
            solver_state[ii, fills] .= 1
            solver_state[ii, crosses] .= 0
        end
        if !isempty(open_columns)
            jj = pop!(open_columns)
            prune_options!(column_options[jj], solver_state[:, jj])
            if isempty(column_options[jj])
                @info "Column options are empty. Problem not solvable"
                return nothing
            end
            fills, crosses = intersect_line_options(column_options[jj])
            updated = (fills .| crosses) .& (solver_state[:, jj] .< 0)
            union!(open_rows, findall(updated))
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
            display(colorview(Gray, Matrix{Float64}(solver_state)))
        end
    end

    if any(<(0), solver_state)
        @info "Some fields are still undecided but there are no open rows or columns. Problem not sequentially solvable."
        return nothing
    end

    ProblemState(Matrix{Bool}(solver_state))
end

function show_state(state::ProblemState)
    colorview(Gray, state.grid)
end

    figure
end

end # module Picross
