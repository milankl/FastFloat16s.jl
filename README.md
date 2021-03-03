# FastFloat16s.jl - Software-emulated Float16, but fast.

NOTE: THIS PACKAGE IS DEPRECATED FOR JULIA >=1.6 AS THE SUPPORT OF LLVM'S HALF FOR JULIA'S FLOAT16 IS SIMILARLY FAST.

FastFloat16s.jl emulates Float16 similar to Julia's inbuilt type, but stores them as
Float32 internally. Although 32-bit are therefore used for storing every FastFloat16
number, avoiding the recalculation of the exponent bits makes them about 20–30x faster.
Arithmetically, FastFloat16 is identical to Float16.

For all numbers larger equal subnormal on every arithmetic operation the significant
bits of Float32 are round to the nearest 10 significant bits. For Float16-subnormals
the precision of 10 bits is reduced every power of 2 down by 1 bit – to match the
IEEE standard. As FastFloat16s are essentially Float32 but always round to the nearest
Float16 in the subset of all Float32 no conversion of the exponent bits is needed
which makes them much faster.

As with Float16, FastFloat16 underflow below minpos/2 and overflow above floatmax.

## Benchmarking

`FastFloat16s.jl` is almost 20–30x faster than Julia's inbuilt `Float16` (but requires twice as much memory).

```julia
using FastFloat16s.jl, BenchmarkTools
A = Float16.(rand(1000,1000));
B = Float16.(rand(1000,1000));
Afast = FastFloat16.(rand(1000,1000));
Bfast = FastFloat16.(rand(1000,1000));

julia> @btime +($A,$B);
  16.556 ms (2 allocations: 1.91 MiB)

julia> @btime +($Afast,$Bfast);
  628.882 μs (2 allocations: 3.81 MiB)
```
and only slightly slower than Float32
```julia
julia> A = Float32.(rand(1000,1000));
julia> B = Float32.(rand(1000,1000));

julia> @btime +($A,$B);
  460.743 μs (2 allocations: 3.81 MiB)
```
