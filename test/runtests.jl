using FastFloat16s
using Test

@testset "Conversions" begin
    for ui in 0x0000:0x7bff
        f1 = reinterpret(Float16,ui)
        @test f1 == Float16(FastFloat16(f1))
    end

    N = 1_000_000
    for _ in 1:N
        f = Float32(randn())
        @test Float32(Float16(f)) == Float32(FastFloat16(f))
    end
end

@testset "Subnormals" begin
    N = 1_000_000
    for _ in 1:N
        f = reinterpret(Float32,rand(0x33800000:0x38800000))
        @test Float32(Float16(f)) == Float32(FastFloat16(f))
    end
end

@testset "Arithmetics" begin
    N = 1_000

    for _ in 1:N
        ui1 = rand(0x0000:0x7bff)
        ui2 = rand(0x0000:0x7bff)

        f1 = reinterpret(Float16,ui1)
        f2 = reinterpret(Float16,ui2)

        @test f1*f2 == Float16(FastFloat16(f1)*FastFloat16(f2))
        @test f1+f2 == Float16(FastFloat16(f1)+FastFloat16(f2))
        @test f1-f2 == Float16(FastFloat16(f1)-FastFloat16(f2))
        @test f1/f2 == Float16(FastFloat16(f1)/FastFloat16(f2))

        if f1*f2 != Float16(FastFloat16(f1)*FastFloat16(f2))
            println("$f1,$f2")
        end
    end
end

# was only used for development
# function bittest(x::Float32)
#     s = bitstring(x)
#     println("Float32 full: "*s[1]*" "*s[2:9]*" "*s[10:19]*" "*s[20:end])
#     s = bitstring(FastFloat16(x),:split)
#     println("FFloat16  is: "*s[1:21]*" "*s[22:end])
#     s = bitstring(Float32(Float16(x)))
#     println("Float32 redu: "*s[1]*" "*s[2:9]*" "*s[10:19]*" "*s[20:end])
#     s = bitstring(Float16(x))
#     println("Float16 prec: "*s[1]*"    "*s[2:6]*" "*s[7:end])
# end