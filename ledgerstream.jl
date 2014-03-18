using PyCall
cc = pyimport("websocket")[:create_connection]

type Stream
	messages::Array
	currentmsg::Int
	alive::Bool
	ws::PyObject
end
stream=Stream(fill!(Array(String,99),""),1,true,cc("wss://s1.ripple.com",443))

function startstream(verbose=true)
	streamledger="""{"command":"subscribe","id":0,"streams":["ledger"]}"""
	stream.ws[:send](streamledger)
	stream.messages[1]=stream.ws[:recv]()
	println(stream.messages[1])
	stream.currentmsg+=1

	while (stream.alive)
		sleep(1)
		newreply=stream.ws[:recv]()
		if stream.messages[stream.currentmsg]!=newreply
			stream.messages[stream.currentmsg]=newreply			
			stream.currentmsg+=1
			if verbose
				println(newreply)
			end
		end
		if stream.currentmsg==99
			stream.currentmsg=1
		end
	end
end
@async startstream(false) #to start in background, input may lag during recv
