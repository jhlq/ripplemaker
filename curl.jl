#curl -X POST -d '{ "method" : "account_info", "params" : [ { "account" : "rHb9CJAWyB4rj91VRWn96DkukG4bwdtyTh"} ] }' https://s1.ripple.com:51234

function makemethod(cmd)
	return """{"method":"$cmd"}"""
end
function makemethod(cmd,ops::Array) #ops=["ledger_hash" "2A213C0B2EA3A2585039658CB8CB13819815CD85B0FD592B37811E5A4B1ECDB1"; "transactions" "true"]
	request="""{"method":"$cmd","params":[{ """
	nops=length(ops[:,1])
	if nops<1
		error("Empty options vector")
	end
	request*=""" "$(ops[1,1])":"$(ops[1,2])" """
	for nop in 2:nops
		request*=""","$(ops[nop,1])":"$(ops[nop,2])" """
	end
	request*="}]}"
end
function curlreq(request)
	run(`curl -X POST -d $request https://s1.ripple.com:51234` |> "reply.txt")
	rf=open("reply.txt","r")
	reply=readall(rf)
	close(rf)
	Rm.sto.reply=reply
	return reply
end
function curlreq(cmd,ops::Array)
	request=makemethod(cmd,ops)
	curlreq(request)
end
