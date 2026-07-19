# Extract and plot selected observables from a GROMACS full.edr file.
#
# Run this script in the directory containing full.edr:
#   Rscript plot_full_edr.R
#
# Requirements:
# - GROMACS available as "gmx" or "gmx_mpi"
# - base R only; no additional R packages are required

edr_file <- "full.edr"

terms <- list(
  Potential = list(
    title = "Potential energy",
    y_label = "Potential energy (kJ/mol)",
    file_stub = "potential"
  ),
  Temperature = list(
    title = "Temperature",
    y_label = "Temperature (K)",
    file_stub = "temperature"
  ),
  Pressure = list(
    title = "Pressure",
    y_label = "Pressure (bar)",
    file_stub = "pressure"
  ),
  Density = list(
    title = "Density",
    y_label = expression(paste("Density (kg/", m^3, ")")),
    file_stub = "density"
  ),
  Volume = list(
    title = "Volume",
    y_label = expression(paste("Volume (", nm^3, ")")),
    file_stub = "volume"
  )
)

# Output folders
xvg_dir <- "full_energy_xvg"
plot_dir <- "full_energy_plots"
stats_dir <- "full_energy_stats"

dir.create(xvg_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(plot_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(stats_dir, showWarnings = FALSE, recursive = TRUE)

# Check input file
if (!file.exists(edr_file)) {
  stop(
    "The file '", edr_file,
    "' was not found. Run the script in the directory containing full.edr."
  )
}

# Find the GROMACS executable
gmx_candidates <- c(
  unname(Sys.which("gmx")),
  unname(Sys.which("gmx_mpi"))
)

gmx_candidates <- gmx_candidates[nzchar(gmx_candidates)]

if (length(gmx_candidates) == 0) {
  stop(
    "GROMACS was not found in PATH. ",
    "Activate/source your GROMACS installation and try again."
  )
}

gmx_command <- gmx_candidates[1]
message("Using GROMACS executable: ", gmx_command)

# Read a plain or Grace-formatted XVG file
read_xvg_numeric <- function(file_path) {
  lines <- readLines(file_path, warn = FALSE)

  data_lines <- lines[
    !grepl("^\\s*[@#]", lines) &
      trimws(lines) != "" &
      trimws(lines) != "&"
  ]

  if (length(data_lines) == 0) {
    stop("No numerical data found in: ", file_path)
  }

  data <- read.table(
    text = data_lines,
    header = FALSE,
    fill = TRUE,
    stringsAsFactors = FALSE
  )

  if (ncol(data) < 2) {
    stop("Fewer than two numerical columns found in: ", file_path)
  }

  data <- data[, 1:2, drop = FALSE]
  names(data) <- c("Time_ps", "Value")

  data$Time_ps <- as.numeric(data$Time_ps)
  data$Value <- as.numeric(data$Value)

  data <- data[
    is.finite(data$Time_ps) &
      is.finite(data$Value),
    ,
    drop = FALSE
  ]

  if (nrow(data) == 0) {
    stop("No finite numerical values found in: ", file_path)
  }

  data
}

# Extract one observable with gmx energy
extract_energy_term <- function(term_name, xvg_path, log_path) {
  message("Extracting: ", term_name)

  command_output <- system2(
    command = gmx_command,
    args = c(
      "energy",
      "-f", shQuote(edr_file),
      "-o", shQuote(xvg_path),
      "-xvg", "none"
    ),
    input = c(term_name, "0"),
    stdout = TRUE,
    stderr = TRUE
  )

  exit_status <- attr(command_output, "status")

  if (is.null(exit_status)) {
    exit_status <- 0L
  }

  writeLines(command_output, con = log_path)

  if (exit_status != 0L || !file.exists(xvg_path)) {
    stop(
      "gmx energy failed for '", term_name,
      "'. See: ", log_path
    )
  }

  invisible(command_output)
}

# Plot one extracted observable
plot_energy_term <- function(
  data,
  title,
  y_label,
  output_path
) {
  png(
    filename = output_path,
    width = 1800,
    height = 1200,
    res = 200
  )

  old_par <- par(no.readonly = TRUE)

  tryCatch(
    {
      par(
        mar = c(5.2, 5.6, 4.2, 1.5),
        mgp = c(3.3, 1.0, 0),
        las = 1
      )

      plot(
        x = data$Time_ps,
        y = data$Value,
        type = "l",
        lwd = 2,
        xlab = "Time (ps)",
        ylab = y_label,
        main = title
      )

      grid()

      # Dashed horizontal line showing the frame-wise mean
      abline(
        h = mean(data$Value),
        lty = 2,
        lwd = 1.5
      )

      legend(
        "topright",
        legend = c(
          title,
          sprintf("Frame mean = %.3f", mean(data$Value))
        ),
        lty = c(1, 2),
        lwd = c(2, 1.5),
        bty = "n"
      )
    },
    finally = {
      par(old_par)
      dev.off()
    }
  )
}

summary_rows <- list()

for (term_name in names(terms)) {
  settings <- terms[[term_name]]

  xvg_path <- file.path(
    xvg_dir,
    paste0("full_", settings$file_stub, ".xvg")
  )

  plot_path <- file.path(
    plot_dir,
    paste0("full_", settings$file_stub, ".png")
  )

  log_path <- file.path(
    stats_dir,
    paste0("gmx_energy_", settings$file_stub, ".txt")
  )

  tryCatch(
    {
      extract_energy_term(
        term_name = term_name,
        xvg_path = xvg_path,
        log_path = log_path
      )

      data <- read_xvg_numeric(xvg_path)

      plot_energy_term(
        data = data,
        title = settings$title,
        y_label = settings$y_label,
        output_path = plot_path
      )

      summary_rows[[length(summary_rows) + 1]] <- data.frame(
        Observable = term_name,
        Frames = nrow(data),
        Start_time_ps = min(data$Time_ps),
        End_time_ps = max(data$Time_ps),
        Mean_from_XVG_frames = mean(data$Value),
        SD_from_XVG_frames = sd(data$Value),
        Minimum = min(data$Value),
        Maximum = max(data$Value),
        First_value = data$Value[1],
        Last_value = data$Value[nrow(data)],
        stringsAsFactors = FALSE
      )

      message("Saved plot: ", plot_path)
    },
    error = function(error_condition) {
      warning(
        "Could not process ",
        term_name,
        ": ",
        conditionMessage(error_condition)
      )
    }
  )
}

if (length(summary_rows) == 0) {
  stop("None of the requested energy terms could be processed.")
}

summary_table <- do.call(rbind, summary_rows)

summary_file <- file.path(
  stats_dir,
  "full_energy_frame_statistics.csv"
)

write.csv(
  summary_table,
  file = summary_file,
  row.names = FALSE
)

message("")
message("Finished.")
message("XVG files:   ", normalizePath(xvg_dir))
message("PNG plots:   ", normalizePath(plot_dir))
message("Statistics:  ", normalizePath(stats_dir))
message("")
message(
  "Note: the TXT files contain the statistics printed directly by ",
  "gmx energy. These can differ slightly from statistics calculated ",
  "from the exported XVG frames."
)
