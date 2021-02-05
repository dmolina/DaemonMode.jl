using  Logging, LoggingExtras

logger = MinLevelLogger(global_logger(), Logging.Debug)
logger = global_logger()

function msg()
    @warn "warning 2\nanother line\nlast one"
    @error "error 2"
    @info "info 2"
    @debug "debug 2"
end

with_logger(logger) do
    msg()
end

with_logger(FileLogger("salida.log")) do
    msg()
end
