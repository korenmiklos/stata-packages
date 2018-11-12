program define xtbootstrap
version 8.2

syntax namelist, data(string) PROGram(string) saveas(string) [REPetition(integer 200) CONDition(string)]

if ("`condition'"=="") {
    local condition 1
}

*di "Ez itt: `data', `condition'"

tempfile data2

* data should be tsset
drop _all
use "`data'"
keep if (`condition')


* save panel ids for sample
tsset
local id `r(panelvar)'
local t `r(timevar)'

egen n = group(`id') if `condition'
egen T = sum(cond(`condition',1,0)), by(n)

count if `condition'
scalar firstNT = r(N)
su n
scalar firstN = r(max)

save `data2', replace

************ now do lots of repetitions

drop _all
capture use "`saveas'"
if (_rc==0) {
    count
    scalar Bmax = r(N)
    * no need to rerun these bootstraps
    scalar list Bmax
}
else {
    save "`saveas'", replace emptyok
    scalar Bmax = 0
}


set output error

while Bmax<`repetition' {
    use `data2', clear
    keep if (`condition')

    /* save seed for replicability */
    local seed `c(seed)'

    * this is bsampling by `id', making sure that NT>=NT(original)
    gen int hanyszor = 0
    scalar eachNT = 0
    while (eachNT<firstNT) {
        scalar now = int(1+uniform()*firstN)
        qui replace hanyszor = hanyszor+1 if n==now

        qui su hanyszor if `condition'
        scalar eachNT = r(sum)
        *noi scalar list eachNT
    }

    *noi tab hanyszor

    qui drop if hanyszor==0
    expand hanyszor

    egen newid1 = seq(), by(`id' `t')
    egen newid = group(`id' newid1)
    drop `id'
    ren newid `id'
    * so that we can use tsset in the new dataset

    * this is the actual program, could also have arguments
    `program'


    drop _all
    set obs 1
    *noi di "`namelist'"
    foreach X of any `namelist' {
        gen `X' = `X'
        * make sure that the program saves something to this scalar!!!
    }
    /* save seed for replicability */
    gen str seed = "`seed'"

    capture append using "`saveas'"
    count
    scalar Bmax = r(N)
    saveold "`saveas'", replace
}

set output proc

end
