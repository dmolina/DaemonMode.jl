using CSV
using DataFrames

function main()
    df = CSV.File("7days.csv") |> DataFrame
    sal = reshape(df.total, nrow(df), 1)
    value = join(string.(sal), ", ")
    println(value)
    println(last(df, 5))
end

main()
