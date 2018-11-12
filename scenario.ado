program define scenario
    syntax, DOfile(string) PARAMfile(string) save(namelist)

/* temp definitions */
tempname K
tempfile params results

/* read paramfile, determine number of scenarios */
preserve
use `paramfile', clear
count
local K `r(N)'

di "`K'"

gen int _scenid=_n
sort _scenid
save `params', replace

/* empty results dataset */
drop _all
gen int _scenid=.
sort _scenid
save `results', replace emptyok

restore

/* for each scenario: load parameters, run dofile, save results */
forval k=1/`K' {
    di `k'
    preserve

    /* read in scalars from paramfile */
    drop _all
    scalar drop _all
    use if _scenid==`k' using `params'

    foreach XX of var _all {
        qui su `XX'
        scalar `XX' = r(mean)
    }
    restore

    /* now do all the calculations */
    qui do `dofile'

    /* save scalars */
    drop _all
    set obs 1
    gen int _scenid=`k'
    foreach X of any `save' {
        gen `X' = `X'
    }
    sort _scenid
    merge _scenid using `params', nokeep
    drop _merge

    /* append to existing results */
    append using `results'
    save `results', replace
}

end
