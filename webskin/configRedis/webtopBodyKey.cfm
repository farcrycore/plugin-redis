<cfsetting enablecfoutputonly="true" />
<!--- @@fuAlias: key --->

<cfset redis = createobject("component","farcry.plugins.redis.packages.lib.redis") />
<cfset redisClient = application.fc.lib.objectbroker.getRedis() />
<cfset data = redis.get(redisClient, url.key) />

<cfoutput><h1>#url.key#</h1></cfoutput>

<cfdump var="#data#">

<cfsetting enablecfoutputonly="false" />