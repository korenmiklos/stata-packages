program define save_all_to_json
	local outputs : all scalars
	foreach X in `outputs' {
		save_to_json ../exhibits/scalar/`X' `X'
	}
end
