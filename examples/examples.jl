function main()
    image = load("/home/lassepe/Downloads/test.jpg")
    image_scaled = imedge(imresize(image; ratio = 0.05))[3]
    image_bw = [Gray(p) > 0.25 for p in image_scaled]
    @show size(image_bw)
    colorview(Gray, image_bw) |> display
    problem = get_problem_from_image(image_bw)
    solution = solve(problem; verbose = true)
end

function elephant()
    problem = Picross.Problem(;
        row_blocks = [
            [4],
            [1, 4],
            [1, 2],
            [1, 1, 1],
            [1, 1, 1, 1],
            [1, 1, 2],
            [1, 1, 2],
            [1, 4],
            [1, 1, 2, 1],
            [1, 1, 2, 1],
        ],
        column_blocks = [
            [8],
            [1],
            [1, 1, 2],
            [1, 1],
            [1, 7],
            [1, 3],
            [1, 2],
            [1, 1],
            [2, 1],
            [5, 2],
        ],
    )
    final_problem_state = Picross.solve(problem; verbose = true)
    show_state(final_problem_state)
end

function p60()
    problem = Picross.Problem(;
        row_blocks = [
            [3, 2],
            [1, 1, 1, 2],
            [2, 2, 1],
            [1, 2, 1],
            [2, 3],
            [1, 1, 1, 1],
            [4, 1, 1],
            [1, 2],
            [1, 1],
            [2, 1, 2],
        ],
        column_blocks = [
            [1, 2],
            [1, 1, 1],
            [3, 2, 1],
            [1, 1, 1, 1],
            [3, 2, 1, 1],
            [1, 2, 1],
            [1, 1, 1],
            [1, 1, 3],
            [1, 2, 1, 1],
            [1, 1, 2],
        ],
    )
    final_problem_state = Picross.solve(problem; verbose = true)

    println("Final state:")
    show_state(final_problem_state)
end
