# Change image vectors to image matrices and select a subset of the rows and columns
make_image_matrices <- function(image_vectors, selected_columns, selected_rows){
  n <- nrow(image_vectors)
  im_matrix <- list(length = n)
  red_im_matrix <- list(length = n)
  
  for (i in 1:n){
    im_matrix[[i]] <- matrix(image_vectors[i,], byrow=TRUE, ncol=28, nrow=28)
  }
  
  # Subsetting
  if (all(selected_rows == 1:28) & all(selected_columns == 1:28)){
    red_im_matrix <- im_matrix
  }
  else if (!is.null(selected_rows) & !is.null(selected_columns)){
    for (i in 1:n){
      red_im_matrix[[i]] <- rbind(im_matrix[[i]][selected_rows, , drop = FALSE], 
                                  t(im_matrix[[i]])[selected_columns, , drop = FALSE])
    }
  }
  else if (!is.null(selected_rows)){
    for (i in 1:n){
      red_im_matrix[[i]] <- im_matrix[[i]][selected_rows, , drop = FALSE]
    }
  }
  else if (!is.null(selected_columns)){
    for (i in 1:n){
      red_im_matrix[[i]] <- t(im_matrix[[i]])[selected_columns, , drop = FALSE]
    }
  }
  return(red_im_matrix)
}

# Calculate Euler Characteristic (EC)
get_EC <- function(image_matrices, cutoff=0){
  # image_matrix is a list of image matrices 
  # each image in the list corresponds to a row of the EC_matrix (indexed by k)
  # each row (or transposed column) of an image gets a column of EC_matrix (indexed by i)
  # pixels in a row are indexed by j
  EC_matrix <- matrix(0, nrow=length(image_matrices), 
                      ncol=(nrow(image_matrices[[1]])))
  for (k in 1:length(image_matrices)){  
    for (i in 1:nrow(image_matrices[[1]])){ 
      for (j in 1:27){
        if (image_matrices[[k]][i,j]<= cutoff & image_matrices[[k]][i,j+1]>cutoff){
          EC_matrix[k,i] <- EC_matrix[k,i] + 1
        }
      }
    }
  }
  return(EC_matrix)
}

