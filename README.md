# Picross.jl

A quick and dirty Julia implementation of a picross solver.

## Insall

Install [julia](https://julialang.org/downloads/). Then from the REPL run:

`] add https://github.com/lassepe/Picross.jl`

## Quick Start

```julia

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
Picross.show_state(problem, final_problem_state)
```
![image](https://github.com/lassepe/Picross.jl/assets/10076790/eb674a00-efec-4544-b710-9f79d38a9691)
