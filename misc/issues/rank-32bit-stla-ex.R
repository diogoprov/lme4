#### https://github.com/lme4/lme4/issues/162

dat <- data.frame(sample   = gl(6, 12,    labels=formatC(10^(1:6), format="d")),
                  operator = gl(2, 6, 72, labels=c("AVR","SCF")),
                  day      = gl(3, 2, 72),
### MM: The '-Inf' below shows that  log10(y)  below is really "wrong";
                  ## OTOH, the example is even slightly more strange then:
                  y = c(1.12456538692733,
    1.04023576431277, 1.12910081120271, 0.581806780532349, 1.07647980145301,
    1.22161328950346, 1.51177691237896, -Inf, 1.19015015315616,
    1.03354099916988, 0.603171609936178, 0.705227192721609, 1.86167501109739,
    1.86277998601675, 1.65574976385051, 1.82224021596912, 1.65385675068902,
    1.71478270723892, 2.07683849212327, 1.94820703790447, 1.81685554129005,
    1.82318675630272, 1.67472636917711, 1.73603762679861, 2.77360793812718,
    2.75584578744623, 2.67174075805986, 3.56033301725792, 2.59346532052226,
    2.88589073071213, 2.95589899305532, 3.07458877850557, 3.09835599261508,
    3.16168022258914, 2.6154384817674, 2.93867350223824, 3.8955447722368,
    3.88888263877041, 3.89083385501686, 3.80615113315833, 3.72231338871737,
    3.77647995701415, 4.08683202931585, 4.0821680901089, 4.20925760538899,
    4.10520504959443, 3.83097220519035, 3.88318253895298, 4.83289909148059,
    4.88285972034546, 4.73031091539232, 4.79413747207678, 4.81689261774979,
    4.91614962524619, 4.96371649333942, 4.90935086757041, 4.85171460752004,
    4.94426774190972, 4.88322016087255, 4.95624730733193, 5.89029646965548,
    5.61555385330924, 5.82949401647961, 5.86877631695349, 5.88521433806452,
    5.85461376554296, 5.9006285826237, 6.07374763216832, 6.09786080600134,
    5.98030329499588, 5.89387938834901, 5.92806626774672))
str(dat)
## 'data.frame':	72 obs. of  4 variables:
##  $ sample  : Factor w/ 6 levels "10","100","1000",..: 1 1 1 1 1 1 1 1 1 1 ...
##  $ operator: Factor w/ 2 levels "AVR","SCF": 1 1 1 1 1 1 2 2 2 2 ...
##  $ day     : Factor w/ 3 levels "1","2","3": 1 1 2 2 3 3 1 1 2 2 ...
##  $ y       : num  3.12 2.88 3.12 1.75 2.88 ...

## Completely balanced:
ftable( xtabs(~operator+sample+day, dat) )
##                  day 1 2 3
## operator sample
## AVR      10          2 2 2
##          100         2 2 2
##          1000        2 2 2
##          10000       2 2 2
##          100000      2 2 2
##          1000000     2 2 2
## SCF      10          2 2 2
##          100         2 2 2
##          1000        2 2 2
##          10000       2 2 2
##          100000      2 2 2
##          1000000     2 2 2

require(lattice)
splom(~ dat) ##--> clear picture  y ~ as.numeric(sample)
xyplot(log10(y) ~ log10(as.numeric(as.character(sample))), dat)

## Given the above picture, it seems *very*  "adventurous" to take
## 1) 'sample' as random effect factor; rather log10(..) should be used as *numeric* fixed effect
## 2) 'operator' (with only 2 levels) as random effect is also a bit extreme


library(lme4)
fitAV3 <- lmer(log10(y) ~ (1|sample)+(1|day)+(1|operator)+
               (1|day:sample)+(1|day:operator)+(1|sample:operator)+
               (1|day:sample:operator),
               control = lmerControl("Nelder_Mead"),
               data = subset(dat, y > 0) )
## No longer seeing this:
##  Warning message:
## In checkZrank(reTrms$Zt, n = n, control, nonSmall = 1e+06) :
##   number of observations <= rank(Z); variance-covariance matrix will be unidentifiable
## MM: No longer happens with new  Matrix 1.1-1 (Dec.21, 2013)

## but with new checks, now get
## Warning message:
## In checkConv(attr(opt, "derivs"), opt$par, checkCtrl = control$checkConv,  :
##   Model failed to converge with max|grad| = 0.00122188 (tol = 0.001)

f.tAV3 <- update(fitAV3,
               control = lmerControl("bobyqa"))
## no warning

fitAV3.nobound <- update(fitAV3,
               control=lmerControl(boundary.tol=0))
f.tAV3.nobound <- update(f.tAV3,
               control=lmerControl(boundary.tol=0))

fitAV3.norestart <- update(fitAV3,
               control=lmerControl(restart_edge=FALSE,boundary.tol=0))
f.tAV3.norestart <- update(f.tAV3,
               control=lmerControl(restart_edge=FALSE,boundary.tol=0))

summary(fitAV3) ## looks "fine"
summary(f.tAV3) ## ditto; but better: the three sigma's are = 0, exactly
mList <- list(fitAV3,f.tAV3,fitAV3.nobound,f.tAV3.nobound,
              fitAV3.norestart,f.tAV3.norestart)

lapply(mList,function(x) which(getME(x,"theta")==0))

myfile <- "fit+pr_AV3.rda"
if(file.exists(myfile)) print(load(myfile)) else {
    system.time(
        pr.AV3 <- profile(fitAV3)
        ## Warning messages:
        ## 1: In zeta(pw * 1.01, start = opt[seqpar1][-w]) :
        ##   slightly lower deviances (diff=-8.2423e-13) detected
        ## 2: In nextpar(mat, cc, i, delta, lowcut, upcut) :
        ##   Last two rows have identical or NA .zeta values: using minstep
        ## 3: In nextpar(mat, cc, i, delta, lowcut, upcut) :
        ##   Last two rows have identical or NA .zeta values: using minstep
        ## 4: In profile.merMod(fitAV3) : non-monotonic profile
        ## 5: In profile.merMod(fitAV3) : non-monotonic profile
        ## 6: In profile.merMod(fitAV3) : non-monotonic profile
    )
    ##  2013-12-28 [nb-mm3]:
    ##    user  system elapsed
    ## 139.352   0.112 139.943
    ##  2013-12-30 [nb-mm3]: with new 'check-conv': 15% slower:
    ##    user  system elapsed
    ## 161.028   0.012 161.569

    system.time(
        p..AV3 <- profile(f.tAV3)
        ## Warning messages:
        ## 1: In profile.merMod(f.tAV3) : non-monotonic profile
        ## 2: In profile.merMod(f.tAV3) : non-monotonic profile
        ## 3: In profile.merMod(f.tAV3) : non-monotonic profile
        )
    ##	2013-12-30 [nb-mm3]: with new 'check-conv':
    ##    user  system elapsed
    ## 147.296   0.000 147.788

    save(fitAV3, f.tAV3, pr.AV3, p..AV3,
	 file=myfile)
}

confint(pr.AV3) # (prettied)
##                  2.5 %     97.5 %
## .sig01      0.01127495 0.05807177
## .sig02      0.                Inf
## .sig03      0.                Inf
## .sig04      0.         0.05530778
## .sig05      0.16340194 0.53108204
## .sig06      0.         0.08005722
## .sig07      0.                Inf
## .sigma      0.03406133 0.05606905
## (Intercept) 0.21048244 0.71334815

stopifnot(all.equal(confint(pr.AV3),
                    confint(p..AV3), tol= 5e-5))## 64bit: see 2.43e-05

##--> hmm... want to have a *match* between all the  ".sig<n>" and the "group" names,
## see vc3 below (etc)
confint(pr.AV3, level = 0.80) # still has the same 3  (0, Inf) intervals

vc3 <- VarCorr(fitAV3)
print(vc3, comp=c("Std.Dev","Var"), formatter=formatC)
noquote(cbind(lme4:::formatVC(vc3, formatter=formatC),
              format(confint(pr.AV3)[-9,], digits=4, drop0trailing=TRUE)))
##                                                               __manually__
##  Groups              Name         Std.Dev.   2.5 %   97.5 %   name{profile}
##  day:sample:operator (Intercept)  0.036138   0.01127 0.05807   .sig01
##  day:sample          (Intercept)  7.3444e-07 0           Inf   .sig02
##  sample:operator     (Intercept)  2.1048e-06 0           Inf   .sig03
##  day:operator        (Intercept)  0.016983   0       0.05531   .sig04
##  sample              (Intercept)  0.28951    0.1634  0.53108   .sig05
##  day                 (Intercept)  0.009331   0       0.08006   .sig06
##  operator            (Intercept)  1.1641e-06 0           Inf   .sig07
##  Residual                         0.042778   0.03406 0.05607   .sigma

## FIXME:
## 1) profile.merMod() should also *store* the 'Groups' that belong to  .sig<nn>
## 2) ................ similar when there are correlations

require(lattice)
xyplot(pr.AV3)
## Warning messages:
## 1: In (function (x, y, ...)  : bad profile for variable 2: skipped
## 2: In (function (x, y, ...)  : bad profile for variable 3: skipped
## 3: In (function (x, y, ...)  : bad profile for variable 7: skipped
