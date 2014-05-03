using JSON
using Requests

url="http://localhost:5990/v1"
acc="rw8iVnARvhQ3WNMUEAaamSHqBEGzTrnAEE"
cur=["CAD","r3ADD8kXSUKHd6zTCKfnKT3zV9EZHjzp1S"]

function balance(raw::Bool,account::String=acc)
	#JSON.parse(readall(`curl $url/accounts/$acc/balances`))
	if raw
		return get("$url/accounts/$account/balances")
	else
		return JSON.parse(get("$url/accounts/$account/balances").data)
	end
end
balance()=balance(false,acc)
function balance(cur::Array,account::String=acc)
	stuff=0
	if cur[2]==""
		stuff=Array(Dict{String,Any},0)
	end
	r=balance(false,account)
	if r["success"]==true
		for c in r["balances"]
			if cur[2]==""
				if c["currency"]==cur[1]
					push!(stuff,c)
				end
			elseif c["counterparty"]==cur[2] && c["currency"]==cur[1]
				return c
			end
		end
		return stuff
	else
		return r	
	end
end
balance(cur::String,account::String=acc)=balance([cur,""],account)
function getpath(destination,amount::Array=[10,"XRP"],source=acc)
	am="$(amount[1])+$(amount[2])"
	if length(amount)==3
		am*="+$(amount[3])"
	end
	r=JSON.parse(get("$url/accounts/rw8iVnARvhQ3WNMUEAaamSHqBEGzTrnAEE/payments/paths/rwbSHNaVZGM14T7UNHDEWrwjUgdCfNQCcB/$am").data)
	if r["success"]==true
		return r["payments"]
	else
		return r
	end
end
function trustlines(account::String=acc)
	JSON.parse(get("$url/accounts/$account/trustlines").data)
end
function notifications(tx_hash::String,account::String=acc)
	r=JSON.parse(get("$url/accounts/$account/notifications/$tx_hash").data)
	if r["success"]==true
		return r["notification"]
	else
		return r
	end
end
function connected()
	JSON.parse(get("$url/server/connected").data)
end
function server()
	JSON.parse(get("$url/server").data)["rippled_server_status"]
end
function tx(hash)
	JSON.parse(get("$url/tx/$hash").data)
end
function uuid()
	json(JSON.parse(get("$url/uuid").data)["uuid"])[2:end-1]
end
