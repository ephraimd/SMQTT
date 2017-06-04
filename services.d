module services;

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

public import messagequeue;


/**
* Class contains all services provided by the server
*/
class Services{
	ResponseFormat response;
	private string notifychannel;

	this(){
		this.response = ResponseFormat(); 
		this.notifychannel = Util.settings["notifications_channel"];
	}
	public ResponseFormat registerClient(string clientUID, Socket client){
		if(this.isRegistered(client)) //dont allow them if someone else has this id online
			return this.response.notExecuted().and(ResponseFormat.EXISTING_CLIENT);

		Util.registeredClients[clientUID] = client; //so we can track you
		//this.notifyAll(format("Client[%s] is online!", clientUID), clientUID); //dont do this. security dont show client name to all!!!
		writefln("client[%s] registered!",clientUID);
		return this.response.executed();
	}
	public ResponseFormat unsubscribe(string channel, string rclientID){
		if(!this.isSubscribed(rclientID, channel))
			return this.response.notExecuted().and(ResponseFormat.NOT_ON_CHANNEL);

		remove(Util.channel[channel], countUntil(Util.channel[channel], rclientID));
		if(Util.channel[channel].length == 0) //removes empty channel
			Util.channel.remove(channel);

		this.notifyAll("unsubscribed", rclientID, channel);
		writefln("client[%s] unsubscribed from channel[%s] ",rclientID, channel);
		return this.response.executed(); 
	}
	public ResponseFormat subscribe(string channel, string rclientID){
		if(isSubscribed(rclientID, channel)){
			writefln("client[%s] already subscribed to channel[%s] ",rclientID, channel);
		   return this.response.executed();
		}

		Util.channel[channel] ~= rclientID;

		this.notifyAll("subscribed", rclientID, channel);
		writefln("client[%s] subscribed to channel[%s] ",rclientID, channel);
		return this.response.executed(); 
	}
	
	public ResponseFormat publish(string message, string channel, string rclientID){
		if(channel == this.notifychannel) //first rule-> u cant publish on restricted channels
			return this.response.notExecuted().and(ResponseFormat.RESTRICTED_CHANNEL);
		else if(!this.isSubscribed(rclientID, channel)) //rule 2: you Have to be a memeber of that channel
			return this.response.notExecuted().and(ResponseFormat.NOT_ON_CHANNEL);
		auto channels = Util.channel;
		//writeln(channels);
		try{
			if(channel in channels){ //convert all dangerous channel chars. do general injection prevention
				foreach(rcID; channels[channel]){
					if(rcID == rclientID || !isRegistered(rcID))
						continue;

					Util.echo(this.response.publish(channel, rclientID, message), Util.registeredClients[rcID]);
				}
				writefln("client[%s] published message[%s] on channel[%s] ",rclientID, message, channel);
				return this.response.executed();
			} else
				return this.response.notExecuted().and(ResponseFormat.INVALID_CHANNEL);
			
		} catch (Exception err){
			Util.logError(format("%s in %s(&s)",err.msg, err.file, err.line));
			writeln("--debug: Fatal Server Error 5!");
			return this.response.notExecuted().and(ResponseFormat.LOGIC_ERROR);
		}
	}
	public ResponseFormat notifyAll(string message, string rclientID, string channel){
		if(this.isSubscribedchannel(this.notifychannel))
			foreach(rcid; Util.channel[this.notifychannel]){
				if(rcid == rclientID || !this.isSubscribed(rcid, channel)) //if self or not on channel
					continue;
				if(rcid in Util.registeredClients) //also only if registered
					Util.echo(this.response.notify(message, channel, rclientID), Util.registeredClients[rcid]);
			}
		return this.response.executed();
	}

	public bool isSubscribed(string rclientID, string channel){
		if(channel in Util.channel)
			if(countUntil(Util.channel[channel], rclientID) != -1)
				return true;
		return false;
	}
	public bool isSubscribedchannel(string channel){
		if(channel in Util.channel)
			return true;
		return false;
	}
	public bool closeClientSession(string rclientID){
		//unsubscribe them from all channels
		if(rclientID != null){
			foreach(channel; Util.channel[rclientID]){ 
				this.unsubscribe(channel, rclientID);
			}
			//remove them from our database
			this.deRegister(rclientID);
		}
		return false;
	}
	public bool isRegistered(string rclientID){
		if(rclientID in Util.registeredClients)
			return true;
		return false;
	}
	public bool isRegistered(Socket client){
		if(client !is null)
			foreach(clent; Util.registeredClients)
				if(client == clent)
					return true;
		return false;
	}
	public bool deRegister(string rclientID){
		if(rclientID in Util.registeredClients)
			return Util.registeredClients.remove(rclientID);
		return false;
	}
}


/*
the smart thread will close unregistered clients
remove channels that have been empty for sometime  jkbjv hvjyh
check list of registered clients for client that have issues
goota fix this part quick

//////////// the settings file will hold values for
list of restricted channels
max connection to registration interval
backlog
message buffer size
max,min channel length
max,min client id length
	*/