# hand_written_digits
An implementation of topological data analysis for reading images from the MNIST data set

I originally created and submitted this project for my course in "Statistical Programming in R" (PHP 2560) in the Fall of 2020.  I have since revised it slightly.

The goal was to write a program to extract topological data from images of handwritten digits, and then apply machine learning techniques using the extracted features.

Below is text from the orginial submission.

- - - -

Tobias DeKara
Statistical Programming in R
Midterm Project
"An Application of Topological Data Analysis to Handwritten Digits"
11/3/20

Introduction
My question is "Can a very basic version of topological data analysis accurately identify hand-written
digits?"

To answer this, I am using the MNIST data set, a set of gray scale images of hand-written digits (see
"About the Data", below). The images have 784 pixels, arranged as a 28 x 28 square, and I first
round the gray scale values to 0 or 1, representing white and black.

To extract topological data from the images, I calculate the Euler Characteristic (EC) of each row of
pixels. In this one dimensional case, the EC is equal to the number of separate regions of writing in
the row. For example, '00000000111000001111000000000' corresponds to a row with 2 distinct
sections of writing, and so the EC is equal to 2, and '0000001111000001111100001111' has an EC of
3.

I then use the ECs as variables in a model for predicting the type of digit in the image. For the
model, I chose to create a decision tree using recursive partitioning, implemented by the 'rpart'
package, authored by Beth Atkinson. For an explanation of this process see step 7, below.

Finally, the decision tree is used to predict the type of digit in each image, and I measure the overall
accuracy, as well as the accuracy for reading each type of digit.

About the Data
The MNIST data set was originally produced by the National Institute of Standards and Technology
(NIST), and modified (hence MNIST) by Yann LeCun, Courant Institute, NYU; Corinna Cortes,
Google Labs, New York; and Christopher J.C. Burges, Microsoft Research, Redmond (see
http://yann.lecun.com/exdb/mnist/).

I am reading the data into R by using the 'dslabs' package authored by Rafael A. Irizarry and Amy
Gill; in particular this package includes the function read_mnist() written by Samuela Pollack,
spollack@jimmy.harvard.edu.

The data has already been divided into a training set with 60,000 images and a test set of 10,000
images. The data comes as a list for the training data and another list for the test data. These lists
each have a matrix for the gray scale values of the images, and a vector for the labels (the actual
type of digit that is represented in an image).

Each images has 784 pixels, arranged as a 28 x 28 square. The 784 pixels of each image are
stored as rows of the mnist$test$images and mnist$train$images matrices. I will refer
to these rows as "image vectors". These are stored 'by row', meaning the first 28 entries of an
image vector represent the first row of that image.

The Plan
1. Read in the data
2. Change image vectors to image matrices
3. Change to black and white
4. Calculate the Euler Characteristic
5. Introduce dummy variables
6. Add meaningful names to the data frame of EC values
7. Make a Classification Tree using Recursive Partitioning
8. View the decision tree
9. Measure accuracy
10. Visualize accuracy
