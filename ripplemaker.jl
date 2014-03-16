#Rm.req("account_tx",["account" acc;"ledger_index_min" -1;"limit" 3])

module Rm
export req

include("curl.jl")
include("marketdepth.jl")

type Storage
	wsc::String
	wsport::Int
	rpcc::String
	rpcport::Int
	reply::String
end
sto=Storage("wss://s1.ripple.com",443,"https://s1.ripple.com",51234,"Nothing received.")
using PyCall
cc = pyimport("websocket")[:create_connection]
#rws = cc(sto.wsc,sto.wsport)
type acc
	address::String
	secret::String
end
account=acc("rGDWKWni6exeneJdNbEZ3nVX3Rrw5VG1p1","sss")
type WS
	r::PyObject
	isvalid::Bool
end
ws=WS(0,false)#cc(sto.wsc,sto.wsport),true)

#streamledger="""{"command":"subscribe","id":0,"streams":["ledger"]}"""
#accinfo="""{"command":"account_info","account":"r3kmLJN5D28dHuH8vZNUZpMC43pEHpaocV"}"""
#req=accinfo
#rws[:send](req)
#reply=ripplesocket[:recv]()
#println(reply)

function find(str::String,reply=sto.reply;delim='}')
	loc=search(reply,str)
	if loc[1]==0
		return "Not found. "
	end
	le=loc[end]
	while reply[le]!=delim 
		le+=1
	end
	f1=reply[loc[1]:le]
	return f1,le	
end
function getnum(str::String)
	m=match(r"[0-9]",str)
	b=m.offset
	while !ismatch(r"[^0-9.]",str[b:(b+1)])
		b+=1
	end
	return float(str[m.offset:b])
end	
function makereq(cmd)
	return """{"command":"$cmd"}"""
end
function makereq(cmd,ops) #ops=["ledger_hash" "2A213C0B2EA3A2585039658CB8CB13819815CD85B0FD592B37811E5A4B1ECDB1"; "transactions" "true"]
	request="""{"command":"$cmd" """
	nops=length(ops[:,1])
	for nop in 1:nops
		request*=""","$(ops[nop,1])":"$(ops[nop,2])" """
	end
	request*="}"
end
function addop(req,op)#format op=["account_index" "42"]
	treq=req[1:(end-1)]
	treq*=""","$(op[1])":"$(op[2])"}"""
	return treq
end
function req(request,tries=3)
	if request[1]!='{'
		request=makereq(request)
	end
	try
		println("Sending.. $request")
		ws.r[:send](request)
		println("Receiving..")
		reply=ws.r[:recv]()
		println("Returning..")
		return reply
	catch erx
		if tries<1
			return erx
		end
		ws.r=cc(sto.wsc,sto.wsport)
		return req(request,tries-1)
	end
end
function req(cmd,ops::Array)
	if ws.isvalid
		request=makereq(cmd,ops)
		req(request)
	else
		curlreq(cmd,ops)
	end
end

function setaccount(acc)
	Rm.account.address=acc
end
function setsecret(sec)
	Rm.account.secret=sec
end
function account_info(account;strict=false,index=false,ledger_hash=false,ledger_index=false)
	accinfo="""{"command":"account_info","account":"$account" """
	ops=["strict" strict;"index" index;"ledger_hash" ledger_hash;"ledger_index" ledger_index]
	for nop in length(ops[:,1])
		if ops[nop,2]!=false
			accinfo*=""","$(ops[nop,1])":"$(ops[nop,2])" """
		end
	end
	accinfo*="""}"""
	req(accinfo)
end
account_info()=account_info(account.address)
function account_lines(account;account_index=0,peer=false,peer_index=0)
	acclin="""{"command":"account_lines","account":"$account","account_index":"$account_index","""
	if peer!=false
		acclin*=""" "peer":"$peer","""
	end
	acclin*=""" "peer_index":"$peer_index"}"""
	req(acclin)
end
function account_offers(account)
	request="""{"command":"account_offers","account":"$account"}"""
	req(request)
end
function account_tx(account)
	request="""{"command":"account_tx","account":"$account"}"""
	req(request)
end
function book_offers(currency1,issuer1,currency2="XRP",issuer2="";limit=3)
	creq="""{"method":"book_offers","params":[{  "taker_gets":"""
	if currency1=="XRP"
		tg="""{"currency":"XRP"}"""
	else
		tg="""{"currency":"$currency1","issuer":"$issuer1"}"""
	end
	creq*=tg
	creq*=""","taker_pays":"""
	if currency2=="XRP"
		tp="""{"currency":"XRP"}"""
	else
		tp="""{"currency":"$currency2","issuer":"$issuer2"}"""
	end
	creq*=tp
	creq*=""","limit":$limit }]}"""
#	{"currency":"$currency1","issuer":"$issuer1"} ,"taker_pays":{"currency":"$currency2"},"limit":$limit }]}"""
	curlreq(creq)
end
end #rm
