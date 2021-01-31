# FastFloat16s.jl - Software-emulated Float16, but fast.

FastFloat16s.jl emulates Float16 similar to Julia's imbuilt type, but stores them as
Float32 internally. Although 32-bit are therefore used for storing every FastFloat16
number, avoiding the recalculation of the exponent bits makes them about 40x faster.

## Benchmarking

`FastFloat16s.jl` is almost 40x faster than Julia's imbuilt `Float16` (but requires twice as much memory)

```julia
using FastFloat16s.jl, BenchmarkTools
A = Float16.(rand(1000,1000));
B = Float16.(rand(1000,1000));
Afast = FastFloat16.(rand(1000,1000));
Bfast = FastFloat16.(rand(1000,1000));

julia> @btime +($A,$B);
  16.556 ms (2 allocations: 1.91 MiB)

julia> @btime +($Afast,$Bfast);
  435.845 μs (2 allocations: 3.81 MiB)
```
