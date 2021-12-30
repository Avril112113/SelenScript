# Aega projects
Aega is a build system for SelenScript projects, though it can also be used for plain lua also.

Aega supports multiple different project types;  
- `application` Your normal runnable lua application, entry `main.sel`/`main.lua`  
- `library` A lua library, entry `lib.sel`/`lib.lua`  

Here is a full example of a `aega.json` with all properties set to their defaults  
```jsonc
{
	// Name of the project
	"name": "TestProject",
	// Short description of the project
	"description": "SelenScript test project for testing during development of SelenScript.",

	// Project type, this controls how it's built 
	"type": "application",
	// The source code location for this project, relitive to `aega.json`
	"src": "./main",
	// The output location for this project, relitive to `aega.json`
	"out": "./build",

	// Runtime dependencies
	"dependencies": {
		"luasocket": "2.0.2"
	},
	// Development only dependencies
	// These are either tools or libraries only used in development builds or building process
	"devdependencies": {
		"SelenScript": "0.0.1",
		"SelenScriptLib": "0.0.1"
	},

	// Formatting rules to use for source code
	"formatting": {
		// TODO
	}
}
```
