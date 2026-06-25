
library(cdmetapopR)
devtools::install("D:/GitHub/cdmetapopR")
load_all("D:/Github/CDMetaPOPR/")

test_classvars <- ClassVars()
View(as.data.frame(test_classvars))

test_cv <- read_cdmetapop("D:/Github/CDMetaPOP/example_files/classvars/Classvars_AS1.csv", "ClassVars")
str(test_classvars)

as.data.frame(test_cv) == as.data.frame(test_classvars)

print(test_cv)
str(test_cv)
add_rows(test_cv, n=1)

test_cv2 <- ClassVars(ages=0:2)
print(test_cv2)
test_cv2$sex_ratio = c("0.5~0.5", "0.2~0.8", "0.2~0.8")
write_cdmetapop(test_cv2, path="D:/ClassVarsbro.csv")
