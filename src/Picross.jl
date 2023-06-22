module Picross

using Combinatorics: Combinatorics
using ImageInTerminal: ImageInTerminal
using Images: Gray, colorview, load, imresize, imedge
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

function prune_options!(options::Set{Vector{Bool}}, current_state::AbstractVector{Int})
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
    line_options = Dict{Tuple{Symbol,Int},Set{Vector{Bool}}}()
    verbose && @info "Generating initial row options"
    merge!(
        line_options,
        Dict([
            (:row, ii) => get_possible_lines_from_blocks(blocks, length(problem.column_blocks)) for
            (ii, blocks) in enumerate(problem.row_blocks)
        ]),
    )
    verbose && @info "Generating initial column options"
    merge!(
        line_options,
        Dict([
            (:column, jj) => get_possible_lines_from_blocks(blocks, length(problem.row_blocks)) for
            (jj, blocks) in enumerate(problem.column_blocks)
        ]),
    )
    # 3. maintain a set of rows/columns that we still need to process
    open_set = Set(keys(line_options))

    # 4. iterate over open rows/columns
    iteration = 0
    while !isempty(open_set)
        k = (line_type, ii) = pop!(open_set)
        line_state = @views line_type === :row ? solver_state[ii, :] : solver_state[:, ii]
        # 4.1. prune all options that are not compatible with the current state
        prune_options!(line_options[k], line_state)
        if isempty(line_options[k])
            @info "Row options are empty. Problem not solvable"
            return nothing
        end
        # 4.2. draw new conclusions
        fills, crosses = intersect_line_options(line_options[k])
        updated = (fills .| crosses) .& (line_state .< 0)
        line_state[fills] .= 1
        line_state[crosses] .= 0

        # 4.3 trigger updates for all affected rows/columns
        new_indices = findall(updated)
        new_line_type = line_type === :row ? :column : :row
        union!(open_set, tuple.(new_line_type, new_indices))

        iteration += 1
        if iteration > maximum_number_of_iterations
            @info "Too many iterations. Giving up"
            return nothing
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
