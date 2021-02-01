import Base: Float64, Float32, Float16, Int

primitive type FastFloat16 <: AbstractFloat 32 end

# CONVERSIONS
# helper functions to create correct shift & set/shavemasks
shift(n::UInt32) = 13 + n                   # for subnormals n > 0 to decrease precision
mask(n::UInt32) = 0x003f_ffff >> (0xa-n)    # same: mask more significant bits

# conversion FastFloat16 -> Float32 is just reinterpretation
Base.Float32(x::FastFloat16) = reinterpret(Float32,x)

# conversion Float32 -> via rounding & over/underflow cap
function FastFloat16(x::Float32)
    ui = reinterpret(UInt32,x)
    sign = ui & 0x8000_0000     # separate the sign bit
    ui = ui & 0x7fff_ffff       # from the exp&significant bits

    # check for Float16-subnormals: subnormal sn = ui < 0x3880_0000
    scale = 0x71 - (ui >> 23)           # 0 for sn, 1 for sn/2, 2 for sn/4 etc.
    # for x>=subnormal mask&shift operators are constant, for subnormals the
    # precision is decreased by 1 bit for every power 2
    maskbits,shiftbits = scale < 0xb ?  # = subnormal? yes: get variable mask&shift, no: constant
        (mask(scale), shift(scale)) : (0x0000_0fff, 13)

    # round to nearest (retain 10 sigbits for >subnormal, less for subnormals)
    ui += maskbits + ((ui >> shiftbits) & 0x0000_0001)  # take carry over into account
    ui &= (~maskbits) << 1          # set the non-Float16 sigbits to 0

    # check for overflow/underflow
    # underflow = ui smaller than minpos/2 = Float32(nextfloat(Float16(0)))/2
    ui = ui < 0x3300_0000 ? 0x0000_0000 : ui   # then replace with 0
    ui = ui > 0x477f_e000 ? 0x7f80_0000 : ui   # overflow? replace with Inf32

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