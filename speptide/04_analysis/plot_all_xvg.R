output_dir <- "plots"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# Remove common Grace/Xmgrace formatting commands from labels.
clean_grace_text <- function(text) {
  if (length(text) == 0 || is.na(text[1])) {
    return("")
  }

  text <- text[1]

  # Superscript and subscript formatting.
  text <- gsub("\\\\S([^\\\\]+)\\\\N", "^\\1", text, perl = TRUE)
  text <- gsub("\\\\s([^\\\\]+)\\\\N", "_\\1", text, perl = TRUE)

  # Font commands.
  text <- gsub("\\\\f\\{[^}]*\\}", "", text, perl = TRUE)
  text <- gsub("\\\\f[^\\\\ ]+", "", text, perl = TRUE)

  # Remaining normal-font tags.
  text <- gsub("\\\\N", "", text, fixed = FALSE)

  trimws(text)
}

# Extract the first quoted metadata value matching a Grace line.
extract_metadata <- function(lines, pattern, default_value = "") {
  matching_lines <- grep(pattern, lines, value = TRUE)

  if (length(matching_lines) == 0) {
    return(default_value)
  }

  value <- sub('^[^"]*"([^"]*)".*$', "\\1", matching_lines[1])

  if (identical(value, matching_lines[1])) {
    return(default_value)
  }

  clean_grace_text(value)
}

# Read legends and retain their original series numbers: s0, s1, ...
extract_legends <- function(lines) {
  legend_lines <- grep(
    "^@\\s+s[0-9]+\\s+legend\\s+",
    lines,
    value = TRUE
  )

  if (length(legend_lines) == 0) {
    return(character(0))
  }

  series_ids <- sub(
    "^@\\s+s([0-9]+)\\s+legend.*$",
    "\\1",
    legend_lines
  )

  legend_values <- sub(
    '^[^"]*"([^"]*)".*$',
    "\\1",
    legend_lines
  )

  legend_values <- vapply(
    legend_values,
    clean_grace_text,
    character(1)
  )

  stats::setNames(legend_values, series_ids)
}

# Split an XVG file into numerical data blocks separated by "&".
split_data_blocks <- function(lines) {
  data_lines <- lines[
    !grepl("^\\s*[@#]", lines) &
      trimws(lines) != ""
  ]

  blocks <- list()
  current_block <- character(0)

  for (line in data_lines) {
    if (trimws(line) == "&") {
      if (length(current_block) > 0) {
        blocks[[length(blocks) + 1]] <- current_block
        current_block <- character(0)
      }
    } else {
      current_block <- c(current_block, line)
    }
  }

  if (length(current_block) > 0) {
    blocks[[length(blocks) + 1]] <- current_block
  }

  blocks
}

# Test whether a token can be interpreted as a numerical XVG value.
is_numeric_token <- function(token) {
  grepl(
    "^[-+]?(?:(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)(?:[eEdD][-+]?[0-9]+)?|inf(?:inity)?|nan)$",
    token,
    ignore.case = TRUE,
    perl = TRUE
  )
}

# Read the leading numerical columns of a data block.
# This intentionally ignores text after the numbers, e.g. "GLU-2" in rama.xvg.
read_numeric_block <- function(block_lines) {
  if (length(block_lines) == 0) {
    return(NULL)
  }

  token_rows <- strsplit(trimws(block_lines), "\\s+")

  leading_numeric_counts <- vapply(
    token_rows,
    function(tokens) {
      numeric_flags <- vapply(tokens, is_numeric_token, logical(1))
      first_non_numeric <- which(!numeric_flags)

      if (length(first_non_numeric) == 0) {
        length(tokens)
      } else {
        as.integer(first_non_numeric[1] - 1L)
      }
    },
    integer(1)
  )

  number_of_columns <- min(leading_numeric_counts)

  if (number_of_columns < 2) {
    return(NULL)
  }

  numerical_rows <- lapply(
    token_rows,
    function(tokens) {
      values <- tokens[seq_len(number_of_columns)]
      values <- gsub("[dD]", "E", values)
      as.numeric(values)
    }
  )

  matrix(
    unlist(numerical_rows, use.names = FALSE),
    ncol = number_of_columns,
    byrow = TRUE
  )
}

# Create a label for a plotted series.
get_series_label <- function(series_id, legends) {
  key <- as.character(series_id)

  if (key %in% names(legends) && nzchar(legends[[key]])) {
    legends[[key]]
  } else {
    paste("Series", series_id + 1)
  }
}

# Plot a single XVG file.
plot_xvg <- function(file_path) {
  message("Processing: ", file_path)

  lines <- readLines(file_path, warn = FALSE)
  file_name <- tools::file_path_sans_ext(basename(file_path))

  graph_title <- extract_metadata(
    lines,
    "^@\\s+title\\s+",
    file_name
  )

  graph_subtitle <- extract_metadata(
    lines,
    "^@\\s+subtitle\\s+",
    ""
  )

  x_label <- extract_metadata(
    lines,
    "^@\\s+xaxis\\s+label\\s+",
    "X"
  )

  y_label <- extract_metadata(
    lines,
    "^@\\s+yaxis\\s+label\\s+",
    "Y"
  )

  legends <- extract_legends(lines)

  raw_blocks <- split_data_blocks(lines)
  data_blocks <- lapply(raw_blocks, read_numeric_block)
  data_blocks <- Filter(Negate(is.null), data_blocks)

  if (length(data_blocks) == 0) {
    warning("No usable numerical data in: ", file_path)
    return(invisible(NULL))
  }

  output_file <- file.path(
    output_dir,
    paste0(file_name, ".png")
  )

  is_ramachandran <- grepl(
    "rama|ramachandran",
    paste(file_name, graph_title, x_label, y_label),
    ignore.case = TRUE
  )

  if (is_ramachandran) {
    png(
      filename = output_file,
      width = 1600,
      height = 1600,
      res = 200
    )
  } else {
    png(
      filename = output_file,
      width = 1800,
      height = 1200,
      res = 200
    )
  }

  old_par <- par(no.readonly = TRUE)

  tryCatch(
    {
      par(
        mar = c(5.2, 5.4, 4.2, 1.5),
        mgp = c(3.2, 1.0, 0),
        las = 1
      )

      if (is_ramachandran) {
        # rama.xvg has Phi, Psi and a text residue label.
        rama_data <- do.call(
          rbind,
          lapply(data_blocks, function(block) block[, 1:2, drop = FALSE])
        )

        point_colour <- grDevices::adjustcolor(
          "black",
          alpha.f = 0.35
        )

        plot(
          x = rama_data[, 1],
          y = rama_data[, 2],
          type = "p",
          pch = 16,
          cex = 0.45,
          col = point_colour,
          xlim = c(-200, 200),
          ylim = c(-200, 200),
          xaxs = "i",
          yaxs = "i",
          asp = 1,
          axes = FALSE,
          xlab = if (x_label == "Phi") "Phi (degrees)" else x_label,
          ylab = if (y_label == "Psi") "Psi (degrees)" else y_label,
          main = graph_title
        )

        axis(
          side = 1,
          at = seq(-200, 200, by = 50),
          las = 1
        )

        axis(
          side = 2,
          at = seq(-200, 200, by = 50),
          las = 1
        )

        box()
        grid(
          nx = NULL,
          ny = NULL
        )
        abline(h = 0, v = 0, lty = 3)

      } else {
        # Convert all blocks and all Y columns into individual line series.
        plotted_series <- list()
        next_series_id <- 0

        for (block in data_blocks) {
          if (ncol(block) < 2) {
            next
          }

          for (column_number in 2:ncol(block)) {
            plotted_series[[length(plotted_series) + 1]] <- list(
              x = block[, 1],
              y = block[, column_number],
              id = next_series_id
            )

            next_series_id <- next_series_id + 1
          }
        }

        if (length(plotted_series) == 0) {
          warning("No Y series found in: ", file_path)
          return(invisible(NULL))
        }

        # For hbnum.xvg keep only s0 (hydrogen-bond count).
        # For gyrate.xvg keep only s0 (total radius of gyration, Rg),
        # excluding the X, Y and Z components.
        if (
          grepl("^hbnum", tolower(file_name)) ||
            grepl("^gyrate", tolower(file_name)) ||
            grepl("radius of gyration", graph_title, ignore.case = TRUE)
        ) {
          plotted_series <- plotted_series[1]
        }

        all_x <- unlist(
          lapply(plotted_series, function(series) series$x),
          use.names = FALSE
        )

        all_y <- unlist(
          lapply(plotted_series, function(series) series$y),
          use.names = FALSE
        )

        finite_x <- all_x[is.finite(all_x)]
        finite_y <- all_y[is.finite(all_y)]

        if (length(finite_x) == 0 || length(finite_y) == 0) {
          warning("No finite values in: ", file_path)
          return(invisible(NULL))
        }

        series_colours <- seq_along(plotted_series)

        first_series <- plotted_series[[1]]

        plot(
          x = first_series$x,
          y = first_series$y,
          type = "l",
          lty = 1,
          lwd = 2,
          col = series_colours[1],
          xlim = range(finite_x),
          ylim = range(finite_y),
          xlab = x_label,
          ylab = y_label,
          main = graph_title
        )

        if (length(plotted_series) > 1) {
          for (series_number in 2:length(plotted_series)) {
            lines(
              x = plotted_series[[series_number]]$x,
              y = plotted_series[[series_number]]$y,
              lty = 1,
              lwd = 2,
              col = series_colours[series_number]
            )
          }
        }

        grid()

        series_labels <- vapply(
          plotted_series,
          function(series) get_series_label(series$id, legends),
          character(1)
        )

        show_legend <- (
          length(plotted_series) > 1 ||
            length(legends) > 0
        )

        if (show_legend) {
          legend(
            "topright",
            legend = series_labels,
            col = series_colours,
            lty = 1,
            lwd = 2,
            bty = "n",
            cex = 0.9
          )
        }
      }

      if (nzchar(graph_subtitle)) {
        mtext(
          graph_subtitle,
          side = 3,
          line = 0.3,
          cex = 0.8
        )
      }
    },
    finally = {
      par(old_par)
      dev.off()
    }
  )

  message("Saved: ", output_file)
  invisible(output_file)
}

# Find all XVG files in the current working directory.
xvg_files <- list.files(
  path = ".",
  pattern = "\\.xvg$",
  full.names = TRUE,
  ignore.case = TRUE
)

if (length(xvg_files) == 0) {
  stop("No XVG files were found in the current working directory.")
}

# One malformed file will not stop plotting the remaining files.
invisible(
  lapply(
    xvg_files,
    function(file_path) {
      tryCatch(
        plot_xvg(file_path),
        error = function(error_condition) {
          warning(
            "Could not plot ",
            file_path,
            ": ",
            conditionMessage(error_condition)
          )
          invisible(NULL)
        }
      )
    }
  )
)

message("Plots were saved in: ", normalizePath(output_dir))
