source("R/analysis.R")

out <- tempfile()

dir.create(out)

r <- run_analysis(normalizePath("."), out)

stopifnot(length(r) > 0, file.exists(out))

stopifnot(r$train_rows + r$test_rows == 200, all(vapply(r[c("LDA", "QDA")], function(m) m$accuracy >= 
    0 && m$accuracy <= 1, logical(1))))

cat("Validation passed\n")

