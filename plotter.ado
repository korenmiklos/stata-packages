program define plotter
    syntax [if], x(varname) y(varname)  [z(varname) bins(integer 20) scatter categ overlay]

 
**** plotter.ado
**** Miklos Koren
**** http://miklos.koren.hu/research/

**** This .ado program creates a line plot of local medians. It breaks the variable `x' into **** `bins' number of quantiles and calculates the median of variable `y' for each quantile, **** plotting these medians in a line plot of `y' against `x'. Useful to visualize **** scatterplots with many observations, potential nonlinearities, and outliers. The **** scatterplot itself may be included (`scatter' option).

**** It can create separate graphs for categories indicated by the quantiles of the optional **** variable `z', or, bye values of `z' if `z' is a categorical variable (`categ' option). **** The graphs can be separate (default) or overlaid on one graph (`overlay'). The use of **** an `if' clause is allowed. */

marksample tolouse
tempvar xbin zbin ymed xmed zgroup egy

/* defaults */
if ("`z'"=="") {
    gen `egy' = 1
    local z `egy'
}


/* create bins */
qui egen `xbin' = cut(`x'), group(`bins')

qui ins `z' if `tolouse'
if (r(N_unique)<=2)|("`categ'"!="") {
    /* no bins required for categ vars */

    qui gen `zbin' = `z'
    qui su `z' if `tolouse'

    qui egen `zgroup' = group(`zbin') if `tolouse'
    qui su `zgroup' if `tolouse'
    local maximum  `r(max)'


    local parancs ""
    local opcio ""
    forval i=1/`maximum' {
        qui su `zbin' if `zgroup'==`i' & `tolouse'
        local szam `r(mean)'

        local parancs "`parancs' (line `ymed' `xmed' if `zgroup'==`i' & `tolouse', sort lwidth(medthick))"
        local opcio `"`opcio' `i' "`z'=`szam'""'
    }

    local categ "categ"

}
else {
    egen `zbin' = cut(`z') if `tolouse', group(`bins')
}

/* calculate median for each bin */
qui egen `ymed' = median(`y') if `tolouse', by(`xbin' `zbin')
qui egen `xmed' = median(`x') if `tolouse', by(`xbin' `zbin')

/* create labels */
label var `xmed' `x'
label var `ymed' `y'
label var `zbin' `z'

/* the graph we've all been waiting for */
if ("`scatter'"=="") {
    if ("`categ'"=="categ")&("`overlay'"!="") {
        /* do it for multiple categs */
        tw `parancs' if `tolouse', legend(order(`opcio'))
    }
    else {
        tw (line `ymed' `xmed' if `tolouse', sort lwidth(medthick)) , by(`zbin')
    }
}
else {
    tw (scatter `y' `x' if `tolouse', msize(vtiny) )/*
    */ (line `ymed' `xmed' if `tolouse', sort lwidth(thick)) , by(`zbin')
}


end
