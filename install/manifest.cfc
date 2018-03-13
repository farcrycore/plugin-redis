<cfcomponent extends="farcry.core.webtop.install.manifest" name="manifest">

	<!--- IMPORT TAG LIBRARIES --->
	<cfimport taglib="/farcry/core/packages/fourq/tags/" prefix="q4">
	
	
	<cfset this.name = "Redis" />
	<cfset this.description = "<strong>Redis</strong> plugin replaces the default object and webskin caching mechanism in Core with an external redis server." />
	<cfset this.lRequiredPlugins = "" />
	

</cfcomponent>