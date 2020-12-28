library(tidyverse)
library(dslabs)
library(docstring)
library(rpart)
library(ggplot2)
library(caret)

mnist <- read_mnist()

#str(mnist)

i <- 8
image(1:28, 1:28, matrix(mnist$train$images[i,], nrow=28)[ , 28:1],
col = gray(seq(0, 1, 0.05)), xlab = "", ylab="")
# the labels for this image is:
mnist$train$labels[i]

# Change image vectors to image matrices and select a subset of the rows and columns
selected_rows <- 1:28
selected_columns <- 1:28
train_im_matrix <- list(length=60000)
train_red_im_matrix <- list(length=60000)
for (i in 1:60000){
  train_im_matrix[[i]] <- matrix(mnist$train$images[i,], byrow=TRUE, ncol=28, nrow=28)
  train_red_im_matrix[[i]] <- rbind(train_im_matrix[[i]][selected_rows,], t(train_im_matrix[[i]])[selected_columns,])
}

# Repeat for test images
test_im_matrix <- list(length=10000)
test_red_im_matrix <- list(length=10000)
for (i in 1:10000){
  test_im_matrix[[i]] <- matrix(mnist$test$images[i,], byrow=TRUE, ncol=28, nrow=28)
  test_red_im_matrix[[i]] <- rbind(test_im_matrix[[i]][selected_rows,], t(test_im_matrix[[i]])[selected_columns,])
}

# Change to black and white
for (k in 1:length(train_red_im_matrix)){
  train_red_im_matrix[[k]][train_red_im_matrix[[k]]>0] <- 1
  train_red_im_matrix[[k]][train_red_im_matrix[[k]]<=0] <- 0
}
for (k in 1:length(test_red_im_matrix)){
  test_red_im_matrix[[k]][test_red_im_matrix[[k]]>0] <- 1
  test_red_im_matrix[[k]][test_red_im_matrix[[k]]<=0] <- 0
}

# Calculate Euler Characteristic (EC)
EC_train <- matrix(0, nrow=length(train_red_im_matrix), 
                   ncol=(nrow(train_red_im_matrix[[1]])))

for (k in 1:length(train_red_im_matrix)){
  for (i in 1:nrow(train_red_im_matrix[[k]])){
    for (j in 1:27){
      if (train_red_im_matrix[[k]][i,j]==0 & train_red_im_matrix[[k]][i,j+1]==1){
        EC_train[k,i] <- EC_train[k,i] + 1
      }
    }
  }
}

# Repeat for EC_test
EC_test <- matrix(0, nrow=length(test_red_im_matrix), 
                  ncol=(nrow(test_red_im_matrix[[1]])))

for (k in 1:length(test_red_im_matrix)){
  for (i in 1:nrow(test_red_im_matrix[[k]])){
    for (j in 1:27){
      if (test_red_im_matrix[[k]][i,j]==0 & test_red_im_matrix[[k]][i,j+1]==1){
        EC_test[k,i] <- EC_test[k,i] + 1
      }
    }
  }
}

# Introduce dummy variables for labels
train_label_vectors <- matrix(0, nrow=nrow(EC_train), ncol=10)
for (k in 1:nrow(EC_train)){
    train_label_vectors[k, mnist$train$labels[k]+1] <- 1
}

# repeat for test labels
test_label_vectors <- matrix(0, nrow=nrow(EC_test), ncol=10)
for (k in 1:nrow(EC_test)){
  test_label_vectors[k, mnist$train$labels[k]+1] <- 1
}

# Introduce dummy variables for ECs
testthat::expect_true(max(EC_train, EC_test)<=5)

EC_train_vectors <- matrix(0, nrow=nrow(EC_train), ncol=(ncol(EC_train)*6))
for (k in 1:nrow(EC_train)){
  for (col_num in 1:(ncol(EC_train))){
      EC_train_vectors[k, 6*(col_num-1)+ EC_train[k,col_num]+1] <- 1 
  }
}

# Repeat for test ECs
EC_test_vectors <- matrix(0, nrow=nrow(EC_test), ncol=(ncol(EC_test)*6))
for (k in 1:nrow(EC_test)){
  for (col_num in 1:(ncol(EC_train))){
    EC_test_vectors[k, 6*(col_num-1)+ EC_test[k,col_num]+1] <- 1 
  }
}

EC_train_vectors <- data.frame(EC_train_vectors)
EC_test_vectors <- data.frame(EC_test_vectors)

# Rename the variables in the data frame of EC values
var_label <- function(i){
  row <- ceiling(i/6)
  EC <- ifelse(i %% 6 == 0, 5, i%%6 -1)
  label <- paste0('Row ',row,', EC = ',EC)
  return(label)
}

for (i in 1:length(names(EC_train_vectors))){
  names(EC_train_vectors)[i] <- var_label(i)
}
for (i in 1:length(names(EC_test_vectors))){
    names(EC_test_vectors)[i] <- var_label(i)
}

# Make a classification tree
rpart_fit <- rpart(mnist$train$labels ~ ., data=EC_train_vectors,method="class", cp=.001)
rp_predict_train <- predict(rpart_fit, newdata=EC_train_vectors, type="class")
rp_predict_test <- predict(rpart_fit, newdata=EC_test_vectors, type="class")

#plot(rpart_fit, margin=.01)
#text(rpart_fit, cex=.5)

# Measure accuracy
rp_percent_predict_train <- sum((rp_predict_train) == 
                                  mnist$train$labels)/length(rp_predict_train)
print(paste0('The model correctly categorizes ',rp_percent_predict_train," of the training images."))

rp_percent_predict_test <- sum(rp_predict_test == 
                                 mnist$test$labels)/length(rp_predict_test)
print(paste0('The model correctly predicts ',rp_percent_predict_test," of the test images."))

# Find percent correct, by label
percent_i <- vector(length=10)
for (i in 0:9){
  predict_given_i <- rp_predict_test[mnist$test$labels==i]
  percent_i[i+1] <- sum(predict_given_i==i)/length(predict_given_i)
}

print(percent_i)

ggplot() + geom_col(aes(y=percent_i, x=c('0','1','2','3','4','5','6','7','8','9')), show.legend=FALSE) + xlab('Actual Digit Represented in Image') + ylab('Percent Accurately Predicted')

confusionMatrix(as.factor(rp_predict_test), as.factor(mnist$test$labels))

# Testing the formation of image matrices, using training image number 3
testthat::expect_equal(mnist$train$images[3, 253:280],train_im_matrix[[3]][10,])

# Testing that the observed ECs do not exceed 5
testthat::expect_true(max(EC_train, EC_test)<=5)

# Testing var_label()
testthat::expect_equal(var_label(1), "Row 1, EC = 0")
testthat::expect_equal(var_label(6), "Row 1, EC = 5")
testthat::expect_equal(var_label(12), "Row 2, EC = 5")
testthat::expect_equal(var_label(123), "Row 21, EC = 2")