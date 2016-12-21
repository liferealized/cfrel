<cffunction name="getParameters" returntype="array" access="public" hint="Return array of all parameters used in query and subqueries">
	<cfargument name="stack" type="array" default="#[]#" />
	<cfscript>
		var loc = {};
			
		// stack on parameters from subqueries
		loc.iEnd = ArrayLen(this.sql.froms);
		for (loc.i = 1; loc.i LTE loc.iEnd; loc.i++)
			if (typeOf(this.sql.froms[loc.i]) EQ "cfrel.nodes.SubQuery")
				arguments.stack = this.sql.froms[loc.i].subject.getParameters(arguments.stack);
				
		// stack on parameters from join subqueries
		loc.iEnd = ArrayLen(this.sql.joins);
		for (loc.i = 1; loc.i LTE loc.iEnd; loc.i++)
			if (typeOf(this.sql.joins[loc.i].table) EQ "cfrel.nodes.SubQuery")
				arguments.stack = this.sql.joins[loc.i].table.subject.getParameters(arguments.stack);
			
		// stack on join parameters
		loc.iEnd = ArrayLen(this.sql.joinParameters);
		for (loc.i = 1; loc.i LTE loc.iEnd; loc.i++)
			ArrayAppend(arguments.stack, this.sql.joinParameters[loc.i]);
		
		// stack on where parameters
		loc.iEnd = ArrayLen(this.sql.whereParameters);
		for (loc.i = 1; loc.i LTE loc.iEnd; loc.i++)
			ArrayAppend(arguments.stack, this.sql.whereParameters[loc.i]);
		
		// stack on having parameters
		loc.iEnd = ArrayLen(this.sql.havingParameters);
		for (loc.i = 1; loc.i LTE loc.iEnd; loc.i++)
			ArrayAppend(arguments.stack, this.sql.havingParameters[loc.i]);
			
		return arguments.stack;
	</cfscript>
</cffunction>

<cffunction name="getParameterColumns" returntype="array" access="public" hint="Return array of all columns referenced by parameters">
	<cfargument name="stack" type="array" default="#[]#" />
	<cfscript>
		var loc = {};
			
		// stack on parameters from subqueries
		loc.iEnd = ArrayLen(this.sql.froms);
		for (loc.i = 1; loc.i LTE loc.iEnd; loc.i++)
			if (typeOf(this.sql.froms[loc.i]) EQ "cfrel.nodes.SubQuery")
				arguments.stack = this.sql.froms[loc.i].subject.getParameterColumns(arguments.stack);
				
		// stack on parameters from join subqueries
		loc.iEnd = ArrayLen(this.sql.joins);
		for (loc.i = 1; loc.i LTE loc.iEnd; loc.i++)
			if (typeOf(this.sql.joins[loc.i].table) EQ "cfrel.nodes.SubQuery")
				arguments.stack = this.sql.joins[loc.i].table.subject.getParameterColumns(arguments.stack);
		
		// stack on join parameter columns
		loc.iEnd = ArrayLen(this.sql.joinParameterColumns);
		for (loc.i = 1; loc.i LTE loc.iEnd; loc.i++)
			ArrayAppend(arguments.stack, this.sql.joinParameterColumns[loc.i]);
		
		// stack on where parameter columns
		loc.iEnd = ArrayLen(this.sql.whereParameterColumns);
		for (loc.i = 1; loc.i LTE loc.iEnd; loc.i++)
			ArrayAppend(arguments.stack, this.sql.whereParameterColumns[loc.i]);
		
		// stack on having parameter columns
		loc.iEnd = ArrayLen(this.sql.havingParameterColumns);
		for (loc.i = 1; loc.i LTE loc.iEnd; loc.i++)
			ArrayAppend(arguments.stack, this.sql.havingParameterColumns[loc.i]);
			
		return arguments.stack;
	</cfscript>
</cffunction>

<cffunction name="getParameterColumnTypes" returntype="array" access="public" hint="Return array of all columns types used as parameters">
	<cfargument name="stack" type="array" default="#[]#" />
	<cfscript>
		var loc = {};
			
		// stack on parameters from subqueries
		loc.iEnd = ArrayLen(this.sql.froms);
		for (loc.i = 1; loc.i LTE loc.iEnd; loc.i++)
			if (typeOf(this.sql.froms[loc.i]) EQ "cfrel.nodes.SubQuery")
				arguments.stack = this.sql.froms[loc.i].subject.getParameterColumnTypes(arguments.stack);
				
		// stack on parameters from join subqueries
		loc.iEnd = ArrayLen(this.sql.joins);
		for (loc.i = 1; loc.i LTE loc.iEnd; loc.i++)
			if (typeOf(this.sql.joins[loc.i].table) EQ "cfrel.nodes.SubQuery")
				arguments.stack = this.sql.joins[loc.i].table.subject.getParameterColumnTypes(arguments.stack);
			
		// stack on join parameter columns
		loc.iEnd = ArrayLen(this.sql.joinParameterColumns);
		for (loc.i = 1; loc.i LTE loc.iEnd; loc.i++) {
			if (arrayLen(this.sql.joins) gte loc.i AND typeOf(this.sql.joins[loc.i].table) EQ "cfrel.nodes.SubQuery")
				arguments.stack = this.sql.joins[loc.i].table.subject.getParameters(arguments.stack);
			ArrayAppend(arguments.stack, this.mapper.columnDataType(this.sql.joinParameterColumns[loc.i]));
		}
		
		// stack on where parameter columns
		loc.iEnd = ArrayLen(this.sql.whereParameterColumns);
		for (loc.i = 1; loc.i LTE loc.iEnd; loc.i++) {
			if (variables.qoq)
				ArrayAppend(arguments.stack, _queryColumnDataType(this.sql.whereParameterColumns[loc.i]));
			else
				ArrayAppend(arguments.stack, this.mapper.columnDataType(this.sql.whereParameterColumns[loc.i]));
		}
		
		// stack on having parameter columns
		loc.iEnd = ArrayLen(this.sql.havingParameterColumns);
		for (loc.i = 1; loc.i LTE loc.iEnd; loc.i++)
			ArrayAppend(arguments.stack, this.mapper.columnDataType(this.sql.havingParameterColumns[loc.i]));
			
		return arguments.stack;
	</cfscript>
</cffunction>