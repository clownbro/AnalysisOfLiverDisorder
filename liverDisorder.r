#Loding Libraries
library(class)
library(caret)
library(C50)
library(gmodels)
library(stats)
library(cluster)
library(fpc)
library(plotly)
library(e1071)
library(randomForest)
library(caTools)

#----------------- load orignal dataset -------------------------------------#
data.liver <- read.csv("liver.csv",TRUE,)
str(data.liver)

# Removing Gender column
data.liver <- data.liver[,c(1,3:11)]


# selecting the column of missing values and defining ina variable
x <- c(data.liver$A.G.Ratio)
summary(x)

#------------------------ Mean without NA values ----------------------------#
result.mean<-mean(x,na.rm = TRUE)
print(result.mean)

liver_normal <- data.liver[,c(1:9)]

# Function for Normalization
normalize <- function(w) {
  return((w-min(w)) / (max(w) - min(w)))
}

# Normalizing the dataset for calculations
liver_normal <- as.data.frame(lapply(liver_normal,normalize))
Selector.field <- as.factor(data.liver$Selector.field)
liver_normal<-cbind(liver_normal,Selector.field)
str(liver_normal)

#---------------------------- Data Partitioning for KNN Algorithm  --------------------#
trainer <- liver_normal[1:450,c(1:9)]
tester <- liver_normal[451:583,c(1:9) ]
trainer_target <- liver_normal[1:450,10]
tester_target <- liver_normal[451:583,10]

################################################################################
#                            Applying KNN Algorithm                            #
################################################################################

knn_model <- knn(train = trainer, test = tester,
                 cl=trainer_target, k=sqrt(583))

# Printing and plotting model results
print(knn_model)
x<-rchisq(100,5,0)
plot_ly(x=knn_model,type = 'histogram')

# Summary of the Algorithm
summary(knn_model)

#Finding Results using confusion matrix
confusionMatrix(knn_model, tester_target)

#--------------- Validating Data Partitioning for this C5.0 Algorithm ------------------#
trainc50 <- liver_normal[1:450,c(1:9)]
testc50 <- liver_normal[451:583,]
train_targetc50 <- liver_normal[1:450,10]
test_targetc50 <- liver_normal[451:583,10]


##########################################################################
#                               C50 ALGORITHM                            #
##########################################################################

C50_model<- C5.0(trainc50,train_targetc50)

# print result of Algorithm
print(C50_model)

# Summary of the Algorithm
summary(C50_model)
plot(C50_model,type="extended")


# Testing the model
pred_m<-predict(C50_model,testc50)
print(pred_m)

# Making table of Confusion matrix
CrossTable(test_targetc50, pred_m,
           prop.chisq = FALSE, prop.c = FALSE, prop.r = FALSE,
           dnn = c('actual Selector.Field', 'predicted Selector.field'))

# Printing the Result using Confusion Matrix
confusionMatrix(test_targetc50,pred_m)
#--------------------------------------------------------------------------------#
# Improving the model with (adaptative) boosting
credit_boost10 <- C5.0(trainc50, train_targetc50,
                       trials = 10)
credit_boost10

credit_boost_pred10 <- predict(credit_boost10, testc50)
CrossTable(test_targetc50, credit_boost_pred10,
           prop.chisq = FALSE, prop.c = FALSE, prop.r = FALSE,
           dnn = c('actual Selector.field', 'predicted Selector.field'))
plot(credit_boost10)

confusionMatrix(test_targetc50,credit_boost_pred10)

#------------------ Prepration of the Data to be implemented in kmeans algorithm ------------------------#
data.liver1<-data.liver
data.liver1$Selector.field <- as.factor(data.liver1$Selector.field)
str(data.liver1)
#################################################################################
#                                K-means ALGORITHM                              #
#################################################################################

kmeans_model <- kmeans(x = subset(data.liver1, select = -Selector.field),
                       centers = 2)

# Printing and Ploting result of algorithm
str(kmeans_model)
plotcluster(data.liver1[,-10], kmeans_model$cluster)

# Summarizing the Algorithm's Result
summary(kmeans_model)

# Making table of Comfusion matrix
mtab <- table(data.liver1$Selector.field,kmeans_model$cluster)
CrossTable(kmeans_model$cluster, data.liver1$Selector.field,
           prop.chisq = FALSE, prop.c = FALSE, prop.r = FALSE,
           dnn = c('actual Selector.Field', 'predicted Selector.field'))

# Printing the result using confusion matrix
confusionMatrix(mtab)


#------------- Preparing Data to be implemented in Naive Bayes Algorithm ----------#
train_naive <- liver_normal[1:450,c(1:9)]
train_target_naive <- liver_normal[1:450,10]
tester_naive <- liver_normal[451:583,c(1:9) ]
tester_target_naive <- liver_normal[451:583,10]

###############################################################################
#                         Applying NAIVE BAYES Algorithm                      #
###############################################################################

bayes_model <- naiveBayes(x = train_naive, y = train_target_naive)

# Summary of the Algorithm
summary(bayes_model)

# structure result of Algorithm
str(bayes_model)

# Testing the model
result<-predict(object = bayes_model,newdata = tester_naive)
print(result)
x<-rchisq(100,5,0)
plot_ly(x=result,type = 'histogram')

# Making table of Confusion matrix
tab<-table(result,tester_target_naive)
CrossTable(tester_target_naive, result,
           prop.chisq = FALSE, prop.c = FALSE, prop.r = FALSE,
           dnn = c('actual Selector.Field', 'predicted Selector.field'))

plot(tab)

# Printing the result using confusion matrix
confusionMatrix(tab)   


#------------------------  Prepairing Data to be implemented in this Algorithm --------------------------#
train_rf <- liver_normal[1:450,c(1:9)]
test_rf <- liver_normal[451:583,]
train_target_rf <- liver_normal[1:450,10]
test_target_rf <- liver_normal[451:583,10]

###############################################################################
#                         Applying RANDOM FOREST Algorithm                    #
###############################################################################

random <- randomForest(train_rf,train_target_rf,ntree = 500)

# Printing and Ploting result of algorithm
print(random)
plot(random)

# Summarizing the Algorithm's Result
summary(random)

# Testing the model
predic <- predict(random,test_rf)
print(predic)

# Making table of Confusion matrix
rtab<-table(predic,test_target_rf)
CrossTable(test_target_rf, predic,prop.chisq = FALSE,
           prop.c = FALSE,
           prop.r = FALSE,
           dnn = c('actual Selector.Field',
                   'predicted Selector.field'))

x<-rchisq(1000,5,0)
plot_ly(x=predic,type = 'histogram')

# Printing the result using confusion matrix
confusionMatrix(predic,test_target_rf)

#############################################################################################
# ROC curve for Whole Orignal dataset befor implementing algorithms.

colAUC(liver_normal[,-10], liver_normal[,10],
       plotROC=TRUE,alg=c("Wilcoxon","ROC"))

cat("Total AUC: \n"); 
colMeans(colAUC(liver_normal[,-10], liver_normal[,10]))

# Plot patients in there age groups 
set.seed(100)
d <- data.liver[sample(nrow(data.liver), 500), ]
plot_ly(d, x = ~Age, y = ~Selector.field, color = ~Age,
        size = ~Age, text = ~paste("A.G.Ratio: ", A.G.Ratio))

#--------------------- ROC Curve for C5.0 Algorithm -----------------------------#
c5.0_predict <- predict(credit_boost10,testc50,type="prob") 
c5.0_ROC <- colAUC(c5.0_predict,testc50$Selector.field,
                   plotROC = TRUE,
                   alg=c("Wilcoxon","ROC"))

#--------------------- ROC curve for Naive bayes Algorithm ----------------------#
test_nb <- liver_normal[451:583,] 
nb_predict <- predict(bayes_model,test_nb,type="raw") 
nb_ROC <- colAUC(nb_predict,test_nb$Selector.field,
                 plotROC = TRUE,
                 alg=c("Wilcoxon","ROC"))

#--------------------- ROC curve for Random Forest ------------------------------#
rf_predict <- predict(random,test_rf,type="prob") 
rf_ROC <- colAUC(rf_predict,test_rf$Selector.field,
                 plotROC = TRUE,
                 alg=c("Wilcoxon","ROC"))

