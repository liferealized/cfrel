<cffunction name="$getTrace" access="public" output="false" returntype="array">
  <cfreturn variables.trace />
</cffunction>

<cffunction name="$reporter" access="public" output="false" returntype="any">
  <cfscript>
    local._methodName = getFunctionCalledName();
    local.arguments = duplicate(arguments);
    local.timer = getTickCount();

    // we need to append to the array BEFORE calling the method
    arrayAppend(variables.trace, duplicate(local));
    local.position = arrayLen(variables.trace);

    // call our actual method on core
    var method = core[local._methodName];

    local.returned = method(argumentCollection = arguments);

    variables.trace[local.position].timer = getTickCount() - local.timer;

    if (isNull(local.returned)) {
      variables.trace[local.position].returned = "null";
      return;
    }
    variables.trace[local.position].returned = duplicate(local.returned);
    return local.returned;
  </cfscript>
</cffunction>

<cffunction name="$dump" returntype="void" access="public" output="true">
  <cfargument name="var" type="any" required="true">
  <cfargument name="abort" type="boolean" required="false" default="true">
  <cfdump var="#arguments.var#">
  <cfif arguments.abort>
    <cfabort>
  </cfif>
</cffunction>

<cffunction name="$invoke" returntype="any" access="public" output="false">
  <cfset var loc = {}>
  <cfset arguments.returnVariable = "loc.rv">
  <cfset arguments.component = this>
  <cfif StructKeyExists(arguments, "invokeArgs")>
    <cfset arguments.argumentCollection = arguments.invokeArgs>
    <cfif StructCount(arguments.argumentCollection) IS NOT ListLen(StructKeyList(arguments.argumentCollection))>
      <!--- work-around for fasthashremoved cf8 bug --->
      <cfset arguments.argumentCollection = StructNew()>
      <cfloop list="#StructKeyList(arguments.invokeArgs)#" index="loc.i">
        <cfset arguments.argumentCollection[loc.i] = arguments.invokeArgs[loc.i]>
      </cfloop>
    </cfif>
    <cfset StructDelete(arguments, "invokeArgs")>
  </cfif>
  <cfset request.cfrel.invoked = duplicate(arguments)>
  <cfinvoke attributeCollection="#arguments#">
  <cfset request.cfrel.invoked = {}>
  <cfif StructKeyExists(loc, "rv")>
    <cfreturn loc.rv>
  </cfif>
</cffunction>

<cfscript>
  if (structKeyExists(application, "cfrel")
      && structKeyExists(application.cfrel, "metrics")
      && application.cfrel.metrics) {

    request.$a = { func = { core = {}, trace = [] } };

    for (request.$a.key in variables) {
      if (!listFindNoCase("$dump,$invoke,$reporter,$getTrace,init,setupcaching", request.$a.key)) {
        if (isCustomFunction(variables[request.$a.key])) {
          request.$a.func.core[request.$a.key] = duplicate(variables[request.$a.key]);
          request.$a.func[request.$a.key] = variables.$reporter;
        }
      }
    }

    structAppend(variables, request.$a.func, true);
    structDelete(request, "$a", false);
  }
</cfscript>
