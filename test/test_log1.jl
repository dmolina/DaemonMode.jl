using  Logging, LoggingExtras

function msg()
    @warn "warning 1\nanother line\nlast one"
    @error "error 1"
    @info "info 1"
    @debug "debug 1"
end

msg()

with_logger(FileLogger("salida.log")) do
    msg()
end
