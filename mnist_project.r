library(tidyverse)
library(dslabs)
library(docstring)
library(rpart)
library(ggplot2)
library(caret)

# Step 1. Read in the data
# This can take several minutes.
mnist <- read_mnist()

# View an image
# The following code gives us a look at one of the images. 
# This code was copied from the dslabs documentation and was
# written by Samuela Pollack, spollack@jimmy.harvard.edu.
i <- 8
image(1:28, 1:28, matrix(mnist$train$images[i,], nrow=28)[ , 28:1],
col = gray(seq(0, 1, 0.05)), xlab = "", ylab="")

# the labels for this image is:
mnist$train$labels[i]

# Step 2. Change image vectors to image matrices and select a subset of the rows and columns
# This makes two lists of matrices, 'train_im_matrix' and 'test_im_matrix'.
# These lists have one entry per image, and each entry is 28 by 28 matrix.
# The code allows for selecting a subset of the images' rows and columns by setting the values of
# 'selected_rows' and 'selected_columns' , which produces two lists of smaller matrices, 
# 'train_red_im_matrix' and 'test_red_im_matrix'.
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

# Step 3. Change to black and white
# To determine the Euler Characteristic, we need each pixel to considered "writing" or "not writing".
# Below, any gray scale value greater than 0 is changed to 1.
for (k in 1:length(train_red_im_matrix)){
  train_red_im_matrix[[k]][train_red_im_matrix[[k]]>0] <- 1
  train_red_im_matrix[[k]][train_red_im_matrix[[k]]<=0] <- 0
}
for (k in 1:length(test_red_im_matrix)){
  test_red_im_matrix[[k]][test_red_im_matrix[[k]]>0] <- 1
  test_red_im_matrix[[k]][test_red_im_matrix[[k]]<=0] <- 0
}

# Step 4. Calculate the Euler Characteristic (EC)
# In the code below, I find the EC of a row by counting the number of times the values in that row
# change from 0 to 1.
# For example, 000000111110000011111 should have an EC of 2.
# The result is a pair of matrices, EC_train and EC_test .
# Each is a k by i matrix, where k is the number of images, and i is the number of rows selected from
# the image matrices.
# The value of EC[k,i] is the EC for the k-th image's i-th selected row.
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

# Step 5. Introduce dummy variables
# Part a. The digit labels are categorical, meaning that a handwritten 2 is not somehow halfway between a
# 1 and 3. So, below I recode each label as a set of 10 "dummy variables".
# The first variable will indicate if the label is a 0, the second varible will indicate if the label is 1, . . .
# the tenth variable will indicate if the label is a 9.
# Each variable will have value 1 if the image has that label and value 0 otherwise.
# For example a label of "0" will become 1000000000 , a label of "2" will become 0010000000 .
train_label_vectors <- matrix(0, nrow=nrow(EC_train), ncol=10)
for (k in 1:nrow(EC_train)){
    train_label_vectors[k, mnist$train$labels[k]+1] <- 1
}

# repeat for test labels
test_label_vectors <- matrix(0, nrow=nrow(EC_test), ncol=10)
for (k in 1:nrow(EC_test)){
  test_label_vectors[k, mnist$train$labels[k]+1] <- 1
}

# 5.b.
# Below, I recode the ECs with dummy variables as well, because I believe that, in this context, the
# ECs are essentially categorical.
# While a case could be made that the ECs are ordinal data, any recursive partitioning that is possible
# by treating them as ordinal data is still possible by treating the ECs as categorical (albeit with more
# steps).
# The highest EC observed in the data is 5, so I recode the ECs with 6 dummy variables each.
# The first dummy variable indicates if the EC is zero. For example, an EC of 3 -> 000100.
# Note: This process with break down if there is an EC of 6 or greater, and I have included a test to
# check for that.
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

# The rpart() function requires data frames rather than matrices, so I make that change here.
EC_train_vectors <- data.frame(EC_train_vectors)
EC_test_vectors <- data.frame(EC_test_vectors)

# Step 6. Add meaningful names to the data frame of EC values
# In order to be able to interpret the decision tree that will be produced with this data,
# I rename the variable labels in the data frames of ECs.
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

# Step 7. Make a Classification Tree using Recursive Partitioning
# Below, I use the rpart() function from the rpart package, to fit a classification tree to the
# data. This package was written by Beth Atkinson.
# The rpart() function selects a variable and then divides the images in the training set into two
# partitions based on each image's value of that variable. The function then further subdivides these
# partitions based on a new variable. This process continues until the accuracy gained by adding new
# partitions drops below a pre-set complexity parameter ( cp ). The result is a decision tree that
# determines which partition an image belongs to. The algorithm then finds the most common label of
# the training images in each partition, and uses that label as the predicted label for every test set
# image that the decision tree sorts into that partition.

rpart_fit <- rpart(mnist$train$labels ~ ., data=EC_train_vectors,method="class", cp=.001)
rp_predict_train <- predict(rpart_fit, newdata=EC_train_vectors, type="class")
rp_predict_test <- predict(rpart_fit, newdata=EC_test_vectors, type="class")

# Step 8. View the decision tree
plot(rpart_fit, margin=.01)
text(rpart_fit, cex=.5)

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

# Step 10. Visualize accuracy
ggplot() + geom_col(aes(y=percent_i, x=c('0','1','2','3','4','5','6','7','8','9')), show.legend=FALSE) + xlab('Actual Digit Represented in Image') + ylab('Percent Accurately Predicted')

confusionMatrix(as.factor(rp_predict_test), as.factor(mnist$test$labels))

# Testing
# Testing the formation of image matrices, using training image number 3
testthat::expect_equal(mnist$train$images[3, 253:280],train_im_matrix[[3]][10,])

# Testing that the observed ECs do not exceed 5
testthat::expect_true(max(EC_train, EC_test)<=5)

# Testing var_label()
testthat::expect_equal(var_label(1), "Row 1, EC = 0")
testthat::expect_equal(var_label(6), "Row 1, EC = 5")
testthat::expect_equal(var_label(12), "Row 2, EC = 5")
testthat::expect_equal(var_label(123), "Row 21, EC = 2")
