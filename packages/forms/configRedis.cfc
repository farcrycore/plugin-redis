<cfcomponent extends="farcry.core.packages.forms.forms" displayname="Redis" hint="Redis object broker settings" key="redis">

	<cfproperty name="server" type="string" required="false" 
		ftSeq="1" ftWizardStep="" ftFieldset="Redis" ftLabel="Server"
		ftHint="Redis Server Hostname / IP address">

	<cfproperty name="port" type="string" required="false" 
		ftSeq="2" ftWizardStep="" ftFieldset="Redis" ftLabel="Port" 
		ftHint="Redis Server Port">

	<cfproperty name="password" type="string" required="false" 
		ftSeq="3" ftWizardStep="" ftFieldset="Redis" ftLabel="Password" 
		ftHint="Redis Password">


	<cffunction name="process" access="public" output="false" returntype="struct">
		<cfargument name="fields" type="struct" required="true" />
		
		<cfset application.fc.lib.objectbroker.cacheInitialise(arguments.fields) />
		
		<cfreturn fields />
	</cffunction>
	

	<cffunction name="getProgressBar" access="public" output="false" returntype="string">
		<cfargument name="value" type="numeric" required="true" />
		<cfargument name="max" type="numeric" required="true" />
		<cfargument name="label" type="string" required="true" />
		<cfargument name="styleClass" type="string" required="false" default="progress-info" />

		<cfset var html = "" />
		<cfset var width = 0 />

		<cfif arguments.max>
			<cfset width = round(arguments.value / arguments.max * 100) />
		</cfif>

		<cfsavecontent variable="html"><cfoutput>
			<div class="progress #arguments.styleClass# progress-striped">
				<div class="bar" style="width:#width#%;">&nbsp;#arguments.label#</div>
			</div>
		</cfoutput></cfsavecontent>

		<cfreturn html>
	</cffunction>

	<cffunction name="isNewWebtop" access="public" output="false" returntype="boolean">

		<cfreturn structkeyexists(url,"id") />
	</cffunction>

	<cffunction name="getServersURL" access="public" output="false" returntype="string">

		<cfreturn application.fapi.fixURL(addvalues='type=configRedis&bodyView=webtopBody',removevalues='server,app,cachetype') />
	</cffunction>

	<cffunction name="getServerURL" access="public" output="false" returntype="string">
		<cfargument name="server" type="string" required="true" />

		<cfreturn application.fapi.fixURL(addvalues='type=configRedis&bodyView=webtopBodyServer&server=#arguments.server#',removevalues='app,cachetype') />
	</cffunction>

	<cffunction name="getApplicationURL" access="public" output="false" returntype="string">
		<cfargument name="server" type="string" required="true" />
		<cfargument name="app" type="string" required="true" />

		<cfreturn application.fapi.fixURL(addvalues='type=configRedis&bodyView=webtopBodyApplication&server=#arguments.server#&app=#arguments.app#',removevalues='cachetype') />
	</cffunction>

	<cffunction name="getTypeURL" access="public" output="false" returntype="string">
		<cfargument name="server" type="string" required="true" />
		<cfargument name="app" type="string" required="true" />
		<cfargument name="typename" type="string" required="true" />

		<cfreturn application.fapi.fixURL(addvalues='type=configRedis&bodyView=webtopBodyType&server=#arguments.server#&app=#arguments.app#&cachetype=#arguments.typename#',removevalues='') />
	</cffunction>

	<cffunction name="getKeyURL" access="public" output="false" returntype="string">
		<cfargument name="server" type="string" required="true" />
		<cfargument name="app" type="string" required="true" />
		<cfargument name="typename" type="string" required="true" />
		<cfargument name="key" type="string" required="true" />

		<cfreturn application.fapi.fixURL(addvalues='type=configRedis&view=webtopPageModal&bodyView=webtopBodyKey&server=#arguments.server#&app=#arguments.app#&cachetype=#arguments.typename#&key=#arguments.key#',removevalues='') />
	</cffunction>

</cfcomponent>