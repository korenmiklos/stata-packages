program define gridgmm
    syntax, program(string) moments(varlist numeric) parameters(namelist) low(numlist) high(numlist) steps(numlist >0 integer) [gmmweight(name) save(namelist)]

    * check consistency first
    local M : word count `moments'
    local K : word count `parameters'
    local pluszK : word count `save'

    local Klow : word count `low'
    local Khigh : word count `high'
    local Ksteps : word count `steps'

    if (`K'!=`Klow')|(`K'!=`Khigh')|(`K'!=`Ksteps') {
        di in red "Set LOW, HIGH and STEPS for all parameters!"
        error(99)
    }

    if (`K'>`M') {
        di in red "You need at least as many moments as parameters!"
        error(99)
    }



    tempname Remaining High Low Steps Overall J mvec A minJ

    mat `mvec' = J(`M',1,0)
    if ("`gmmweight'"=="") {
        matrix `A' = I(`M')
    }
    else {
        matrix `A' = `gmmweight'
    }

    matrix `High' = J(`K',1,0)
    matrix `Low' = J(`K',1,0)
    matrix `Steps' = J(`K',1,0)
    matrix `Remaining' = J(`K',1,0)

    scalar `minJ' = 9999

    scalar `Overall' = 1

    forval k=1/`K' {
        local highk : word `k' of `high'
        local lowk : word `k' of `low'
        local stepsk : word `k' of `steps'

        if (`highk'<`lowk') {
            di in red "HIGH must not be lower than LOW!"
            error(99)
        }

        if (`highk'==`lowk') {
            mat `Steps'[`k',1] = 1
        }
        else {
            mat `Steps'[`k',1] = `stepsk'
        }
        scalar `Overall' = `Overall'*`Steps'[`k',1]
        mat `High'[`k',1] = `highk'
        mat `Low'[`k',1] = `lowk'
    }


    di in gre "-----------------------"
    di in gre "Overall required steps: " in ye `Overall'
    di in gre "Now running testrun...."
    * test run
    di c(current_time)
    forval k=1/`K' {
        local parameter : word `k' of `parameters'
        *noi di "Ez itt: `parameter'/`parameters'"
        scalar `parameter' = `Low'[`k',1]
    }
    * call program
    `program'
    di c(current_time)

    * di in gre "Expected running time: " in ye expected in gre " seconds = " in ye expected/60 in gre " minutes = " in ye expected/3600 in gre " hours "



    mat `Remaining' = `Steps'+J(`K',1,1)

    while (`Remaining'[1,1]>0) {

        * do something
        forval k=1/`K' {
            local parameter : word `k' of `parameters'
            *noi di "Ez itt: `parameter'/`parameters'"
            scalar `parameter' = `Low'[`k',1]+(`Remaining'[`k',1]-1)/`Steps'[`k',1]*(`High'[`k',1]-`Low'[`k',1])
        }

        * call program
        `program'

        * save sample mean of moments
        forval i=1/`M' {
            local mi : word `i' of `moments'
            noi su `mi', meanonly
            mat `mvec'[`i',1] = r(mean)
        }

        * this is what we minimize
        mat `J' = `mvec''*`A'*`mvec'
        if `J'[1,1]<`minJ' {
            scalar `minJ' =`J'[1,1]
            forval k=1/`K' {
                local parameter : word `k' of `parameters'
                noi di in gre "`parameter' = " in ye `Low'[`k',1]+(`Remaining'[`k',1]-1)/`Steps'[`k',1]*(`High'[`k',1]-`Low'[`k',1])
                scalar grid_`parameter' = `Low'[`k',1]+(`Remaining'[`k',1]-1)/`Steps'[`k',1]*(`High'[`k',1]-`Low'[`k',1])
                foreach XX of any `save' {
                    scalar grid_`XX' = `XX'
                }
            }

            * save stuff
            qui mat accum SS = `moments', nocons dev
            mat SS=SS/r(N)
            mat khi =`mvec''*inv(SS)*`mvec'
            di in gre "J=" in ye `minJ' in gre "   Chi^2(`M'-`K'-`pluszK')=" in ye khi[1,1] in gre "  p=" in ye 1-invchi2(`M'-`K'-`pluszK',khi[1,1])
        }


        mat `Remaining'[`K',1] = `Remaining'[`K',1]-1
        forval k=2/`K' {
            if `Remaining'[`k',1]==0 {
                mat `Remaining'[`k',1] = `Steps'[`k',1]+1
                mat `Remaining'[`k'-1,1] = `Remaining'[`k'-1,1]-1
            }
        }

    }

    /* rename parameters to get rid of grid_ prefix */
    foreach XX of any `save' {
        scalar `XX' = grid_`XX'
        scalar drop grid_`XX'
    }


end
