program define selectdir, rclass

    /* handle different paths */
    local currentdir `c(pwd)'
    foreach X of any `0' {
        capture chdir "`X'"
        if _rc==0 {
            local datastore `X'
        }
    }
    qui chdir "`currentdir'"

    return local found "`datastore'"

end
