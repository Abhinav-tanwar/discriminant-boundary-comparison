split_rows <- function(y, seed = 121, p = 0.7) {
    set.seed(seed)
    sort(unlist(lapply(split(seq_along(y), y), function(i) sample(i, floor(length(i) * p)))))
}

score <- function(actual, pred, prob = NULL) {
    levels_y <- levels(actual)
    cm <- table(actual = factor(actual, levels_y), predicted = factor(pred, levels_y))
    result <- list(accuracy = mean(actual == pred), confusion = unclass(cm))
    if (length(levels_y) == 2) {
        positive <- levels_y[2]
        tp <- sum(actual == positive & pred == positive)
        fp <- sum(actual != positive & pred == positive)
        fn <- sum(actual == positive & pred != positive)
        tn <- sum(actual != positive & pred != positive)
        result$recall <- tp/(tp + fn)
        result$precision <- if (tp + fp) 
            tp/(tp + fp)
        else 0
        result$balanced_accuracy <- (tp/(tp + fn) + tn/(tn + fp))/2
        if (!is.null(prob)) {
            y <- actual == positive
            result$roc_auc <- (sum(rank(prob)[y]) - sum(y) * (sum(y) + 1)/2)/(sum(y) * sum(!y))
        }
    }
    result
}

run_analysis <- function(root, out) {
    d <- read.csv(file.path(root, "data/discriminant.csv"))
    d$Class <- factor(d$Class)
    idx <- split_rows(d$Class)
    train <- d[idx, ]
    test <- d[-idx, ]
    models <- list(LDA = MASS::lda(Class ~ Feature1 + Feature2, train), QDA = MASS::qda(Class ~ 
        Feature1 + Feature2, train))
    grid <- expand.grid(Feature1 = seq(min(d$Feature1), max(d$Feature1), length.out = 180), 
        Feature2 = seq(min(d$Feature2), max(d$Feature2), length.out = 180))
    png(file.path(out, "decision-regions.png"), 1200, 600)
    par(mfrow = c(1, 2))
    result <- list(train_rows = nrow(train), test_rows = nrow(test))
    for (name in names(models)) {
        pr <- predict(models[[name]], test)
        result[[name]] <- score(test$Class, pr$class)
        region <- predict(models[[name]], grid)$class
        plot(grid, col = adjustcolor(as.integer(region), alpha.f = 0.15), pch = 15, cex = 0.4, 
            main = name)
        points(train[, c("Feature1", "Feature2")], col = as.integer(train$Class), pch = 19)
        points(test[, c("Feature1", "Feature2")], col = as.integer(test$Class), pch = 1)
    }
    dev.off()
    result
}

