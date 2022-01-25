# SMQTT
A simple MQTT server for quick and very low bandwidth message transfer
>Project no longer under maintenance. You can create issues if you need it to be resurrected
Its pretty easy to use...if i had documented it.

  But building it is a breeze; you can simply build it with the D command
  
  **$ dmd <.d files> -release**

>i really dont use cmd for multi-file projects its not very productive for me. So save your self some trouble and use any D IDE to open the files when you've cloned of downloaded the repo. I use Visual Studio as its very straight forward; the main function is in **main.d**.

## What does it do?
- The server is a simplified version of MQTT servers; so its uses even less network data and CPU resources.
- The server allows for easy building of messaging apps as it fully supports both secure and anonymous queued messaging.
- The server can be used to power IOT devices (currently powers one i'm yet to finish).
- SMQTT is a ready made communications server for any kind of networked comminucation needs
- The server is being built to support distributed computing for extreme processes in big data networks
- I use this server to power my upcoming Personal AI, HyperD
  
## Errors?
- **Please make sure the conf folder is in the same folder as your executable**
- Ensure **logfile_path** directive points to a valid path of the errorlogs.txt file in the log folder
- **Just go through the whole configuration file (smtt.conf)**
- After these, i cannot help further

## Currently?
- I have created clients for the server in 3 languages, java, javascript, python. 
  - PHP, C#, C++ and D will be coming soon
- I have tested this server for over 96 hours of continous communication with a real time IOT device and it works very well.
- I am hoping to create a standard API that developers can use to access the server irrespective of the language.

Details about how this server works works will be released later. 

Also, clients for the server written in python and java languages have been developed, i'll upload them soon.
HAve fun!!
