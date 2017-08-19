<!---
	Name: dribbbleCFC
	API Docs: http://www.dribbble.com/api
	Created: 8/6/2010
	Last Updated: 8/6/2010
	History:
		8/6/2010: dribbbleCFC - Initial creation
	Purpose: A ColdFusion wrapper for the Dribbble showcase API
	Version: Listed in contructor
--->
<cfcomponent hint="A ColdFusion wrapper for the Dribbble interface showcase API" displayname="dribbbleCFC" output="false">

	<cfscript>
		VARIABLES.version = '0.1';
		VARIABLES.appName = 'dribbbleCFC';
		VARIABLES.lastUpdated = DateFormat(CreateDate(2010,08,06),'mm/dd/yyyy');
		VARIABLES.apiRoot = 'http://api.dribbble.com';
	</cfscript>

	<!---
		########################
		##	 INTERNAL METHODS
		########################
	--->
	<cffunction name="init" description="Initializes the CFC, returns itself" returntype="dribbbleCFC" access="public" output="false">
		<cfreturn THIS>
	</cffunction>

	<cffunction name="currentVersion" description="Returns current version" returntype="string" access="public" output="false">
		<cfreturn VARIABLES.version>
	</cffunction>

	<cffunction name="lastUpdated" description="Returns last updated date" returntype="date" access="public" output="false">
		<cfreturn VARIABLES.lastUpdated>
	</cffunction>

	<cffunction name="introspect" description="Returns detailed info about this CFC" returntype="struct" access="public" output="false">
		<cfreturn getMetaData(this)>
	</cffunction>

	<cffunction name="dumpMe" returntype="void">
		<cfargument name="variable" required="true" type="any">
		<cfdump var="#ARGUMENTS.variable#" label="dumpMe">
		<cfabort>
	</cffunction>

	<cffunction name="callDribbble" description="The actual http call to dribbble" returntype="struct" access="private" output="false">
		<cfargument name="attr" required="true" type="struct">

		<cfscript>
			var LOCAL = {};
			var cfhttp = {};
			// what fieldtype will this be?
			LOCAL['fieldType'] = iif( ARGUMENTS.attr['method'] == 'GET', De('URL'), De('formField') );
		</cfscript>

		<cfhttp attributecollection="#ARGUMENTS.attr#"></cfhttp>

		<cfreturn cfhttp>
	</cffunction>

	<cffunction name="prepDataCall" description="Prepares data for call to dribbble servers" returntype="struct" access="private" output="false">
		<cfargument name="config" type="struct" required="true">

		<cfscript>
			var LOCAL = {};
			LOCAL['error'] = '';
			LOCAL['returnColdFusion'] = false;
			LOCAL['attributes'] = {};

			// does the user want a coldfusion object returned?
			if (ARGUMENTS['config']['format'] EQ 'coldfusion') {
				LOCAL['returnColdFusion'] = true;
			}

			// finish setting up the attributes for the http call
			LOCAL['attributes']['url'] = VARIABLES.apiRoot & ARGUMENTS['config']['url'];
			LOCAL['attributes']['method'] = ARGUMENTS['config']['method'];

			try {
				LOCAL['data'] = callDribbble(LOCAL['attributes']);

				if ( NOT StructKeyExists( DeserializeJSON( LOCAL['data'].filecontent.toString()), 'message' )) {
					//set data, success, and message values
					if (ARGUMENTS['config']['format'] EQ 'JSON') {
						LOCAL.returnStruct.data = LOCAL['data'].filecontent.toString();
					} else {
						LOCAL.returnStruct.data = DeserializeJSON( LOCAL['data'].filecontent.toString());
					}
					LOCAL.returnStruct.success = 1;
					LOCAL.returnStruct.message = 'Request successful';
				} else {
					LOCAL.returnStruct.data = '';
					LOCAL.returnStruct.success = 0;
					LOCAL.returnStruct.message = DeserializeJSON( LOCAL['data'].filecontent.toString()).message;
				}

			}
			catch(any e) {
				//set success and message value
				LOCAL.returnStruct.data = '';
				LOCAL.returnStruct.success = 0;
				LOCAL.returnStruct.message = 'An error occurred. Please check your parameters and try your request again.';
			}
		</cfscript>

		<cfreturn LOCAL.returnStruct>
	</cffunction>

	<cffunction name="getShotByID" description="Returns details for a shot specified by :id" returntype="struct" access="public" output="false">
		<cfargument name="id" type="numeric" required="true">
		<cfargument name="outputType" type="string" required="false" default="JSON">

		<cfscript>
			var LOCAL = {};
			LOCAL['config'] = {};
			LOCAL['returnStruct'] = {};

			// the following values are required for EVERY call
			LOCAL['config']['method'] = 'GET';
			LOCAL['config']['format'] = ARGUMENTS['outputType'];
			LOCAL['config']['url'] = '/shots/#ARGUMENTS.id#';
		</cfscript>

		<cfreturn prepDataCall(LOCAL['config'])>
	</cffunction>

	<cffunction name="getShotByCategory" description="Returns the specified list of shots where :list has one of the following values: debuts, everyone, popular" returntype="struct" access="public" output="false">
		<cfargument name="category" type="string" required="true" hint="available values: debuts, everyone, popular">
		<cfargument name="outputType" type="string" required="false" default="JSON">
		<cfargument name="page" type="numeric" required="false" default="1">
		<cfargument name="per_page" type="numeric" required="false" default="15">

		<cfscript>
			var LOCAL = {};
			LOCAL['config'] = {};
			LOCAL['returnStruct'] = {};

			// the following values are required for EVERY call
			LOCAL['config']['method'] = 'GET';
			LOCAL['config']['format'] = ARGUMENTS['outputType'];
			LOCAL['config']['url'] = '/shots/#ARGUMENTS.category#?true';

			// does the page argument exist?
			if (StructKeyExists(ARGUMENTS, 'page')) {
				LOCAL['config']['url'] &='&page=#ARGUMENTS.page#';
			}
			// make sure that per_page is within the correct range, if it exists
			if (StructKeyExists(ARGUMENTS, 'per_page') AND (ARGUMENTS.per_page GTE 1 AND ARGUMENTS.per_page LTE 30)) {
				LOCAL['config']['url'] &='&per_page=#ARGUMENTS.per_page#';
			}
		</cfscript>

		<cfreturn prepDataCall(LOCAL['config'])>
	</cffunction>

	<cffunction name="getShotsByPlayer" description="Returns the most recent shots for the player specified by :id" returntype="struct" access="public" output="false">
		<cfargument name="id" type="any" required="true" hint="id may be a player id or username, e.g. '1' or 'simplebits' ">
		<cfargument name="outputType" type="string" required="false" default="JSON">
		<cfargument name="page" type="numeric" required="false" default="1">
		<cfargument name="per_page" type="numeric" required="false" default="15">

		<cfscript>
			var LOCAL = {};
			LOCAL['config'] = {};
			LOCAL['returnStruct'] = {};

			// the following values are required for EVERY call
			LOCAL['config']['method'] = 'GET';
			LOCAL['config']['format'] = ARGUMENTS['outputType'];
			LOCAL['config']['url'] = '/players/#ARGUMENTS.id#/shots?true';

			// does the page argument exist?
			if (StructKeyExists(ARGUMENTS, 'page')) {
				LOCAL['config']['url'] &='&page=#ARGUMENTS.page#';
			}
			// make sure that per_page is within the correct range, if it exists
			if (StructKeyExists(ARGUMENTS, 'per_page') AND (ARGUMENTS.per_page GTE 1 AND ARGUMENTS.per_page LTE 30)) {
				LOCAL['config']['url'] &='&per_page=#ARGUMENTS.per_page#';
			}
		</cfscript>

		<cfreturn prepDataCall(LOCAL['config'])>
	</cffunction>

	<cffunction name="getShotsByPlayerFollowing" description="Returns the most recent shots published by those the player specified by :id is following" returntype="struct" access="public" output="false">
		<cfargument name="id" type="any" required="true" hint="id may be a player id or username, e.g. '1' or 'simplebits' ">
		<cfargument name="outputType" type="string" required="false" default="JSON">
		<cfargument name="page" type="numeric" required="false" default="1">
		<cfargument name="per_page" type="numeric" required="false" default="15">

		<cfscript>
			var LOCAL = {};
			LOCAL['config'] = {};
			LOCAL['returnStruct'] = {};

			// the following values are required for EVERY call
			LOCAL['config']['method'] = 'GET';
			LOCAL['config']['format'] = ARGUMENTS['outputType'];
			LOCAL['config']['url'] = '/players/#ARGUMENTS.id#/shots/following?true';

			// does the page argument exist?
			if (StructKeyExists(ARGUMENTS, 'page')) {
				LOCAL['config']['url'] &='&page=#ARGUMENTS.page#';
			}
			// make sure that per_page is within the correct range, if it exists
			if (StructKeyExists(ARGUMENTS, 'per_page') AND (ARGUMENTS.per_page GTE 1 AND ARGUMENTS.per_page LTE 30)) {
				LOCAL['config']['url'] &='&per_page=#ARGUMENTS.per_page#';
			}
		</cfscript>

		<cfreturn prepDataCall(LOCAL['config'])>
	</cffunction>

	<cffunction name="getPlayerProfile" description="Returns profile details for a player specified by :id" returntype="struct" access="public" output="false">
		<cfargument name="id" type="any" required="true" hint="id may be a player id or username, e.g. '1' or 'simplebits' ">
		<cfargument name="outputType" type="string" required="false" default="JSON">

		<cfscript>
			var LOCAL = {};
			LOCAL['config'] = {};
			LOCAL['returnStruct'] = {};

			// the following values are required for EVERY call
			LOCAL['config']['method'] = 'GET';
			LOCAL['config']['format'] = ARGUMENTS['outputType'];
			LOCAL['config']['url'] = '/players/#ARGUMENTS.id#';
		</cfscript>

		<cfreturn prepDataCall(LOCAL['config'])>
	</cffunction>

	<cffunction name="getFollowersByPlayer" description="Returns the list of followers for a player specified by :id" returntype="struct" access="public" output="false">
		<cfargument name="id" type="any" required="true" hint="id may be a player id or username, e.g. '1' or 'simplebits' ">
		<cfargument name="outputType" type="string" required="false" default="JSON">

		<cfscript>
			var LOCAL = {};
			LOCAL['config'] = {};
			LOCAL['returnStruct'] = {};

			// the following values are required for EVERY call
			LOCAL['config']['method'] = 'GET';
			LOCAL['config']['format'] = ARGUMENTS['outputType'];
			LOCAL['config']['url'] = '/players/#ARGUMENTS.id#/followers';
		</cfscript>

		<cfreturn prepDataCall(LOCAL['config'])>
	</cffunction>

	<cffunction name="getPlayersFollowedByPlayer" description="Returns the list of players followed by the player specified by :id" returntype="struct" access="public" output="false">
		<cfargument name="id" type="any" required="true" hint="id may be a player id or username, e.g. '1' or 'simplebits' ">
		<cfargument name="outputType" type="string" required="false" default="JSON">

		<cfscript>
			var LOCAL = {};
			LOCAL['config'] = {};
			LOCAL['returnStruct'] = {};

			// the following values are required for EVERY call
			LOCAL['config']['method'] = 'GET';
			LOCAL['config']['format'] = ARGUMENTS['outputType'];
			LOCAL['config']['url'] = '/players/#ARGUMENTS.id#/following';
		</cfscript>

		<cfreturn prepDataCall(LOCAL['config'])>
	</cffunction>

	<cffunction name="getDrafteesByPlayer" description="Returns the list of players drafted by the player specified by :id" returntype="struct" access="public" output="false">
		<cfargument name="id" type="any" required="true" hint="id may be a player id or username, e.g. '1' or 'simplebits' ">
		<cfargument name="outputType" type="string" required="false" default="JSON">

		<cfscript>
			var LOCAL = {};
			LOCAL['config'] = {};
			LOCAL['returnStruct'] = {};

			// the following values are required for EVERY call
			LOCAL['config']['method'] = 'GET';
			LOCAL['config']['format'] = ARGUMENTS['outputType'];
			LOCAL['config']['url'] = '/players/#ARGUMENTS.id#/draftees';
		</cfscript>

		<cfreturn prepDataCall(LOCAL['config'])>
	</cffunction>

</cfcomponent>

























