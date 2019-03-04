program define permute
/* Given a datafile, permute each of its variables.
The resulting datafile replicates the exact marginal distribution of each variable,
but contains no information about their joint distribution.
This is a crude way to ensure anonymity, because individual identifiers will not be 
correlated with any of the observed outcomes. */

tempfile original stash

use `1', clear
set more off

unab variables : _all
save `original', replace

* create an empty dataset
gen index = _n
keep index
save `stash', replace

foreach X in `variables' {
	use `original', clear
	keep `X'
	gen random = uniform()
	sort random
	drop random
	gen index = _n
	
	merge 1:1 index using `stash'
	drop _m
	save `stash', replace
}

drop index
save `1'_permuted, replace
set more on

end
