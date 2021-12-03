using Suppressor

function main()
    programs = ["hello", "slow", "long", "DS"] .* ".jl"

    for program in programs
        output = @capture_err run(`time julia $program`)
        @show output
        break
    end
end

main()
