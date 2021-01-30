library(tidyverse)
library(dslabs)
library(docstring)
library(rpart)
library(caret)
library(randomForest)

source('mnist_project_functions.r')

mnist <- read_mnist()

predict_by_EC <- function(cutoff=0, selected_rows = 1:28, selected_columns = 1:28,
                          ntree = 25){
  #' @description Produces both a single classification tree and a random forest
  #' of classification trees for the MNIST data set using the Euler Characteristics
  #' (number of connected regions of writing) of the rows and columns of pixels.
  #' @return Text describing the overall accuracy of the tree and the random forest, 
  #' and a ggplot of accuracy of the random forest by category.
  #' @param cutoff  pixels will be considered writing if their gray scale values 
  #' are above the cutoff
  #' @param selected_rows a vector of integers in the range 1:28, or NULL as long as 
  #' selected_columns is not NULL
  #' @param selected_columns a vector of integers in the range 1:28, or NULL as long as 
  #' selected_rows is not NULL
  #' @param ntree positive integer for the number of trees to be used in the random forest
 
  # Change image vectors to image matrices and select a subset of the rows and columns
  train_red_im_matrix <- make_image_matrices(image_vectors = mnist$train$images, 
                      selected_columns = selected_columns, 
                      selected_rows = selected_rows)
  test_red_im_matrix <- make_image_matrices(image_vectors = mnist$test$images,
                      selected_columns = selected_columns,
                      selected_rows = selected_rows)
  
  # Find the Euler Characteristics of the selected rows and columns
  EC_train <- get_EC(train_red_im_matrix, cutoff = cutoff)
  EC_test <- get_EC(test_red_im_matrix, cutoff = cutoff)
  
  # Make a classification tree
  rpart_fit <- rpart(mnist$train$labels ~ ., data=data.frame(EC_train), 
                     method="class", cp=.001)
  tree_predict_train <- predict(rpart_fit, newdata=data.frame(EC_train), type="class")
  tree_predict_test <- predict(rpart_fit, newdata=data.frame(EC_test), type="class")
  
  tree_percent_predict_train <- sum((tree_predict_train) == 
                                    mnist$train$labels)/length(tree_predict_train)
  print(paste0('A single tree correctly categorizes ',tree_percent_predict_train,
               " of the training images."))
  
  tree_percent_predict_test <- sum(tree_predict_test == 
                                   mnist$test$labels)/length(tree_predict_test)
  print(paste0('A single correctly predicts ',tree_percent_predict_test," of the test images."))
  
  
  # Train a random forest
  forest_fit <- randomForest(x = EC_train, 
                           y = as.factor(mnist$train$labels), ntree = ntree,
                           nodesize = 3)
  
  # Predict with random forest
  forest_predict_train <- predict(forest_fit, newdata = EC_train)
  forest_predict_test <- predict(forest_fit, newdata = EC_test)
  
  confusion_mat_train <- confusionMatrix(forest_predict_train, as.factor(mnist$train$labels))
  confusion_mat_test <- confusionMatrix(forest_predict_test, as.factor(mnist$test$labels))
  
  print(paste0('A random forest correctly categorizes ',
               confusion_mat_train$overall["Accuracy"]," of the training images."))
  print(paste0('A random forest correctly predicts ',
               confusion_mat_test$overall["Accuracy"]," of the test images."))
  
  # Visualize accuracy by digit
  ggplot() + 
    geom_col(aes(y=confusion_mat_test$byClass[,"Sensitivity"],
                 x=c('0','1','2','3','4','5','6','7','8','9')),
             show.legend=FALSE) + xlab('Actual Digit Represented in Image') +
    ylab('Percent Accurately Predicted')
}

predict_by_EC()
