module server;

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

public import processor;


class Server{
	private bool is_running = false;
	private string host;
	private ushort port;
	private Socket server_handle;
	private SocketSet readSet;
	private Processor processor;

	this(){
		this.host = Util.settings["default_host"];
		this.port = to!ushort(Util.settings["default_port"]);
		this.processor = new Processor();
		this.connect();
		this.handle();
		this.disconnect();
	}
	private void connect(){
		this.server_handle = new Socket(AddressFamily.INET, SocketType.STREAM);
		this.server_handle.bind(new InternetAddress(this.port));
		this.server_handle.listen(to!int(Util.settings["connection_backlog"]));
		this.server_handle.blocking = (Util.settings["is_server_blocking"] == "false");
		this.readSet = new SocketSet();
		this.is_running =true;
		this.show(format("Server started at %s on %s", this.host,this.port));
	}
	private void handle(){
		while(this.is_running){
			this.readSet.reset();
			this.readSet.add(this.server_handle);
			foreach(client; Util.connectedClients)
				this.readSet.add(client);
			this.listener(); //listens for new client data and connections
			/*string t = readln();
			if(t == "exit"){
				break;
			}*/
		}
	}
	private void listener(){
		if(Socket.select(this.readSet, null, null)) {
			foreach(cid, client; parallel(Util.connectedClients)){ //used parallel cos in cases of heavy loads (5000)
				if(this.readSet.isSet(client)) {
					this.processor.processClientMessage(client, cid); //should be new thread
				}
			}
			if(this.readSet.isSet(this.server_handle)) {
				this.processor.processNewClient(this.server_handle);
			}
		}
	}
	private void disconnect(){
		this.is_running =false;
		this.server_handle.shutdown(SocketShutdown.BOTH);
		this.server_handle.close();
	}
	/**
	* useful for need to integrate with other forms of ui
	*/
	private void show(string data){
		writeln(data);
	}
}
