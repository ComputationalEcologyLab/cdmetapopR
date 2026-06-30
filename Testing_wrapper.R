
library(cdmetapopR)
devtools::install("D:/GitHub/cdmetapopR")
load_all("D:/Github/CDMetaPOPR/")

test_cv <- ClassVars(ages = 1:3)
add_rows(test_cv, n=10)
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

# Default 7-patch object, matching PatchVarsS1.csv:
mypatchvars <- PatchVars()

# 3 patches, defaults taken from PatchVarsS1.csv's first 3 rows:
mypatchvars <- PatchVars(patch_id = 1:3)

# 3 patches with one column defined and other columns as defaults:
mypatchvars <- PatchVars(patch_id = 1:3, natal_grounds = c(1,1,0))

# Edit a column in place:
mypatchvars$k <- c(300, 300, 500)

# Add a patch (copies the last row; edit afterward):
mypatchvars$add_row()
# or equivalently:
add_rows(mypatchvars)

print(mypatchvars)

myclassvars <- ClassVars()
myclassvars$location
mypatchvars$class_vars <- c(myclassvars, myclassvars, myclassvars, myclassvars, myclassvars)
write_cdmetapop(mypatchvars, path="D:/UM/Github/mypatchvars.csv")


mypv <- PopVars()
mypv
add_rows(mypv, egg_add=nonmating)
mypv2 <- add_rows(read_cdmetapop("D:/Github/CDMetaPOP/example_files/PopVars/PopVars.csv", type = "popvars"), n=5)



test_cv <- ClassVars(
  ages = 0:5,
  body_size_mean = c(31, 53, 92, 123, 147, 184),
  body_size_std = c(0, 5, 0, 10, 10, 10),
  distribution = c(0.5, 0.25, 0.125, 0.0625, 0.03, 0.015),
  sex_ratio = rep(".50~.50", 6),
  age_mortality_out = rep(0, 6),
  age_mortality_out_stdev = rep(0, 6),
  age_mortality_back = c(0, 0, 0, 0, 0, 1),
  age_mortality_back_stdev = rep(0, 6),
  size_mortality_out = rep(0, 6),
  size_mortality_out_stdev = rep(1, 6),
  size_mortality_back = rep(0, 6),
  size_mortality_back_stdev = rep(0, 6),
  migration_out_prob = c(0, 0.1, 0.3, 0.5, 1, 1),
  migration_back_prob = rep(1, 6),
  straying_prob = rep(0.2, 6),
  dispersal_prob = rep(0.2, 6),
  maturation = c(0, 1, 1, 1, 1, 1),
  fecundity_ind = c(0, 5, 5, 10, 10, 10),
  fecundity_ind_stdev = rep(0, 6),
  fecundity_leslie = c(0, 2.5, 10, 11.7, 11.743, 15),
  fecundity_leslie_stdev = rep(0, 6),
  capture_out_prob = rep("N", 6),
  capture_back_prob = rep("N", 6),
  location = NULL
)

test_cv <- read_cdmetapop("D:/Github/cdmetapop/example_files/ClassVars/ClassVars_AS1.csv", type="ClassVars")
test_cv <- ClassVars(path = "D:/Github/cdmetapop/example_files/ClassVars/ClassVars_AS1.csv")

write_cdmetapop(test_cv, "D:")

test_patchvars <- PatchVars()
test_patchvars$class_vars = rep(test_cv, n=7)





