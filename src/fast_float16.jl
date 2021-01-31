import Base: Float64, Float32, Float16, Int

primitive type FastFloat16 <: AbstractFloat 32 end

# conversions
Base.Float32(x::FastFloat16) = reinterpret(Float32,x)
function FastFloat16(x::Float32)
    # round to 10 significant bits
    ui = reinterpret(UInt32,x)
    ui += 0x0000_0fff + ((ui >> 13) & 0x0000_0001)
    ui &= 0xffff_e000           # set bits 20-32 to 0

    # check for overflow/underflow
    sign = ui & 0x8000_0000     # separate the sign bit
    ui = ui & 0x7fff_ffff       # from the exp&significant bits
    ui = ui < 0x3380_0000 ? 0x0000_0000 : ui   # underflow? replace with 0
    ui = ui > 0x477f_e000 ? 0x7f80_0000 : ui   # overflow? repalce with Inf32

    # recombine sign&exp&significant
    return reinterpret(FastFloat16,sign | ui)
end

# conversion between FastFloatt16 and various floats
Float64(x::FastFloat16) = Float64(Float32(x))
Float16(x::FastFloat16) = Float16(Float32(x))
FastFloat16(x::Float64) = FastFloat16(Float32(x))
FastFloat16(x::Float16) = FastFloat16(Float32(x))
Int(x::FastFloat16) = Int(Float32(x))
FastFloat16(x::Int) = FastFloat16(Float32(x))

Base.iszero(x::FastFloat16) = iszero(Float32(x))
Base.isnan(x::FastFloat16) = isnan(Float32(x))
Base.signbit(x::FastFloat16) = signbit(Float32(x))

Base.zero(::Type{FastFloat16}) = reinterpret(FastFloat16,0x0000_0000)
Base.one(::Type{FastFloat16}) = reinterpret(FastFloat16,0x3f80_0000)

Base.floatmin(::Type{FastFloat16}) = reinterpret(FastFloat16,0x3880_0000)   # = Float32(floatmin(Float16))
Base.floatmax(::Type{FastFloat16}) = reinterpret(FastFloat16,0x477f_e000)   # = Float32(floatmax(Float16))

# In the absence of -Inf,Inf define typemin,typemax as floatmin,floatmax
Base.typemin(::Type{FastFloat16}) = reinterpret(FastFloat16,0xff800000)     # = Float32(typemin(Float16))    
Base.typemax(::Type{FastFloat16}) = reinterpret(FastFloat16,0x7f800000)     # = Float32(typemax(Float16))

Base.:(-)(x::FastFloat16) = FastFloat16(-Float32(x))
Base.inv(x::FastFloat16) = FastFloat16(inv(Float32(x)))

# Arithmetics
Base.:(*)(x::FastFloat16,y::FastFloat16) = FastFloat16(Float32(x)*Float32(y))
Base.:(/)(x::FastFloat16,y::FastFloat16) = FastFloat16(Float32(x)/Float32(y))
Base.:(+)(x::FastFloat16,y::FastFloat16) = FastFloat16(Float32(x)+Float32(y))
Base.:(-)(x::FastFloat16,y::FastFloat16) = FastFloat16(Float32(x)-Float32(y))
Base.sqrt(x::FastFloat16) = FastFloat16(sqrt(Float32(x)))

Base.round(x::FastFloat16, r::RoundingMode{:Up}) = Int(ceil(Float32(x)))
Base.round(x::FastFloat16, r::RoundingMode{:Down}) = Int(floor(Float32(x)))
Base.round(x::FastFloat16, r::RoundingMode{:Nearest}) = Int(round(Float32(x)))

for t in (Int8, Int16, Int32, Int64, Int128, UInt8, UInt16, UInt32, UInt64, UInt128)
	@eval Base.promote_rule(::Type{FastFloat16}, ::Type{$t}) = FastFloat16
end

Base.nextfloat(x::FastFloat16) = FastFloat16(nextfloat(Float16(x)))
Base.nextfloat(x::FastFloat16,n::Int) = FastFloat16(nextfloat(Float16(x),n))
Base.prevfloat(x::FastFloat16) = FastFloat16(prevfloat(Float16(x)))
Base.prevfloat(x::FastFloat16,n::Int) = FastFloat16(prevfloat(Float16(x),n))

Base.log2(x::FastFloat16) = FastFloat16(log2(Float32(x)))
Base.log(x::FastFloat16) = FastFloat16(log(Float32(x)))

Base.:(==)(x::FastFloat16,y::FastFloat16) = Float32(x) == Float32(y)
Base.:(>)(x::FastFloat16,y::FastFloat16) = Float32(x) > Float32(y)
Base.:(<)(x::FastFloat16,y::FastFloat16) = Float32(x) < Float32(y)
Base.:(<=)(x::FastFloat16,y::FastFloat16) = Float32(x) <= Float32(y)


# Showing
function Base.show(io::IO, x::FastFloat16)
    io2 = IOBuffer()
    print(io2,Float16(x))
    f = String(take!(io2))
    print(io,"FastFloat16("*f*")")
end

Base.bitstring(x::FastFloat16) = bitstring(Float32(x))

function Base.bitstring(x::FastFloat16,mode::Symbol)
    if mode == :split	# split into sign, integer, fraction
        s = bitstring(x)
		return "$(s[1]) $(s[2:9]) $(s[10:end])"
    else
        return bitstring(x)
    end
end
