module main;

/****************************************************************************
** SMQTT - Simple Message Telemetry Transport

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

public import server;


int main(string[] argv)
{
	auto server = new Server();//ghgjh
	
	readln();
    return 0;
}

struct firstBlood{
	//who drew first blood? hmm? the vikings?

	shared static this(){
		Util.loadSettings("conf/smtt.conf");

		string logfilePath = Util.settings["logfile_path"]; 
		Util.logfile = File(logfilePath, "a"); 
		enforce(Util.logfile.isOpen(), "Log file handle failed to open!");

		if("startup_cron_job" in Util.settings)
			system(Util.settings["startup_cron_job"].ptr);
	}
	shared static ~this(){
		Util.logfile.close();
		if("shutdown_cron_job" in Util.settings)
			system(Util.settings["shutdown_cron_job"].ptr);
	}
}