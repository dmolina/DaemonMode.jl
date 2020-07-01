using Pkg
Pkg.activate(".")
using Logging
using DaemonMode

logger = SimpleLogger(stdout, Logging.Error)

with_logger(logger) do
    DaemonMode.serve()
end
