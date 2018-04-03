<cfcomponent>

	<cffunction name="initializeClient" access="public" output="false" returntype="any">
		<cfargument name="config" type="struct" required="true" />

		<cfset var redis = "" />
		<cfset var redisConfig = "" />

		<cfset var javaLoader = createObject("component", "farcry.core.packages.farcry.javaloader.JavaLoader").init([
			expandpath("/farcry/plugins/redis/packages/java/redis.clients.jedis-2.7.2.jar"),
			expandpath("/farcry/plugins/redis/packages/java/org.apache.commons.pool-1.5.6.jar"),
			expandpath("/farcry/plugins/redis/packages/java/org.apache.commons.pool2-2.4.1.jar")
		])>

		<cflog file="redis" text="Creating redis client for server: #arguments.config.server.toString()#" />
		<cfset redisConfig = javaLoader.create("redis.clients.jedis.JedisPoolConfig").init()>
		<cfset redisConfig.setMaxTotal(128)>
		<cfif len(arguments.config.password)>
			<cfset redis = javaLoader.create("redis.clients.jedis.JedisPool").init(redisConfig, arguments.config.server, arguments.config.port, 15000, arguments.config.password)>
		<cfelse>
			<cfset redis = javaLoader.create("redis.clients.jedis.JedisPool").init(redisConfig, arguments.config.server, arguments.config.port, 15000)>
		</cfif>
		<cflog file="redis" text="Redis client set up" />

		<cfreturn redis />
	</cffunction>

	<cffunction name="get" access="public" output="false" returntype="any" hint="Returns an object from cache if it is there, an empty struct if not. Note that garbage collected data counts as a miss.">
		<cfargument name="redis" type="any" required="true" />
		<cfargument name="key" type="string" required="true" />

		<cfset var stLocal = structnew() />
		<cfset var cfcatch = "" />

<!--- <cflog file="redis" type="information" text="redis.get(#arguments.key#)" /> --->

        <cfset stLocal.value = structnew() />

		<cfset var res = arguments.redis.getResource()>
		<cftry>
			<cfset var result = res.get(toBinary(toBase64(arguments.key)))>
			<cfif NOT isNull(result)>
				<cfset stLocal.value = deserializeByteArray(result)>
			</cfif>

			<cfcatch>
<!--- <cflog file="redis_error" type="error" text="get(#arguments.key#) -- #serializeJSON(cfcatch.message)#" /> --->
				<cfset stLocal.value = structnew() />
				<cfset arguments.redis.returnBrokenResource(res)>
				<cfset res = NullValue()>
			</cfcatch>
			<cffinally>
				<cfif NOT isNull(res)>
					<cfset arguments.redis.returnResource(res)>
				</cfif>
			</cffinally>
		</cftry>

<!--- <cflog file="redis" type="information" text="#serializeJSON(stLocal.value)#" /> --->

		<cfreturn stLocal.value />
	</cffunction>

	<cffunction name="set" access="public" output="false" returntype="void" hint="Puts the specified key in the cache. Note that if the key IS in cache or the data is deliberately empty, the cache is updated but cache queuing is not effected.">
		<cfargument name="redis" type="any" required="true" />
		<cfargument name="key" type="string" required="true" />
		<cfargument name="data" type="struct" required="true" />
		<cfargument name="timeout" type="numeric" required="false" default="3600" hint="Number of seconds until this item should timeout" />
		
		<cfset var cfcatch = "" />

<!--- <cflog file="redis" type="information" text="redis.set(#arguments.key#, #arguments.timeout#)" /> --->
<!--- <cflog file="redis" type="information" text="#serializeJSON(arguments.data)#" /> --->

		<cfset var res = arguments.redis.getResource()>
		<cftry>
			<cfset res.set(toBinary(toBase64(arguments.key)), serializeByteArray(arguments.data))>
			<cfset res.expire(toBinary(toBase64(arguments.key)), arguments.timeout)>

			<cfcatch>
<!--- <cflog file="redis_error" type="error" text="set(#arguments.key#) -- #serializeJSON(cfcatch.message)#" /> --->
				<cfif not structkeyexists(request, "logging")>
					<cfset request.logging = true />
					<cflog type="error" application="true" file="redis" text="Error setting to cache: #cfcatch.message#" />
					<cfset application.fc.lib.error.logData(application.fc.lib.error.normalizeError(cfcatch)) />
					<cfset structDelete(request,"logging") />
				</cfif>
				<cfset arguments.redis.returnBrokenResource(res)>
				<cfset res = NullValue()>
			</cfcatch>
			<cffinally>
				<cfif NOT isNull(res)>
					<cfset arguments.redis.returnResource(res)>
				</cfif>
			</cffinally>
		</cftry>
	</cffunction>

	<cffunction name="append" access="public" output="false" returntype="void" hint="Removes items from the cache that match the specified regex. Does NOT change the cache management stats.">
		<cfargument name="redis" type="any" required="true" />
		<cfargument name="key" type="string" required="false" default="" />
		<cfargument name="data" type="string" required="true" />

		<cfset var cfcatch = "" />
		<cfset var val = "" />

		<cfset var res = arguments.redis.getResource()>
		<cftry>
			<cfset res.append(toBinary(toBase64(arguments.key)), serializeByteArray(arguments.data))>
			<cfset res.expire(toBinary(toBase64(arguments.key)), arguments.timeout)>

			<cfcatch>
<!--- <cflog file="redis_error" type="error" text="append(#arguments.key#) -- #serializeJSON(cfcatch.message)#" /> --->
				<cfif not structkeyexists(request, "logging")>
					<cfset request.logging = true />
					<cflog type="error" application="true" file="redis" text="Error appending to cache: #cfcatch.message#" />
					<cfset application.fc.lib.error.logData(application.fc.lib.error.normalizeError(cfcatch)) />
					<cfset structDelete(request,"logging") />
				</cfif>
				<cfset arguments.redis.returnBrokenResource(res)>
				<cfset res = NullValue()>
			</cfcatch>
			<cffinally>
				<cfif NOT isNull(res)>
					<cfset arguments.redis.returnResource(res)>
				</cfif>
			</cffinally>
		</cftry>
	</cffunction>

	<cffunction name="flush" access="public" output="false" returntype="void" hint="Removes items from the cache that match the specified regex. Does NOT change the cache management stats.">
		<cfargument name="redis" type="any" required="true" />
		<cfargument name="key" type="string" required="false" default="" />
		
		<cfset var cfcatch = "" />

<!--- <cflog file="redis" type="information" text="redis.flush()" /> --->

		<cfset var res = arguments.redis.getResource()>
		<cftry>
			<cfset res.del(toBinary(toBase64(arguments.key))) />

			<cfcatch>
				<cfset arguments.redis.returnBrokenResource(res)>
				<cfset res = NullValue()>
			</cfcatch>
			<cffinally>
				<cfif NOT isNull(res)>
					<cfset arguments.redis.returnResource(res)>
				</cfif>
			</cffinally>
		</cftry>
	</cffunction>

	
	<cffunction name="getServerStats" access="public" returntype="any" output="false" hint="Get all of the stats from all of the connections.">
		<cfargument name="redis" type="any" required="true" />
		
		<cfset var stats = structnew() />
		<cfset var info = "" />
		<cfset var i = "" />
		
		<cfset var res = arguments.redis.getResource()>
		<cftry>
			<cfset info = res.info()>
			<cfset stats["server"] = {}>
			<cfset stats["server"].isUnresolved = function() {
				return false;
			}>

			<cfcatch>
				<cfdump var="#cfcatch#">
				<cfset arguments.redis.returnBrokenResource(res)>
				<cfset res = NullValue()>
			</cfcatch>
			<cffinally>
				<cfif NOT isNull(res)>
					<cfset arguments.redis.returnResource(res)>
				</cfif>
			</cffinally>
		</cftry>

		<cfloop list="#info#" index="i" delimiters="#chr(10)##chr(13)#">
			<cfset stats["server"][listFirst(i, ":")] = listRest(i, ":")>
		</cfloop>

		<cfreturn stats />
	</cffunction>
	
<!--- 
	<cffunction name="getVersions" access="public" returntype="any" output="false" hint="Get the versions of all of the connected redis.">
		<cfargument name="redis" type="any" required="true" />
		
		<cfset var versions = structnew() />
		
		<cfif structkeyexists(this,"redis")>
			<cfset versions = mapToStruct(arguments.redis.getVersions()) />
		</cfif>
		
		<cfreturn versions />
	</cffunction>
 --->

    <cffunction name="mapToStruct" access="private" returntype="struct" output="false">
        <cfargument name="map" type="any" required="true" />

        <cfset var theStruct = {} />
        <cfset var entrySet = "" />
        <cfset var iterator = "" />
        <cfset var entry = "" />
        <cfset var key = "" />
        <cfset var value = "" />

        <cfset entrySet = arguments.map.entrySet() />
        <cfset iterator = entrySet.iterator() />

        <cfloop condition="#iterator.hasNext()#">
            <cfset entry = iterator.next() />
            <cfset key = entry.getKey() />
            <cfset value = entry.getValue() />
            <cfset theStruct[key] = value />
        </cfloop>

        <cfreturn theStruct />
    </cffunction>
	
	<cffunction name="getItemWebskinStats" returntype="struct" output="false">
		<cfargument name="qItems" type="query" required="true">
		
		<cfset var q = querynew("webskin,num,size","varchar,varchar,integer")>
		<cfset var stResult = {} />
		
		<cfquery dbtype="query" name="q">
			<cfif findnocase("mssql",application.dbType)>
				select 		webskin,count(key) as [num], sum([size]) as [size]
			</cfif>
			<cfif application.dbType EQ "mysql">
				select 		webskin,count(key) as num, sum(size) as size
			</cfif>
			from 		arguments.qItems 
			where		webskin<>''
			group by 	webskin
			order by 	webskin
		</cfquery>
		<cfset stResult.stats = q />

		<cfquery dbtype="query" name="q">
			<cfif findnocase("mssql",application.dbType)>
				select 	sum([num]) as sumnum, 
						max([num]) as maxnum, 
						max([size]) as sumsize, 
						max([size]) as maxsize 
			</cfif>
			<cfif application.dbType EQ "mysql">
				select 	sum(num) as sumnum, 
						max(num) as maxnum, 
						max(size) as sumsize, 
						max(size) as maxsize 
			</cfif>
			from 	q
		</cfquery>
		<cfif q.recordcount>
			<cfset stResult.sumnum = q.sumnum />
			<cfset stResult.maxnum = q.maxnum />
			<cfset stResult.sumsize = q.sumsize />
			<cfset stResult.maxsize = q.maxsize />
		<cfelse>
			<cfset stResult.sumnum = 0 />
			<cfset stResult.maxnum = 0 />
			<cfset stResult.sumsize = 0 />
			<cfset stResult.maxsize = 0 />
		</cfif>
		
		<cfreturn stResult />
	</cffunction>

<!--- 
	<cffunction name="getItemSizeStats" returntype="struct" output="false">
		<cfargument name="qItems" type="query" required="true">
		
		<cfset var q = querynew("size,num","integer,integer")>
		<cfset var stResult = {} />
		
		<cfquery dbtype="query" name="q">
			<cfif findnocase("mssql",application.dbType)>
				select		CAST(size as INTEGER) as [size], count(*) as [num]
				from		arguments.qItems
				group by 	[size]
				order by 	[size]
			</cfif>
			<cfif application.dbType EQ "mysql">
				select		CAST(size as INTEGER) as size, count(*) as num
				from		arguments.qItems
				group by 	size
				order by 	size
			</cfif>
		</cfquery>
		<cfset stResult.stats = q />
		
		<cfquery dbtype="query" name="q">
			<cfif findnocase("mssql",application.dbType)>
				select 	sum([num]) as sumnum, 
						max([num]) as maxnum 
				from 	q
			</cfif>
			<cfif application.dbType EQ "mysql">
				select 	sum(num) as sumnum, 
						max(num) as maxnum 
				from 	q
			</cfif>
		</cfquery>
		<cfset stResult.sumnum = q.sumnum />
		<cfset stResult.maxnum = q.maxnum />
		
		<cfreturn stResult />
	</cffunction>
 --->

	<cffunction name="getItemTypeStats" returntype="struct" output="false">
		<cfargument name="qItems" type="query" required="true">
		
		<cfset var q = querynew("typename,objectsize,objectnum,webskinsize,webskinnum","varchar,bigint,integer,bigint,integer")>
		<cfset var stObjectSize = structnew() />
		<cfset var stObjectCount = structnew() />
		<cfset var stWebskinSize = structnew() />
		<cfset var stWebskinCount = structnew() />
		<cfset var stResult = {} />

		<cfloop query="arguments.qItems">
			<cfif not structkeyexists(stObjectSize,arguments.qItems.typename)>
				<cfset stObjectSize[arguments.qItems.typename] = 0 />
				<cfset stObjectCount[arguments.qItems.typename] = 0 />
				<cfset stWebskinSize[arguments.qItems.typename] = 0 />
				<cfset stWebskinCount[arguments.qItems.typename] = 0 />
			</cfif>
			
			<cfif listlen(arguments.qItems.key,"_") eq 5>
				<!--- object --->
				<cfset stObjectSize[arguments.qItems.typename] = stObjectSize[arguments.qItems.typename] + arguments.qItems.size />
				<cfset stObjectCount[arguments.qItems.typename] = stObjectCount[arguments.qItems.typename] + 1 />
			<cfelse>
				<!--- webskin --->
				<cfset stWebskinSize[arguments.qItems.typename] = stWebskinSize[arguments.qItems.typename] + arguments.qItems.size />
				<cfset stWebskinCount[arguments.qItems.typename] = stWebskinCount[arguments.qItems.typename] + 1 />
			</cfif>
		</cfloop>
		
		<cfloop collection="#stObjectSize#" item="i">
			<cfset queryaddrow(q) />
			<cfset querysetcell(q,"typename",i) />
			<cfset querysetcell(q,"objectsize",stObjectSize[i]) />
			<cfset querysetcell(q,"objectnum",stObjectCount[i]) />
			<cfset querysetcell(q,"webskinsize",stWebskinSize[i]) />
			<cfset querysetcell(q,"webskinnum",stWebskinCount[i]) />
		</cfloop>
		
		<cfloop collection="#application.stCOAPI#" item="i">
			<cfif listfindnocase("type,rule",application.stCOAPI[i].class) and not structkeyexists(stObjectSize,i)>
				<cfset queryaddrow(q) />
				<cfset querysetcell(q,"typename",i) />
				<cfset querysetcell(q,"objectsize",0) />
				<cfset querysetcell(q,"objectnum",0) />
				<cfset querysetcell(q,"webskinsize",0) />
				<cfset querysetcell(q,"webskinnum",0) />
			</cfif>
		</cfloop>

		<cfquery dbtype="query" name="q">select * from q order by typename asc</cfquery>
		<cfset stResult.stats = q />

		<cfquery dbtype="query" name="q">
			select 	sum(objectsize) as sumobjectsize, 
					max(objectsize) as maxobjectsize, 
					sum(objectnum) as sumobjectnum, 
					max(objectnum) as maxobjectnum, 
					sum(webskinsize) as sumwebskinsize, 
					max(webskinsize) as maxwebskinsize, 
					sum(webskinnum) as sumwebskinnum, 
					max(webskinnum) as maxwebskinnum 
			from 	q
		</cfquery>
		<cfset stResult.sumobjectsize = q.sumobjectsize />
		<cfset stResult.maxobjectsize = q.maxobjectsize />
		<cfset stResult.sumobjectnum = q.sumobjectnum />
		<cfset stResult.maxobjectnum = q.maxobjectnum />
		<cfset stResult.sumwebskinsize = q.sumwebskinsize />
		<cfset stResult.maxwebskinsize = q.maxwebskinsize />
		<cfset stResult.sumwebskinnum = q.sumwebskinnum />
		<cfset stResult.maxwebskinnum = q.maxwebskinnum />
		
		<cfreturn stResult />
	</cffunction>

	<cffunction name="getItemExpiryStats" returntype="struct" output="false">
		<cfargument name="qItems" type="query" required="true">
		<cfargument name="bBreakdown" type="boolean" required="false" default="false">
		
		<cfset var q = querynew("expires,expires_epoch,num","date,bigint,integer")>
		<cfset var stCount = structnew() />
		<cfset var expires = "" />
		<cfset var stResult = structnew() />

		<cfloop query="arguments.qItems">
			<cfset expires = "" & int(arguments.qItems.expires/60/15) * 60 * 15 - GetTimeZoneInfo().UTCTotalOffset />
			
			<cfif not structkeyexists(stCount,expires)>
				<cfset stCount[expires] = 0 />
			</cfif>
			
			<cfset stCount[expires] = stCount[expires] + 1 />
		</cfloop>
		
		<cfloop collection="#stCount#" item="i">
			<cfset queryaddrow(q) />
			<cfset querysetcell(q,"expires",DateAdd("s", i, "January 1 1970 00:00:00")) />
			<cfset querysetcell(q,"expires_epoch",i) />
			<cfset querysetcell(q,"num",stCount[i]) />
		</cfloop>
		
		<cfquery dbtype="query" name="q">select * from q order by expires asc</cfquery>
		<cfset stResult.stats = q />
		
		<cfquery dbtype="query" name="q">
			<cfif findnocase("mssql",application.dbType)>
				select 	sum([num]) as sumnum, 
						max([num]) as maxnum
				from 	q
			</cfif>
			<cfif application.dbType EQ "mysql">
				select 	sum(num) as sumnum, 
						max(num) as maxnum
				from 	q
			</cfif>
		</cfquery>
		<cfset stResult.sumnum = q.sumnum />
		<cfset stResult.maxnum = q.maxnum />
		
		<!--- breakdowns for expiry times --->
		<cfif arguments.bBreakdown>
			<cfset stResult.breakdown = structnew() />
			<cfloop collection="#stCount#" item="expires">
				<cfif stCount[expires]>
					<cfquery dbtype="query" name="q">
						select		*
						from		arguments.qItems
						where		expires>=#expires# and expires<#expires+60*15#
					</cfquery>
					<cfset stResult.breakdown[expires] = getItemTypeStats(q) />
				<cfelse>
					<cfset stResult.breakdown[expires] = querynew("typename,objectsize,objectnum,webskinsize,webskinnum","varchar,bigint,integer,bigint,integer") />
				</cfif>
			</cfloop>
		</cfif>

		<cfreturn stResult />
	</cffunction>

	<cffunction name="getApplicationStats" returntype="struct" output="false">
		<cfargument name="qItems" type="query" required="true">
		
		<cfset var q = querynew("application,size,num","varchar,bigint,integer")>
		<cfset var stCount = structnew() />
		<cfset var stSize = structnew() />
		<cfset var i = 0 />
		<cfset var app = "" />
		<cfset var stResult = structnew() />
		
		<cfquery dbtype="query" name="q">
			<cfif findnocase("mssql",application.dbType)>
				select		application, count(*) as [num], sum([size]) as [size]
			</cfif>
			<cfif application.dbType EQ "mysql">
				select		application, count(*) as num, sum(size) as size
			</cfif>
			from		arguments.qItems
			group by 	application
			order by 	application asc
		</cfquery>
		<cfset stResult.stats = q />
		
		<cfquery dbtype="query" name="q">
			<cfif findnocase("mssql",application.dbType)>
				select 	sum([size]) as sumsize, 
						max([size]) as maxsize, 
						sum([num]) as sumnum, 
						max([num]) as maxnum
				from 	q
			</cfif>
			<cfif application.dbType EQ "mysql">
				select 	sum(size) as sumsize, 
						max(size) as maxsize, 
						sum(num) as sumnum, 
						max(num) as maxnum
				from 	q
			</cfif>
		</cfquery>
		<cfset stResult.sumsize = q.sumsize />
		<cfset stResult.maxsize = q.maxsize />
		<cfset stResult.sumnum = q.sumnum />
		<cfset stResult.maxnum = q.maxnum />
		
		<cfreturn stResult />
	</cffunction>

	<cffunction name="getItems" returntype="query" output="false">
		<cfargument name="server" type="string" required="true" />
		<cfargument name="app" type="string" required="false" />
		<cfargument name="version" type="numeric" required="false" />
		
		<cfset var slabs = slabStats(arguments.server) />
		<cfset var slabID = "" />
		<cfset var hostname = rereplace(arguments.server,"[^/]+/([^:]+):\d+","\1") />
		<cfset var port = rereplace(arguments.server,"[^/]+/[^:]+:(\d+)","\1") />
		<cfset var keys = "" />
		<cfset var item = "" />
		<cfset var st = "" />
		<cfset var qItems = querynew("app_version,key,size,expires,application,typename,typename_version,webskin","numeric,varchar,integer,bigint,varchar,varchar,numeric,varchar") />
		
		<cfloop collection="#slabs#" item="slabID">
			<cfset keys = easySocket(hostname,port,"stats cachedump #slabID# #slabs[slabID].number#") />
			
			<cfloop from="1" to="#arraylen(keys)#" index="i">
				<cfset item = listtoarray(keys[i]," ") />
				<cfif not structkeyexists(arguments,"app") or listfirst(item[2],"_") eq arguments.app>
					<cfset queryaddrow(qItems) />
					<cfset querysetcell(qItems,"key",item[2]) />
					<cfset querysetcell(qItems,"size",mid(item[3],2,100) / 1024) />
					<cfset querysetcell(qItems,"expires",item[5]) />
					<cfif listlen(item[2],"_") eq 5 or listlen(item[2],"_") eq 8>
						<cfset querysetcell(qItems,"application",listgetat(item[2],1,"_")) />
						<cfset querysetcell(qItems,"app_version",listgetat(item[2],2,"_")) />
						<cfset querysetcell(qItems,"typename",listgetat(item[2],3,"_")) />
						<cfset querysetcell(qItems,"typename_version",listgetat(item[2],4,"_")) />
						<cfif listlen(item[2],"_") eq 8>
							<cfset querysetcell(qItems,"webskin",listgetat(item[2],7,"_")) />
						</cfif>
					<cfelse>
						<cfset querysetcell(qItems,"application","Unknown") />
						<cfset querysetcell(qItems,"app_version","0") />
					</cfif>
				</cfif>
			</cfloop>
		</cfloop>

		<cfif structKeyExists(arguments,"version")>
			<cfquery dbtype="query" name="qItems">
				select  *
				from 	qItems
				where 	app_version=<cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.version#">
			</cfquery>
		</cfif>
		
		<cfreturn qItems />
	</cffunction>

	<cffunction name="slabStats" returntype="struct" output="false">
		<cfargument name="server" type="string" required="false" />
		
		<cfset var stats = application.fc.lib.objectbroker.redis.getStats('items') />
		<cfset var socket = "" />
		
		<cfloop collection="#stats#" item="socket">
			<cfif structkeyexists(arguments,"server")>
				<cfif findnocase(arguments.server,socket)>
					<cfreturn slabifyStats(stats[socket]) />
				</cfif>
			<cfelse>
				<cfset stats[socket] = slabifyStats(stats[socket]) />
			</cfif>
		</cfloop>
		
		<cfif structkeyexists(arguments,"server")>
			<!--- can only get here if the server wasn't found in the stats --->
			<cfset stats = structnew() />
		</cfif>
		
		<cfreturn stats />
	</cffunction>

	<cffunction name="slabifyStats" returntype="struct" output="false">
		<cfargument name="map" type="any" required="true" />
		
		<cfset var stats = mapToStruct(arguments.map) />
		<cfset var result = structnew() />
		<cfset var key = "" />
		<cfset var slabID = "" />
		
		<cfloop collection="#stats#" item="key">
			<cfset slabID = listgetat(key,2,":") />
			<cfif not structkeyexists(result,slabID)>
				<cfset result[slabID] = structnew() />
			</cfif>
			<cfset result[slabID][listgetat(key,3,":")] = stats[key] />
		</cfloop>
		
		<cfreturn result />
	</cffunction>

	<!---
	 Connect to sockets through your ColdFusion application.
	 Mods by Raymond Camden
	 
	 @param host      Host to connect to. (Required)
	 @param port      Port for connection. (Required)
	 @param message      Message to be sent. (Required)
	 @return Returns a string. 
	 @author George Georgiou (george1977@gmail.com) 
	 @version 1, August 27, 2009 
	--->
	<cffunction name="easySocket" access="private" returntype="any" hint="Uses Java Sockets to connect to a remote socket over TCP/IP" output="false">
		<cfargument name="host" type="string" required="yes" default="localhost" hint="Host to connect to and send the message">
		<cfargument name="port" type="numeric" required="Yes" default="8080" hint="Port to connect to and send the message">
		<cfargument name="message" type="string" required="yes" default="" hint="The message to transmit">

		<cfset var result = arraynew(1)>
		<cfset var socket = createObject( "java", "java.net.Socket" )>
		<cfset var streamOut = "">
		<cfset var output = "">
		<cfset var input = "">
		<cfset var line = "" />

		<cfset var cfcatch = "" />

		<cftry>
			<cfset socket.init(arguments.host,arguments.port)>
			<cfcatch type="Object">
				<cfthrow message="Could not connected to host <strong>#arguments.host#</strong>, port <strong>#arguments.port#</strong>">
			</cfcatch>  
		</cftry>

		<cfif socket.isConnected()>
			<cfset streamOut = socket.getOutputStream()>

			<cfset output = createObject("java", "java.io.PrintWriter").init(streamOut)>
			<cfset streamInput = socket.getInputStream()>

			<cfset inputStreamReader= createObject( "java", "java.io.InputStreamReader").init(streamInput)>
			<cfset input = createObject( "java", "java.io.BufferedReader").init(InputStreamReader)>

			<cfset output.println(arguments.message)>
			<cfset output.println()> 
			<cfset output.flush()>

			<cfset line = input.readLine()>
			<cfloop condition="line neq 'END'">
				<cfset arrayappend(result,line) />
				<cfset line = input.readLine()>
			</cfloop>
			<cfset socket.close()>
		<cfelse>
			<cfthrow message="Could not connected to host <strong>#arguments.host#</strong>, port <strong>#arguments.port#</strong>.">
		</cfif>

		<cfreturn result>
	</cffunction>

	<!--- General utility functions --->
	<cffunction name="serializeByteArray" access="private" returntype="any" output="false">
		<cfargument name="value" type="any" required="true" />
		
		<cfset var byteArrayOutputStream = "" />
		<cfset var objectOutputStream = "" />
		<cfset var serializedValue = "" />
		
		<cfif IsSimpleValue(arguments.value)>
			<cfreturn arguments.value />
		<cfelse>
			<cfset byteArrayOutputStream = CreateObject("java","java.io.ByteArrayOutputStream").init() />
			<cfset objectOutputStream = CreateObject("java","java.io.ObjectOutputStream").init(byteArrayOutputStream) />
			<cfset objectOutputStream.writeObject(arguments.value) />
			<cfset serializedValue = byteArrayOutputStream.toByteArray() />
			<cfset objectOutputStream.close() />
			<cfset byteArrayOutputStream.close() />
		</cfif>
		
		<cfreturn serializedValue />
	</cffunction>
	
	<cffunction name="deserializeByteArray" access="private" returntype="any" output="false">
		<cfargument name="value" type="any" required="true" />
		
		<cfset var deserializedValue = "" />
		<cfset var objectInputStream = "" />
		<cfset var byteArrayInputStream = "" />
		
		<cfif IsSimpleValue(arguments.value)>
			<cfreturn arguments.value />
		<cfelse>
			<cfset objectInputStream = CreateObject("java","java.io.ObjectInputStream") />
			<cfset byteArrayInputStream = CreateObject("java","java.io.ByteArrayInputStream") />
			<cfset objectInputStream.init(byteArrayInputStream.init(arguments.value)) />
			<cfset deserializedValue = objectInputStream.readObject() />
			<cfset objectInputStream.close() />
			<cfset byteArrayInputStream.close() />
		</cfif>
		
		<cfreturn deserializedValue />
	</cffunction>

</cfcomponent>