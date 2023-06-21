using Picross

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
final_problem_state = Picross.solve(problem)
display(Picross.show_gui(problem, final_problem_state))
