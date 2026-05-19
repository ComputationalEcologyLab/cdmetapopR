---
title: "cdmetapopR Function Examples"
subtitle: "Worked examples using the Adaptive_Run_08 example outputs"
output:
  html_document:
    toc: true
    toc_depth: 3
    toc_float: true
    number_sections: true
    theme: flatly
    self_contained: true
---



# Overview

This document shows example uses for the exported functions in `cdmetapopR`.
The examples use the package example output files in `inst/extdata/Adaptive_Run_08`.

The example data include:

- 2 batches
- 2 Monte Carlo replicates per batch
- `summary_popAllTime.csv`
- `summary_classAllTime.csv`
- `summary_popAllTime_DiseaseStates.csv`
- `ind0.csv` through `ind9.csv`


``` r
ex_dir <- system.file("extdata", "Adaptive_Run_08", package = "cdmetapopR")

pop_file <- file.path(ex_dir, "run0batch0mc0species0", "summary_popAllTime.csv")
class_file <- file.path(ex_dir, "run0batch0mc0species0", "summary_classAllTime.csv")
ind_file <- file.path(ex_dir, "run0batch0mc0species0", "ind9.csv")

ex_dir
```

```
## [1] "C:/Users/allis/OneDrive - The Ohio State University/Research/side_projects/cdmetapop_package/cdmetapopR/inst/extdata/Adaptive_Run_08"
```

``` r
list.files(ex_dir)
```

```
## [1] "run0batch0mc0species0" "run0batch0mc1species0" "run0batch1mc0species0"
## [4] "run0batch1mc1species0"
```

# Reading and Conversion Helpers

## `read.cdmetapop()`

Use `read.cdmetapop()` to read a CDMetaPOP CSV file into R while keeping the CDMetaPOP-delimited columns as character columns.


``` r
pop_data_chr <- read.cdmetapop(pop_file)

dim(pop_data_chr)
```

```
## [1] 200  81
```

``` r
head(pop_data_chr[, 1:6])
```

```
##   Year
## 1    0
## 2    1
## 3    2
## 4    3
## 5    4
## 6    5
##                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            K
## 1        50054.54099999998|557.965|508.795|502.465|488.091|562.674|568.879|525.22|495.584|479.319|577.174|408.953|555.769|526.205|499.77|452.081|503.644|439.657|525.727|462.646|455.51|426.283|580.581|557.451|493.912|566.308|494.123|502.761|505.394|504.804|466.735|490.808|494.973|476.557|379.09|529.476|374.017|485.239|495.066|470.818|485.25|451.138|502.308|522.653|554.22|569.119|495.938|451.256|463.222|477.516|534.781|516.86|463.804|561.349|487.07|614.136|578.101|533.669|419.944|446.146|564.902|510.6|556.653|492.889|484.372|480.175|466.264|535.34|470.591|575.14|448.605|578.025|506.922|530.839|424.792|492.474|522.682|558.68|538.948|504.346|392.23|522.702|467.992|514.037|475.686|521.305|514.163|515.582|529.075|507.494|472.318|423.091|470.099|518.619|474.181|529.762|460.757|479.099|501.75|513.463|488.893|
## 2 49528.29599999999|496.946|541.583|556.58|552.356|497.343|517.266|524.495|422.387|481.617|600.048|442.127|479.301|531.43|548.512|545.711|490.308|484.298|514.146|411.449|515.734|546.862|509.011|535.529|442.232|494.862|520.873|560.185|444.185|530.632|424.93|497.285|434.252|429.012|432.431|474.027|453.813|486.035|481.408|466.492|484.352|634.621|498.598|469.794|491.529|488.782|590.82|555.525|427.031|511.764|450.613|497.797|582.325|475.859|513.189|552.444|525.579|411.446|412.035|471.04|480.482|468.527|447.526|445.781|520.424|542.416|461.047|534.407|420.916|440.106|406.512|546.638|465.061|445.216|605.407|427.724|547.78|507.789|484.638|507.446|497.554|493.762|526.69|496.489|510.787|488.975|546.925|512.808|570.879|538.097|482.397|435.965|467.867|476.75|541.085|511.957|411.402|465.536|481.344|569.629|432.719|
## 3    49360.18299999999|520.298|498.084|575.143|364.568|495.64|545.495|482.883|469.115|492.659|587.112|534.536|503.216|500.604|408.764|553.225|498.74|414.576|469.047|376.051|507.081|478.163|519.76|531.907|515.875|538.469|539.688|484.478|521.197|402.26|512.983|546.614|434.886|512.572|532.042|493.803|547.809|429.018|491.194|405.493|505.722|428.743|373.999|557.009|534.528|607.755|316.372|470.171|457.174|472.863|494.666|524.411|546.108|445.782|499.32|535.714|469.345|430.952|517.373|444.945|569.94|585.385|490.307|414.693|473.129|460.988|522.423|624.789|478.264|557.259|548.825|589.136|467.007|456.035|514.064|462.052|486.039|560.376|495.701|617.66|380.684|440.97|554.8|478.077|473.597|495.043|481.413|484.182|550.734|484.24|469.825|414.978|500.945|503.621|522.825|461.972|512.976|500.048|492.255|479.114|435.812|
## 4         49719.33900000002|534.29|629.232|603.579|471.322|554.403|614.018|456.589|508.833|513.413|472.269|468.994|534.893|547.558|473.524|567.701|409.806|486.094|470.032|445.105|531.447|472.04|523.263|489.155|416.561|580.516|409.096|562.315|449.517|565.151|492.823|502.057|509.303|494.967|421.134|519.118|583.595|517.114|424.48|584.443|491.484|479.923|395.254|459.729|506.006|500.196|519.17|544.156|496.675|529.97|387.4|500.867|408.259|481.702|493.99|559.974|507.259|505.046|498.684|434.164|460.052|457.219|613.515|568.604|525.341|484.015|445.848|456.549|490.122|421.796|496.332|525.999|557.235|545.699|412.675|492.292|465.935|530.155|533.62|536.8|482.936|382.039|478.55|541.172|464.97|454.684|496.016|482.549|467.04|523.532|477.246|506.31|477.277|511.519|416.276|554.394|387.496|521.03|452.372|543.242|569.228|
## 5        50954.73600000002|458.91|497.421|537.082|484.442|517.87|558.715|518.998|521.073|574.826|502.857|517.684|492.993|489.82|527.445|563.286|499.9|416.659|441.376|478.419|499.493|416.856|511.225|432.206|508.184|493.202|578.736|470.365|515.968|559.76|488.76|517.921|518.521|506.591|578.294|558.762|579.205|502.712|509.99|518.95|501.042|459.884|539.513|472.056|446.675|446.863|529.703|540.236|493.407|484.989|465.196|548.014|486.503|495.966|505.614|540.072|588.642|551.212|474.031|571.519|533.465|498.391|537.736|565.24|538.036|525.344|531.222|437.123|578.965|472.817|570.054|524.455|523.938|526.533|501.806|524.159|440.826|475.664|512.94|406.594|487.853|529.361|475.158|489.415|374.587|489.522|566.663|472.235|505.258|453.195|540.059|554.58|504.776|574.92|577.457|426.15|576.399|484.966|523.535|548.355|568.37|
## 6      49662.09200000002|424.852|446.875|530.753|545.077|432.555|521.951|469.456|577.464|464.311|466.999|588.605|476.83|556.353|436.551|457.94|525.504|473.031|492.984|472.341|388.85|410.999|482.254|415.58|498.687|454.635|511.14|489.33|536.063|455.328|538.956|540.823|499.525|503.693|415.054|540.723|508.068|546.086|563.981|518.489|562.201|524.281|478.08|489.108|530.295|450.99|472.782|460.646|471.221|467.359|523.124|501.124|500.361|512.566|542.432|538.301|586.679|531.434|479.065|553.564|546.277|573.426|492.838|468.136|421.833|483.597|471.687|541.111|521.913|432.06|490.441|428.569|494.635|518.024|526.999|501.144|391.201|446.069|403.787|470.004|443.3|580.283|568.145|438.619|609.488|511.41|636.669|406.137|503.185|421.362|468.754|559.759|610.406|541.58|502.071|518.658|453.303|573.802|462.777|498.376|375.948|
##           GrowthRate
## 1            1.09496
## 2 0.9823189888215095
## 3 1.0098921532168093
## 4 1.0022094564737074
## 5 1.0013962375073486
## 6 0.9988992441476481
##                                                                                                                                                                                                                                                                                                            N_Initial
## 1 12500|250|0|250|250|250|0|250|0|250|0|250|250|0|0|250|250|250|0|0|0|0|250|250|0|250|0|0|0|0|250|250|0|0|250|0|0|250|0|250|250|0|250|250|0|250|250|250|0|0|250|0|0|250|0|250|250|0|250|0|250|0|250|250|0|250|0|0|0|0|250|0|0|250|0|0|0|250|250|250|250|0|0|250|250|250|0|250|250|0|250|0|250|0|250|250|0|0|0|0|250|
## 2 13687|312|0|296|303|326|0|310|0|309|0|180|246|0|0|306|203|254|0|0|0|0|276|327|0|297|0|0|0|0|259|258|0|0|313|0|0|339|0|311|224|0|250|283|0|253|245|185|0|0|266|0|0|219|0|291|247|0|207|0|249|0|339|305|0|271|0|0|0|0|294|0|0|292|0|0|0|216|247|341|314|0|0|183|286|314|0|286|199|0|360|0|317|0|225|252|0|0|0|0|302|
## 3 13445|312|0|317|309|336|0|309|0|324|0|153|231|0|0|301|168|262|0|0|0|0|273|343|0|323|0|0|0|0|262|274|0|0|324|0|0|335|0|326|224|0|246|296|0|238|243|142|0|0|245|0|0|190|0|299|245|0|190|0|229|0|346|303|0|242|0|0|0|0|295|0|0|287|0|0|0|200|236|347|325|0|0|145|286|319|0|274|172|0|366|0|316|0|197|233|0|0|0|0|287|
## 4 13578|319|0|309|320|352|0|347|0|334|0|123|238|0|0|343|165|262|0|0|0|0|274|364|0|324|0|0|0|0|282|269|0|0|340|0|0|328|0|335|207|0|224|276|0|238|233|118|0|0|261|0|0|165|0|313|230|0|184|0|236|0|364|315|0|254|0|0|0|0|327|0|0|288|0|0|0|173|225|380|336|0|0|121|300|328|0|280|159|0|393|0|327|0|174|230|0|0|0|0|291|
## 5  13608|315|0|313|302|371|0|329|0|365|0|112|240|0|0|355|150|271|0|0|0|0|280|390|0|330|0|0|0|0|301|270|0|0|352|0|0|352|0|345|202|0|210|298|0|235|251|99|0|0|250|0|0|153|0|308|217|0|178|0|217|0|398|309|0|243|0|0|0|0|290|0|0|282|0|0|0|178|219|388|358|0|0|113|314|338|0|280|136|0|394|0|330|0|158|233|0|0|0|0|286|
## 6  13627|309|0|313|285|384|0|345|0|391|0|102|245|0|0|347|147|267|0|0|0|0|278|402|0|305|0|0|0|0|310|276|0|0|369|0|0|366|0|329|207|0|217|304|0|223|253|85|0|0|233|0|0|127|0|311|218|0|168|0|234|0|420|297|0|265|0|0|0|0|298|0|0|296|0|0|0|178|216|388|359|0|0|106|306|345|0|280|127|0|394|0|344|0|161|215|0|0|0|0|282|
##                                                                                                                                                                                                                                                                                                                                                                                                      PopSizes_Mean
## 1 0.0|nan|0.0|0.0|0.0|nan|0.0|nan|0.0|nan|0.0|0.0|nan|nan|0.0|0.0|0.0|nan|nan|nan|nan|0.0|0.0|nan|0.0|nan|nan|nan|nan|0.0|0.0|nan|nan|0.0|nan|nan|0.0|nan|0.0|0.0|nan|0.0|0.0|nan|0.0|0.0|0.0|nan|nan|0.0|nan|nan|0.0|nan|0.0|0.0|nan|0.0|nan|0.0|nan|0.0|0.0|nan|0.0|nan|nan|nan|nan|0.0|nan|nan|0.0|nan|nan|nan|0.0|0.0|0.0|0.0|nan|nan|0.0|0.0|0.0|nan|0.0|0.0|nan|0.0|nan|0.0|nan|0.0|0.0|nan|nan|nan|nan|0.0|
## 2 0.0|nan|0.0|0.0|0.0|nan|0.0|nan|0.0|nan|0.0|0.0|nan|nan|0.0|0.0|0.0|nan|nan|nan|nan|0.0|0.0|nan|0.0|nan|nan|nan|nan|0.0|0.0|nan|nan|0.0|nan|nan|0.0|nan|0.0|0.0|nan|0.0|0.0|nan|0.0|0.0|0.0|nan|nan|0.0|nan|nan|0.0|nan|0.0|0.0|nan|0.0|nan|0.0|nan|0.0|0.0|nan|0.0|nan|nan|nan|nan|0.0|nan|nan|0.0|nan|nan|nan|0.0|0.0|0.0|0.0|nan|nan|0.0|0.0|0.0|nan|0.0|0.0|nan|0.0|nan|0.0|nan|0.0|0.0|nan|nan|nan|nan|0.0|
## 3 0.0|nan|0.0|0.0|0.0|nan|0.0|nan|0.0|nan|0.0|0.0|nan|nan|0.0|0.0|0.0|nan|nan|nan|nan|0.0|0.0|nan|0.0|nan|nan|nan|nan|0.0|0.0|nan|nan|0.0|nan|nan|0.0|nan|0.0|0.0|nan|0.0|0.0|nan|0.0|0.0|0.0|nan|nan|0.0|nan|nan|0.0|nan|0.0|0.0|nan|0.0|nan|0.0|nan|0.0|0.0|nan|0.0|nan|nan|nan|nan|0.0|nan|nan|0.0|nan|nan|nan|0.0|0.0|0.0|0.0|nan|nan|0.0|0.0|0.0|nan|0.0|0.0|nan|0.0|nan|0.0|nan|0.0|0.0|nan|nan|nan|nan|0.0|
## 4 0.0|nan|0.0|0.0|0.0|nan|0.0|nan|0.0|nan|0.0|0.0|nan|nan|0.0|0.0|0.0|nan|nan|nan|nan|0.0|0.0|nan|0.0|nan|nan|nan|nan|0.0|0.0|nan|nan|0.0|nan|nan|0.0|nan|0.0|0.0|nan|0.0|0.0|nan|0.0|0.0|0.0|nan|nan|0.0|nan|nan|0.0|nan|0.0|0.0|nan|0.0|nan|0.0|nan|0.0|0.0|nan|0.0|nan|nan|nan|nan|0.0|nan|nan|0.0|nan|nan|nan|0.0|0.0|0.0|0.0|nan|nan|0.0|0.0|0.0|nan|0.0|0.0|nan|0.0|nan|0.0|nan|0.0|0.0|nan|nan|nan|nan|0.0|
## 5 0.0|nan|0.0|0.0|0.0|nan|0.0|nan|0.0|nan|0.0|0.0|nan|nan|0.0|0.0|0.0|nan|nan|nan|nan|0.0|0.0|nan|0.0|nan|nan|nan|nan|0.0|0.0|nan|nan|0.0|nan|nan|0.0|nan|0.0|0.0|nan|0.0|0.0|nan|0.0|0.0|0.0|nan|nan|0.0|nan|nan|0.0|nan|0.0|0.0|nan|0.0|nan|0.0|nan|0.0|0.0|nan|0.0|nan|nan|nan|nan|0.0|nan|nan|0.0|nan|nan|nan|0.0|0.0|0.0|0.0|nan|nan|0.0|0.0|0.0|nan|0.0|0.0|nan|0.0|nan|0.0|nan|0.0|0.0|nan|nan|nan|nan|0.0|
## 6 0.0|nan|0.0|0.0|0.0|nan|0.0|nan|0.0|nan|0.0|0.0|nan|nan|0.0|0.0|0.0|nan|nan|nan|nan|0.0|0.0|nan|0.0|nan|nan|nan|nan|0.0|0.0|nan|nan|0.0|nan|nan|0.0|nan|0.0|0.0|nan|0.0|0.0|nan|0.0|0.0|0.0|nan|nan|0.0|nan|nan|0.0|nan|0.0|0.0|nan|0.0|nan|0.0|nan|0.0|0.0|nan|0.0|nan|nan|nan|nan|0.0|nan|nan|0.0|nan|nan|nan|0.0|0.0|0.0|0.0|nan|nan|0.0|0.0|0.0|nan|0.0|0.0|nan|0.0|nan|0.0|nan|0.0|0.0|nan|nan|nan|nan|0.0|
##                                                                                                                                                                                                                                                                                                                                                                                                       PopSizes_Std
## 1 0.0|nan|0.0|0.0|0.0|nan|0.0|nan|0.0|nan|0.0|0.0|nan|nan|0.0|0.0|0.0|nan|nan|nan|nan|0.0|0.0|nan|0.0|nan|nan|nan|nan|0.0|0.0|nan|nan|0.0|nan|nan|0.0|nan|0.0|0.0|nan|0.0|0.0|nan|0.0|0.0|0.0|nan|nan|0.0|nan|nan|0.0|nan|0.0|0.0|nan|0.0|nan|0.0|nan|0.0|0.0|nan|0.0|nan|nan|nan|nan|0.0|nan|nan|0.0|nan|nan|nan|0.0|0.0|0.0|0.0|nan|nan|0.0|0.0|0.0|nan|0.0|0.0|nan|0.0|nan|0.0|nan|0.0|0.0|nan|nan|nan|nan|0.0|
## 2 0.0|nan|0.0|0.0|0.0|nan|0.0|nan|0.0|nan|0.0|0.0|nan|nan|0.0|0.0|0.0|nan|nan|nan|nan|0.0|0.0|nan|0.0|nan|nan|nan|nan|0.0|0.0|nan|nan|0.0|nan|nan|0.0|nan|0.0|0.0|nan|0.0|0.0|nan|0.0|0.0|0.0|nan|nan|0.0|nan|nan|0.0|nan|0.0|0.0|nan|0.0|nan|0.0|nan|0.0|0.0|nan|0.0|nan|nan|nan|nan|0.0|nan|nan|0.0|nan|nan|nan|0.0|0.0|0.0|0.0|nan|nan|0.0|0.0|0.0|nan|0.0|0.0|nan|0.0|nan|0.0|nan|0.0|0.0|nan|nan|nan|nan|0.0|
## 3 0.0|nan|0.0|0.0|0.0|nan|0.0|nan|0.0|nan|0.0|0.0|nan|nan|0.0|0.0|0.0|nan|nan|nan|nan|0.0|0.0|nan|0.0|nan|nan|nan|nan|0.0|0.0|nan|nan|0.0|nan|nan|0.0|nan|0.0|0.0|nan|0.0|0.0|nan|0.0|0.0|0.0|nan|nan|0.0|nan|nan|0.0|nan|0.0|0.0|nan|0.0|nan|0.0|nan|0.0|0.0|nan|0.0|nan|nan|nan|nan|0.0|nan|nan|0.0|nan|nan|nan|0.0|0.0|0.0|0.0|nan|nan|0.0|0.0|0.0|nan|0.0|0.0|nan|0.0|nan|0.0|nan|0.0|0.0|nan|nan|nan|nan|0.0|
## 4 0.0|nan|0.0|0.0|0.0|nan|0.0|nan|0.0|nan|0.0|0.0|nan|nan|0.0|0.0|0.0|nan|nan|nan|nan|0.0|0.0|nan|0.0|nan|nan|nan|nan|0.0|0.0|nan|nan|0.0|nan|nan|0.0|nan|0.0|0.0|nan|0.0|0.0|nan|0.0|0.0|0.0|nan|nan|0.0|nan|nan|0.0|nan|0.0|0.0|nan|0.0|nan|0.0|nan|0.0|0.0|nan|0.0|nan|nan|nan|nan|0.0|nan|nan|0.0|nan|nan|nan|0.0|0.0|0.0|0.0|nan|nan|0.0|0.0|0.0|nan|0.0|0.0|nan|0.0|nan|0.0|nan|0.0|0.0|nan|nan|nan|nan|0.0|
## 5 0.0|nan|0.0|0.0|0.0|nan|0.0|nan|0.0|nan|0.0|0.0|nan|nan|0.0|0.0|0.0|nan|nan|nan|nan|0.0|0.0|nan|0.0|nan|nan|nan|nan|0.0|0.0|nan|nan|0.0|nan|nan|0.0|nan|0.0|0.0|nan|0.0|0.0|nan|0.0|0.0|0.0|nan|nan|0.0|nan|nan|0.0|nan|0.0|0.0|nan|0.0|nan|0.0|nan|0.0|0.0|nan|0.0|nan|nan|nan|nan|0.0|nan|nan|0.0|nan|nan|nan|0.0|0.0|0.0|0.0|nan|nan|0.0|0.0|0.0|nan|0.0|0.0|nan|0.0|nan|0.0|nan|0.0|0.0|nan|nan|nan|nan|0.0|
## 6 0.0|nan|0.0|0.0|0.0|nan|0.0|nan|0.0|nan|0.0|0.0|nan|nan|0.0|0.0|0.0|nan|nan|nan|nan|0.0|0.0|nan|0.0|nan|nan|nan|nan|0.0|0.0|nan|nan|0.0|nan|nan|0.0|nan|0.0|0.0|nan|0.0|0.0|nan|0.0|0.0|0.0|nan|nan|0.0|nan|nan|0.0|nan|0.0|0.0|nan|0.0|nan|0.0|nan|0.0|0.0|nan|0.0|nan|nan|nan|nan|0.0|nan|nan|0.0|nan|nan|nan|0.0|0.0|0.0|0.0|nan|nan|0.0|0.0|0.0|nan|0.0|0.0|nan|0.0|nan|0.0|nan|0.0|0.0|nan|nan|nan|nan|0.0|
```

## `separate_column()`

Use `separate_column()` when a CDMetaPOP column stores multiple values inside one delimited cell. The example below splits the fourth column, `N_Initial`, using `|`.


``` r
n_initial_by_patch <- separate_column(pop_file, column_name = 4, sep = "|")

dim(n_initial_by_patch)
```

```
## [1] 200 102
```

``` r
head(n_initial_by_patch[, 1:8])
```

```
##      V1  V2 V3  V4  V5  V6 V7  V8
## 1 12500 250  0 250 250 250  0 250
## 2 13687 312  0 296 303 326  0 310
## 3 13445 312  0 317 309 336  0 309
## 4 13578 319  0 309 320 352  0 347
## 5 13608 315  0 313 302 371  0 329
## 6 13627 309  0 313 285 384  0 345
```

## `unite_column()`

Use `unite_column()` to combine several columns into one delimited column.


``` r
small_df <- data.frame(
  Patch = c("A", "B", "C"),
  N_1 = c(25, 30, 35),
  N_2 = c(34, 44, 34)
)

unite_column(
  dataframe = small_df,
  column_name = "N_combined",
  sep = "|",
  cols = c("N_1", "N_2")
)
```

```
##   Patch N_combined
## 1     A      25|34
## 2     B      30|44
## 3     C      35|34
```

## `create_cdmat()`

Use `create_cdmat()` to create a cost distance matrix from patch coordinates. The simplest options are Euclidean distance and equal distance.


``` r
coords <- data.frame(
  x = c(0, 1, 3, 6),
  y = c(0, 2, 2, 5)
)

create_cdmat(coords, method = "euclidean")
```

```
##          1        2        3        4
## 1 0.000000 2.236068 3.605551 7.810250
## 2 2.236068 0.000000 2.000000 5.830952
## 3 3.605551 2.000000 0.000000 4.242641
## 4 7.810250 5.830952 4.242641 0.000000
```

``` r
create_cdmat(coords, method = "equal")
```

```
##      [,1] [,2] [,3] [,4]
## [1,]    1    1    1    1
## [2,]    1    1    1    1
## [3,]    1    1    1    1
## [4,]    1    1    1    1
```

## `cdmetapop_to_gene()`

Use `cdmetapop_to_gene()` to convert an `ind##.csv` file to GENEPOP or GENALEX format. The function writes the converted file to the current working directory, so this example uses a temporary directory.


``` r
old_wd <- getwd()
setwd(tempdir())

cdmetapop_to_gene(ind_file, format = "genepop")
list.files(pattern = "^my_genepop")
```

```
## [1] "my_genepop_ind9.txt"
```

``` r
setwd(old_wd)
```

# Population Summary Plots

`summary_pop()` works with `summary_popAllTime.csv` files. The input can be a single file, a vector of files, a data frame, or a directory containing CDMetaPOP output folders.

When a directory is supplied, `summary_pop()` discovers the matching output folders and can summarize across batches and Monte Carlo replicates.

## Initial Population Size


``` r
summary_pop(ex_dir, type = "N_initial")
```

<img src="C:\Users\allis\OneDrive - The Ohio State University\Research\side_projects\cdmetapop_package\cdmetapopR\docs\cdmetapopR_function_examples_files/figure-html/summary-pop-n-initial-1.png" width="100%" />

## Sex Counts

By default, `type = "sex"` shows males and females only.


``` r
summary_pop(ex_dir, type = "sex")
```

<img src="C:\Users\allis\OneDrive - The Ohio State University\Research\side_projects\cdmetapop_package\cdmetapopR\docs\cdmetapopR_function_examples_files/figure-html/summary-pop-sex-1.png" width="100%" />

Use `include_yys = TRUE` to include YY males and YY females.


``` r
summary_pop(ex_dir, type = "sex", include_yys = TRUE)
```

<img src="C:\Users\allis\OneDrive - The Ohio State University\Research\side_projects\cdmetapop_package\cdmetapopR\docs\cdmetapopR_function_examples_files/figure-html/summary-pop-sex-yys-1.png" width="100%" />

## Mature Counts

By default, `type = "mature"` shows mature males and mature females only.


``` r
summary_pop(ex_dir, type = "mature")
```

<img src="C:\Users\allis\OneDrive - The Ohio State University\Research\side_projects\cdmetapop_package\cdmetapopR\docs\cdmetapopR_function_examples_files/figure-html/summary-pop-mature-1.png" width="100%" />

Use `include_yys = TRUE` to include mature YY males and mature YY females.


``` r
summary_pop(ex_dir, type = "mature", include_yys = TRUE)
```

<img src="C:\Users\allis\OneDrive - The Ohio State University\Research\side_projects\cdmetapop_package\cdmetapopR\docs\cdmetapopR_function_examples_files/figure-html/summary-pop-mature-yys-1.png" width="100%" />

## Births


``` r
summary_pop(ex_dir, type = "births")
```

<img src="C:\Users\allis\OneDrive - The Ohio State University\Research\side_projects\cdmetapop_package\cdmetapopR\docs\cdmetapopR_function_examples_files/figure-html/summary-pop-births-1.png" width="100%" />

## Myy Ratio


``` r
summary_pop(ex_dir, type = "myy_ratio")
```

<img src="C:\Users\allis\OneDrive - The Ohio State University\Research\side_projects\cdmetapop_package\cdmetapopR\docs\cdmetapopR_function_examples_files/figure-html/summary-pop-myy-ratio-1.png" width="100%" />

## Patch Abundance from `summary_popAllTime.csv`


``` r
summary_pop(ex_dir, type = "patch", years = c(0, 5, 9))
```

<img src="C:\Users\allis\OneDrive - The Ohio State University\Research\side_projects\cdmetapop_package\cdmetapopR\docs\cdmetapopR_function_examples_files/figure-html/summary-pop-patch-1.png" width="100%" />

## Deprecated `plot_population()`

`plot_population()` still works as a deprecated wrapper, but new code should use `summary_pop()` or `summary_class()`.


``` r
plot_population(ex_dir, type = "N_initial")
```

<img src="C:\Users\allis\OneDrive - The Ohio State University\Research\side_projects\cdmetapop_package\cdmetapopR\docs\cdmetapopR_function_examples_files/figure-html/plot-population-deprecated-1.png" width="100%" />

# Class Summary Plots

`summary_class()` works with `summary_classAllTime.csv` files.

## Age Class Counts


``` r
summary_class(ex_dir, type = "age_class", n = 10)
```

<img src="C:\Users\allis\OneDrive - The Ohio State University\Research\side_projects\cdmetapop_package\cdmetapopR\docs\cdmetapopR_function_examples_files/figure-html/summary-class-age-class-1.png" width="100%" />

## Age Plus One


``` r
summary_class(ex_dir, type = "age_plus_one")
```

<img src="C:\Users\allis\OneDrive - The Ohio State University\Research\side_projects\cdmetapop_package\cdmetapopR\docs\cdmetapopR_function_examples_files/figure-html/summary-class-age-plus-one-1.png" width="100%" />

# Disease State Summaries

`summarize_states()` works with `summary_popAllTime_DiseaseStates.csv` files. It summarizes disease-state counts across Monte Carlo replicates and compares batches.

## Default State Names


``` r
summarize_states(ex_dir)
```

<img src="C:\Users\allis\OneDrive - The Ohio State University\Research\side_projects\cdmetapop_package\cdmetapopR\docs\cdmetapopR_function_examples_files/figure-html/summarize-states-default-1.png" width="100%" />

## Custom State and Scenario Names


``` r
summarize_states(
  ex_dir,
  state_names = c("State 1", "State 2", "State 3"),
  scenario_names = c("Batch 0", "Batch 1")
)
```

<img src="C:\Users\allis\OneDrive - The Ohio State University\Research\side_projects\cdmetapop_package\cdmetapopR\docs\cdmetapopR_function_examples_files/figure-html/summarize-states-custom-1.png" width="100%" />

## Cumulative State

Use `cumulative_states` for a state that should be plotted as a running total within each Monte Carlo replicate.


``` r
summarize_states(
  ex_dir,
  state_names = c("State 1", "State 2", "State 3"),
  scenario_names = c("Batch 0", "Batch 1"),
  cumulative_states = "State 3"
)
```

<img src="C:\Users\allis\OneDrive - The Ohio State University\Research\side_projects\cdmetapop_package\cdmetapopR\docs\cdmetapopR_function_examples_files/figure-html/summarize-states-cumulative-1.png" width="100%" />

# Individual File Summaries

`summary_ind()` works with `ind##.csv` files. The input can be one file, multiple files, a run folder, a top-level output directory, or a data frame.

For one-year plots, specify `year`. For movement over time, specify `years`.

## Age Histogram


``` r
summary_ind(ex_dir, type = "age", year = 9, batch = 0, mc = 0)
```

<img src="C:\Users\allis\OneDrive - The Ohio State University\Research\side_projects\cdmetapop_package\cdmetapopR\docs\cdmetapopR_function_examples_files/figure-html/summary-ind-age-1.png" width="100%" />

## Size Histogram


``` r
summary_ind(ex_dir, type = "size", year = 9, batch = 0, mc = 0)
```

<img src="C:\Users\allis\OneDrive - The Ohio State University\Research\side_projects\cdmetapop_package\cdmetapopR\docs\cdmetapopR_function_examples_files/figure-html/summary-ind-size-1.png" width="100%" />

## Size by Age


``` r
summary_ind(ex_dir, type = "age_size", year = 9, batch = 0, mc = 0)
```

<img src="C:\Users\allis\OneDrive - The Ohio State University\Research\side_projects\cdmetapop_package\cdmetapopR\docs\cdmetapopR_function_examples_files/figure-html/summary-ind-age-size-1.png" width="100%" />

## Hindex Histogram


``` r
summary_ind(ex_dir, type = "hindex", year = 9, batch = 0, mc = 0)
```

<img src="C:\Users\allis\OneDrive - The Ohio State University\Research\side_projects\cdmetapop_package\cdmetapopR\docs\cdmetapopR_function_examples_files/figure-html/summary-ind-hindex-1.png" width="100%" />

## Movement Distance Histogram

`CDist = -9999` is treated as no movement and is excluded from the histogram.


``` r
summary_ind(ex_dir, type = "cdist", year = 9, batch = 0, mc = 0)
```

<img src="C:\Users\allis\OneDrive - The Ohio State University\Research\side_projects\cdmetapop_package\cdmetapopR\docs\cdmetapopR_function_examples_files/figure-html/summary-ind-cdist-1.png" width="100%" />

## Movement Over Time


``` r
summary_ind(ex_dir, type = "movement", years = 0:9, batch = 0, mc = 0)
```

<img src="C:\Users\allis\OneDrive - The Ohio State University\Research\side_projects\cdmetapop_package\cdmetapopR\docs\cdmetapopR_function_examples_files/figure-html/summary-ind-movement-1.png" width="100%" />

# Individual-Level Genetics

The individual-level genetics functions use genotype columns named like `L0A0`, `L0A1`, `L1A0`, and so on.

## Allele Frequencies by Patch


``` r
allele_frequencies_ind(ex_dir, year = 9, batch = 0, mc = 0)
```

<img src="C:\Users\allis\OneDrive - The Ohio State University\Research\side_projects\cdmetapop_package\cdmetapopR\docs\cdmetapopR_function_examples_files/figure-html/allele-frequencies-by-patch-1.png" width="100%" />

## Mean Allele Frequencies Across Patches

Use `mean_across_patches = TRUE` to summarize allele frequencies across patches for the selected year.


``` r
allele_frequencies_ind(
  ex_dir,
  year = 9,
  batch = 0,
  mc = 0,
  mean_across_patches = TRUE
)
```

<img src="C:\Users\allis\OneDrive - The Ohio State University\Research\side_projects\cdmetapop_package\cdmetapopR\docs\cdmetapopR_function_examples_files/figure-html/allele-frequencies-mean-1.png" width="100%" />

## Heterozygosity by Patch


``` r
heterozygosity_ind(ex_dir, year = 9, batch = 0, mc = 0)
```

<img src="C:\Users\allis\OneDrive - The Ohio State University\Research\side_projects\cdmetapop_package\cdmetapopR\docs\cdmetapopR_function_examples_files/figure-html/heterozygosity-by-patch-1.png" width="100%" />

## Mean Heterozygosity Across Patches


``` r
heterozygosity_ind(
  ex_dir,
  year = 9,
  batch = 0,
  mc = 0,
  mean_across_patches = TRUE
)
```

<img src="C:\Users\allis\OneDrive - The Ohio State University\Research\side_projects\cdmetapop_package\cdmetapopR\docs\cdmetapopR_function_examples_files/figure-html/heterozygosity-mean-1.png" width="100%" />

## Pairwise FST


``` r
pairwise_fst_ind(ex_dir, year = 9, batch = 0, mc = 0)
```

<img src="C:\Users\allis\OneDrive - The Ohio State University\Research\side_projects\cdmetapop_package\cdmetapopR\docs\cdmetapopR_function_examples_files/figure-html/pairwise-fst-1.png" width="100%" />

# Patch Maps from Individual Files

`summary_patch_map()` maps patch locations from the individual files. Point size reflects the number of individuals in each patch.

## All Individuals


``` r
summary_patch_map(
  ex_dir,
  years = c(0, 5, 9),
  batch = 0,
  mc = 0,
  crs = 5070
)
```

<img src="C:\Users\allis\OneDrive - The Ohio State University\Research\side_projects\cdmetapop_package\cdmetapopR\docs\cdmetapopR_function_examples_files/figure-html/summary-patch-map-all-1.png" width="100%" />

## One Disease State

Use `states` to count only individuals in selected disease states.


``` r
summary_patch_map(
  ex_dir,
  years = c(0, 5, 9),
  batch = 0,
  mc = 0,
  states = 1,
  crs = 5070
)
```

<img src="C:\Users\allis\OneDrive - The Ohio State University\Research\side_projects\cdmetapop_package\cdmetapopR\docs\cdmetapopR_function_examples_files/figure-html/summary-patch-map-state-1.png" width="100%" />

## Faceted by Disease State


``` r
summary_patch_map(
  ex_dir,
  years = c(0, 9),
  batch = 0,
  mc = 0,
  states = c(0, 1),
  facet_by_state = TRUE,
  crs = 5070
)
```

<img src="C:\Users\allis\OneDrive - The Ohio State University\Research\side_projects\cdmetapop_package\cdmetapopR\docs\cdmetapopR_function_examples_files/figure-html/summary-patch-map-state-facet-1.png" width="100%" />

# Older Summary Helpers

These functions are still exported and can be useful for specific legacy workflows.

## `age_structure_proportions()`


``` r
age_structure_proportions(
  path = paste0(ex_dir, "/"),
  runs = 1,
  gen = 9,
  species = 0
)
```

```
##               MC1         Avg
## Age1  0.498127341 0.498127341
## Age2  0.202247191 0.202247191
## Age3  0.153558052 0.153558052
## Age4  0.116104869 0.116104869
## Age5  0.082397004 0.082397004
## Age6  0.074906367 0.074906367
## Age7  0.063670412 0.063670412
## Age8  0.052434457 0.052434457
## Age9  0.014981273 0.014981273
## Age10 0.011235955 0.011235955
## Age11 0.011235955 0.011235955
## Age12 0.018726592 0.018726592
## Age13 0.007490637 0.007490637
## Age14 0.003745318 0.003745318
## Age15 0.044943820 0.044943820
## Age16 0.142322097 0.142322097
```

## `dispersal()`

With `plot = FALSE`, `dispersal()` returns a data frame of movement proportions.


``` r
dispersal(
  path = paste0(ex_dir, "/"),
  run = 0,
  batch = 0,
  mc = 1,
  gen = 9,
  species = 0,
  plot = FALSE
)
```

```
##    run0batch0mc0species0 run0batch0mc1species0
## Y0                     0                     0
## Y1                     0                     0
## Y2                     0                     0
## Y3                     0                     0
## Y4                     0                     0
## Y5                     0                     0
## Y6                     0                     0
## Y7                     0                     0
## Y8                     0                     0
## Y9                     0                     0
```

With `plot = TRUE`, it draws a base R barplot and returns the same kind of summary.


``` r
dispersal(
  path = paste0(ex_dir, "/"),
  run = 0,
  batch = 0,
  mc = 0,
  gen = 9,
  species = 0,
  plot = TRUE
)
```

<img src="C:\Users\allis\OneDrive - The Ohio State University\Research\side_projects\cdmetapop_package\cdmetapopR\docs\cdmetapopR_function_examples_files/figure-html/dispersal-plot-1.png" width="100%" />

```
##    Year movers
## 1     0      0
## 2     1      0
## 3     2      0
## 4     3      0
## 5     4      0
## 6     5      0
## 7     6      0
## 8     7      0
## 9     8      0
## 10    9      0
```

## `hets_plot()`


``` r
summary_pop_single <- read.csv(pop_file)
hets_plot(summary_pop_single)
```

<img src="C:\Users\allis\OneDrive - The Ohio State University\Research\side_projects\cdmetapop_package\cdmetapopR\docs\cdmetapopR_function_examples_files/figure-html/hets-plot-1.png" width="100%" />

## `alleles_by_year()`


``` r
alleles_by_year(summary_pop_single, n = 10)
```

<img src="C:\Users\allis\OneDrive - The Ohio State University\Research\side_projects\cdmetapop_package\cdmetapopR\docs\cdmetapopR_function_examples_files/figure-html/alleles-by-year-1.png" width="100%" />

## `size_age_class()`


``` r
size_age_class(class_file)
```

<img src="C:\Users\allis\OneDrive - The Ohio State University\Research\side_projects\cdmetapop_package\cdmetapopR\docs\cdmetapopR_function_examples_files/figure-html/size-age-class-1.png" width="100%" />

# Interactive and External-Run Functions

The following functions are exported, but they launch external software or interactive Shiny apps. They are shown here as code examples but are not run while knitting this document.

## `launch_cdmetapop()`


``` r
launch_cdmetapop(
  pythonFilepath = "C:/path/to/python.exe",
  CDMetaPOPFilepath = "C:/path/to/CDMetaPOP.py",
  runvarsDirectory = "C:/path/to/example_files/",
  runvarsFilename = "RunVars.csv",
  outputDirectory = "test_output"
)
```

## Template Editors


``` r
write_runvars(output_file = "my_new_runvars.csv")
write_popvars(output_file = "my_new_popvars.csv")
write_patchvars(output_file = "my_new_patchvars.csv")
write_classvars(output_file = "my_new_classvars.csv")
```

# Deprecated Internal Compatibility Function

`locus()` is exported for compatibility with older `gstudio` workflows. It is included in the package because the original function is deprecated elsewhere.


``` r
locus(c("0", "1"), type = "snp")
```

```
## [1] "A:A" "A:B"
## attr(,"class")
## [1] "locus"
```

# Session Info


``` r
sessionInfo()
```

```
## R version 4.5.1 (2025-06-13 ucrt)
## Platform: x86_64-w64-mingw32/x64
## Running under: Windows 11 x64 (build 26200)
## 
## Matrix products: default
##   LAPACK version 3.12.1
## 
## locale:
## [1] LC_COLLATE=English_United States.utf8 
## [2] LC_CTYPE=English_United States.utf8   
## [3] LC_MONETARY=English_United States.utf8
## [4] LC_NUMERIC=C                          
## [5] LC_TIME=English_United States.utf8    
## 
## time zone: America/New_York
## tzcode source: internal
## 
## attached base packages:
## [1] stats     graphics  grDevices utils     datasets  methods   base     
## 
## other attached packages:
## [1] ggplot2_4.0.2    cdmetapopR_0.0.1 testthat_3.2.3  
## 
## loaded via a namespace (and not attached):
##  [1] polysat_1.7-7      gtable_0.3.6       xfun_0.52          bslib_0.9.0       
##  [5] poppr_2.9.8        raster_3.6-32      lattice_0.22-7     vctrs_0.6.5       
##  [9] tools_4.5.1        generics_0.1.4     parallel_4.5.1     tibble_3.3.0      
## [13] cluster_2.1.8.1    pkgconfig_2.0.3    Matrix_1.7-3       RColorBrewer_1.1-3
## [17] S7_0.2.1           desc_1.4.3         lifecycle_1.0.5    compiler_4.5.1    
## [21] farver_2.1.2       stringr_1.6.0      brio_1.1.5         fontawesome_0.5.3 
## [25] terra_1.8-54       gdistance_1.6.5    codetools_0.2-20   graph4lg_1.8.0    
## [29] permute_0.9-8      httpuv_1.6.16      htmltools_0.5.8.1  sass_0.4.10       
## [33] yaml_2.3.10        pillar_1.11.1      later_1.4.2        jquerylib_0.1.4   
## [37] seqinr_4.2-36      tidyr_1.3.1        MASS_7.3-65        cachem_1.1.0      
## [41] vegan_2.7-1        boot_1.3-31        nlme_3.1-168       mime_0.13         
## [45] tidyselect_1.2.1   digest_0.6.37      stringi_1.8.7      dplyr_1.1.4       
## [49] reshape2_1.4.5     purrr_1.0.4        labeling_0.4.3     splines_4.5.1     
## [53] ade4_1.7-23        rprojroot_2.1.0    fastmap_1.2.0      grid_4.5.1        
## [57] cli_3.6.5          magrittr_2.0.3     pegas_1.3          pkgbuild_1.4.8    
## [61] ape_5.8-1          withr_3.0.2        shinyBS_0.63.0     scales_1.4.0      
## [65] promises_1.3.3     sp_2.2-0           rmarkdown_2.29     igraph_2.1.4      
## [69] memoise_2.0.1      shiny_1.11.1       evaluate_1.0.4     knitr_1.50        
## [73] mgcv_1.9-3         rlang_1.1.6        Rcpp_1.1.0         xtable_1.8-4      
## [77] glue_1.8.0         adegenet_2.1.11    pkgload_1.4.0      jsonlite_2.0.0    
## [81] R6_2.6.1           plyr_1.8.9
```
