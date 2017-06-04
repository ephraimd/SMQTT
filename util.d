module util;

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

public import std.stdio, std.socket, std.string, std.conv, std.algorithm, std.parallelism, core.stdc.stdlib;
import std.file;

struct Util{
	/**
	* {channel1 : ['sid':sock, 'sid':sock, ...], channel2 : ['sid':sock, 'sid':sock, ...], ...}
	*/
	public static string[][string] channel;
	public static Socket[string] registeredClients;
	public static Socket[] connectedClients;
	public static Socket currentClient;
	public static File logfile;
	public static string[string] settings;

	public static void logError(string error){
		Util.logfile.writeln(error);
		Util.logfile.flush();
	}
	public static void loadSettings(string iniPath){
		auto fh = File(iniPath, "r");
		enforce(fh.isOpen(), "Server Settings file failed to open!");
		while(!fh.eof()){
			auto data = chomp(fh.readln());
			if(data.length < 3 || data[0] == '#')
				continue;
			auto spl = split(data, '=');
			enforce(spl.length >= 2, "Bad/Corrupted Server Settings file format");
			if(spl.length > 2)
				spl[1] = Util.implode(spl[1..$], '=');
			Util.settings[strip(spl[0])] = strip(spl[1]);
		}
		fh.close();
	}
	public static bool echo(ResponseFormat message, Socket client){
		client.send(to!string(message.getResponseData()));
		return true;
	}
	public static bool echo(string message, Socket client){
		client.send(message);
		return true;
	}
	public static string implode(string[] data, char knot){
		string buf="";
		for(int i=0;i<data.length; i++){
			if(i == data.length-1)
				buf ~= data[i];
			else 
				buf ~= data[i] ~ knot;
		}
		return buf;
	}
}


struct ResponseFormat{
	public char[] responseData;
	private bool isChar = true;
	public string sResponse;
	public static char ACKNOWLEDGED = 49, // '1'
		NOT_ACKNOWLEDGED = 50, // '2'
		EXECUTED = 49,
		NOT_EXECUTED = 50,
		EMPTY_MESSAGE = 49,
		MALFORMED_MESSAGE = 50,
		INVALID_SERVICE = 51,
		SERVER_ERROR = 52,
		LOGIC_ERROR = 53,
		EXISTING_CLIENT = 54,
		RESTRICTED_CHANNEL = 55,
		NOT_ON_CHANNEL = 56,
		INVALID_CHANNEL = 57,
		INVALID_SUBSCRIPTION = 58, //wen u misuse the + regex in the channel
		NOT_REGISTERED = 59,
		CONNECTED = 60,
		PUBLISH_RESPONSE = 49,
		NOTICE_RESPONSE = 50,
		TOKEN = '|';

	public ResponseFormat response(char[] data){
		this.responseData = data;
		this.isChar = true;
		return this; //we might need to change this means later
	}
	public ResponseFormat publish(string channel, string rcid, string data){
		this.sResponse = [ResponseFormat.PUBLISH_RESPONSE,ResponseFormat.TOKEN].idup ~ channel ~ ResponseFormat.TOKEN ~ rcid ~ ResponseFormat.TOKEN ~ data;
		this.isChar = false;
		return this;
	}
	public ResponseFormat notify(string data, string channel, string rcid){
		this.sResponse = [ResponseFormat.NOTICE_RESPONSE,ResponseFormat.TOKEN].idup ~ channel ~ ResponseFormat.TOKEN ~ rcid ~ ResponseFormat.TOKEN ~ data;
		this.isChar = false;
		return this;
	}
	public ResponseFormat and(char cmd){
		this.responseData ~= [ResponseFormat.TOKEN,cmd];
		return this;
	}
	public string getResponseData(){
		if(this.isChar)
			return to!string(this.responseData);
		return sResponse;
	}
	public ResponseFormat executed(){
		return ResponseFormat.response([ResponseFormat.ACKNOWLEDGED,ResponseFormat.TOKEN,ResponseFormat.EXECUTED]);
	}
	public ResponseFormat notExecuted(){
		return ResponseFormat.response([ResponseFormat.ACKNOWLEDGED,ResponseFormat.TOKEN,ResponseFormat.NOT_EXECUTED]);
	}
	public ResponseFormat notAuth(){
		return ResponseFormat.response([ResponseFormat.NOT_ACKNOWLEDGED,ResponseFormat.TOKEN,ResponseFormat.NOT_EXECUTED]);
	}
}

//set options for client timeouts based on channel group
//optimize server for heavy load usage
///smt thread
// remove all over time connections
// remove channels without subs