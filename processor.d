module processor;

/****************************************************************************
**
** This file is part of the SMQTT server project.
** 
** Copyright (c) 2017 Olagoke Adedamola Farouq
** 
** Contact:  olagokedammy@gmail.com
** 
** SMQTT server is free software: you can redistribute it and/or modify
** it under the terms of the GNU General Public License as published by
** the Free Software Foundation, either version 3 of the License, or
** (at your option) any later version.
**
** SMQTT server is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
** GNU General Public License for more details.
**
** You should have received a copy of the GNU General Public License
** along with SMQTT server.  If not, see <http://www.gnu.org/licenses/>.
**
****************************************************************************/

public import services;

/**
* This is what i call a "hot object". it will be used by 
* different threads at different times on different cores.
*/
class Processor{
	//private char[1024] buffer;
	private Socket sock;
	private Services services;
	private ResponseFormat response;
	private int bufferSize;

	this(){
		this.response = ResponseFormat();
		this.services = new Services();
		this.bufferSize = to!int(Util.settings["buffer_size"]);
	}
	public void processNewClient(Socket client){
		auto newSocket = client.accept();
	
		Util.connectedClients ~= newSocket; //save time stamp, let another thread check if time > 3secs(2actually)
		Util.echo(this.response.executed().and(ResponseFormat.CONNECTED), client);
	}
	public void processClientMessage(Socket client, int clientID){
		//only 200 bytes allowed
		char[200] buffer; //use char[].init
		try{
			auto got = client.receive(buffer); //do injection checks
			string rcID = this._getRegisteredClient(clientID);
			if(got <= 0){
				Util.echo(this.response.notExecuted().and(ResponseFormat.EMPTY_MESSAGE), client);
				if(rcID != null){
					writeln(format("Client[%s] has been disconnected!", rcID));
					this.services.closeClientSession(rcID);
				}
				this.closeClientConn(client,clientID);
				return;
			} else if(got > this.bufferSize)
				got = this.bufferSize; //control buffer size

			string data_ = buffer[0 .. got].idup; //we should log this data
			string[] data = split(data_, to!char(Util.settings["api_token"]));

			switch(buffer[0]){
				case '0':
					if(data.length < 2){
						Util.echo(this.response.notExecuted().and(ResponseFormat.MALFORMED_MESSAGE), client);
						break;
					}
					if(rcID == null){ //not registered!!
						Util.echo(this.response.notExecuted().and(ResponseFormat.NOT_REGISTERED), client);
						break;
					}
					Util.echo(this.services.subscribe(data[1], rcID), client);
					break;
				case '1':
					if(data.length < 3){
						Util.echo(this.response.notExecuted().and(ResponseFormat.MALFORMED_MESSAGE), client);
						break;
					}
					if(rcID == null){ //not registered!!
						Util.echo(this.response.notExecuted().and(ResponseFormat.NOT_REGISTERED), client);
						break;
					}
					Util.echo(this.services.publish(data[2], data[1], rcID), client);
					break;
				case '2':
					if(data.length < 3){
						Util.echo(this.response.notExecuted().and(ResponseFormat.MALFORMED_MESSAGE), client);
						break;
					}
					if(rcID == null){ //not registered!!
						Util.echo(this.response.notExecuted().and(ResponseFormat.NOT_REGISTERED), client);
						break;
					}
					Util.echo(this.services.publish(data[2], data[1], rcID), client);
					break;
				case '3':
					if(data.length < 2){
						Util.echo(this.response.notExecuted().and(ResponseFormat.MALFORMED_MESSAGE), client);
						break;
					}
					Util.echo(this.services.registerClient(data[1], client),client);
					break;
				default:
					Util.echo(this.response.notExecuted().and(ResponseFormat.INVALID_SERVICE), client);
					break;
			}

			writefln("treated client[%s]> [raw] '%s'", clientID, data_);

		} catch (Exception err){
			Util.logError(format("%s in %s(&s)",err.msg, err.file, err.line));
			writeln("--debug: Fatal Server Error 3!");
			Util.echo(this.response.notExecuted().and(ResponseFormat.SERVER_ERROR), client);
		} catch (Error err){
			Util.logError(format("%s in %s(&s)",err.msg, err.file, err.line));
			writeln("--debug: Fatal Server Error 4!");
			Util.echo(this.response.notExecuted().and(ResponseFormat.SERVER_ERROR), client);
		}

	}
	
	private string _getRegisteredClient(int cclientID){ //connected client id
		foreach(rcID, client; Util.registeredClients)
			if(client == Util.connectedClients[cclientID])
				return rcID;
		return null;
	}
	private void closeClientConn(Socket client, int clientID=-1){ //implement in body
		if(clientID != -1){
			Util.connectedClients = remove(Util.connectedClients, clientID);
		}
		client.shutdown(SocketShutdown.BOTH);
		client.close();
	}
}

/+
** Data Format
* COMMAND, channel, DATA
* 0 | 1 | 2 | 3, <byte>, <byte>  == sub, pub , init, not
** Return format
* ACKNOWLEDGEMENT, EXECUTION
* 1 | 2, 1 | 2 -> 1 - good | bad

* 1|2 - publish|notice , <data>
+/

// sub to notif self/notify/+
// you can only sub to notifications under a particular topic