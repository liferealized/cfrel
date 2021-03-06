<cfcomponent extends="tests.TestCase" output="false">
	
	<!--- TODO: Improve testing. Verify SQL trees instead of visit() return value. Improve comments --->
	<cffunction name="setup" returntype="void" access="public">
		<cfscript>
			super.setup();
			variables.cfc = "src.Relation";
			variables.datasourceRel = new(datasource="cfrel").select("id,username,password").from("users");
			variables.sqlVisitor = CreateObject("component", "src.visitors.Sql").init();
		</cfscript>
	</cffunction>
	
	<cffunction name="visit" returntype="any" access="private">
		<cfargument name="obj" type="any" required="true" />
		<cfreturn variables.sqlVisitor.visit(arguments.obj) />
	</cffunction>
	
	<cffunction name="testInit" returntype="void" access="public">
		<cfscript>
			var loc = {};
			
			// init and count public variables
			loc.obj = new(init=false);
			loc.varCount1 = StructCount(loc.obj);
			loc.instance = loc.obj.init();
			loc.varCount2 = StructCount(loc.instance);
			
			// make sure init modifies instance, not creating a new one
			assertIsTypeOf(loc.instance, "src.Relation");
			assertSame(loc.obj, loc.instance, "init() should return same instance");
			assertTrue(loc.varCount2 GT loc.varCount1, "init() should define private variables");
		</cfscript>
	</cffunction>
	
	<cffunction name="testInitWithOptions" returntype="void" access="public">
		<cfscript>
			var loc = {};
			
			// create a new item with some options
			loc.model = {};
			loc.instance = new(init=false).init(datasource="test", visitor="SqlServer", model=loc.model);
			
			// make sure datasource and visitor were correctly set
			assertEquals("test", loc.instance.datasource, "Datasource should be set through constructor");
			assertIsTypeOf(loc.instance.visitor, "src.visitors.SqlServer");
			assertSame(loc.model, loc.instance.model);
		</cfscript>
	</cffunction>
	
	<cffunction name="testNew" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.factory = new(init=false);
			loc.instance = loc.factory.new();
			assertIsTypeOf(loc.instance, "src.Relation");
			assertNotSame(loc.instance, loc.factory, "new() should create a new instance");
		</cfscript>
	</cffunction>
	
	<cffunction name="testClone" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.instance = new(datasource="cfrel");
			loc.clone1 = injectInspector(loc.instance.clone());
			loc.clone1.select("id").from("users").exec();
			loc.clone2 = injectInspector(loc.clone1.clone());
			
			// get private scopes
			loc.private1 = loc.clone1._inspect();
			loc.private2 = loc.clone2._inspect();
			
			// make sure that call returns a different relation object
			assertIsTypeOf(loc.clone1, "src.Relation");
			assertNotSame(loc.clone1, loc.instance, "clone() should return copy of object, not same one");
			assertNotSame(loc.clone1, loc.clone2);
			assertNotSame(loc.clone1.sql, loc.instance.sql, "clone() should copy the sql struct, not reference it");
			assertNotSame(loc.clone1.sql, loc.clone2.sql);
			assertEquals(loc.clone1.datasource, loc.clone2.datasource);
			assertTrue(IsQuery(loc.private1.cache.query));
			assertFalse(StructKeyExists(loc.private2.cache, "query"));
		</cfscript>
	</cffunction>
	
	<cffunction name="testAutoClone" returntype="void" access="public">
		<cfscript>
			var instance = datasourceRel.clone().exec();
			var key = "";
			var loc = {};
			
			// call each of the basic chainable methods
			loc.select = instance.select("a");
			loc.distinct = instance.distinct();
			loc.from = instance.from("users");
			loc.join = instance.join("posts", "post_user_id = user_id");
			loc.group = instance.group("a");
			loc.having = instance.having("a > ?", [0]);
			loc.order = instance.order("a ASC");
			loc.limit = instance.limit(5);
			loc.offset = instance.offset(10);
			loc.paginate = instance.paginate(1, 5);
			
			// assert that each return is not the original object and has an empty query
			for (key in loc) {
				injectInspector(loc[key]);
				assertNotSame(instance, loc[key], "Operation #key#() should auto-clone");
				assertEquals(0, StructCount(loc[key]._inspect().cache));
			}
		</cfscript>
	</cffunction>
	
	<cffunction name="testCallsAreChainable" returntype="void" access="public">
		<cfscript>
			var instance = new();
			var key = "";
			var loc = {};
			
			// call each of the basic chainable methods
			loc.select = instance.select("a");
			loc.distinct = instance.distinct();
			loc.from = instance.from("users");
			loc.join = instance.join("posts", "post_user_id = user_id");
			loc.where = instance.where(a=5);
			loc.group = instance.group("a");
			loc.having = instance.having("a > ?", [0]);
			loc.order = instance.order("a ASC");
			loc.limit = instance.limit(5);
			loc.offset = instance.offset(10);
			loc.paginate = instance.paginate(1, 5);
			
			// chain each call together for further testing
			loc.multiple = instance.select("b").distinct().from("posts").join("authors", "post_id = author_id").where(b=10).group("b").having("b >= 10").order("b DESC").limit(2).offset(8).paginate(3, 10);
			
			// assert that each return is still the same object
			for (key in loc)
				assertSame(instance, loc[key]);
		</cfscript>
	</cffunction>
	
	<cffunction name="testSelectSyntax" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.testVal = ListToArray("a,b,c");
			
			// run SELECT in various ways
			loc.instance1 = new().select("*");
			loc.instance2 = new().select("a,b,c");
			loc.instance3 = new().select("a","b","c");
			
			// make sure nodes were added and evaluate to input strings
			assertEquals("cfrel.nodes.Wildcard", typeOf(loc.instance1.sql.select[1]));
			assertEquals("cfrel.nodes.Column", typeOf(loc.instance2.sql.select[1]));
			assertEquals("cfrel.nodes.Column", typeOf(loc.instance2.sql.select[2]));
			assertEquals("cfrel.nodes.Column", typeOf(loc.instance2.sql.select[3]));
			assertEquals("cfrel.nodes.Column", typeOf(loc.instance3.sql.select[1]));
			assertEquals("cfrel.nodes.Column", typeOf(loc.instance3.sql.select[2]));
			assertEquals("cfrel.nodes.Column", typeOf(loc.instance3.sql.select[3]));
			assertEquals(["*"], visit(loc.instance1.sql.select));
			assertEquals(loc.testVal, visit(loc.instance2.sql.select));
			assertEquals(loc.testVal, visit(loc.instance3.sql.select));
		</cfscript>
	</cffunction>
	
	<cffunction name="testSelectAppend" returntype="void" access="public">
		<cfscript>
			var loc = {};
			
			// run chained selects to confirm appending with both syntaxes
			loc.instance = new().select("a,b").select("c","d").select("e,f");
			
			// make sure items were stacked/appended
			assertEquals(ListToArray("a,b,c,d,e,f"), visit(loc.instance.sql.select), "SELECT should append additional selects");
		</cfscript>
	</cffunction>
	
	<cffunction name="testSelectSubquery" returntype="void" access="public">
		<cfscript>
			var loc = {};
			
			// build a relation with another relation in the select
			loc.rel1 = new().select("MIN(price)").from("prices").where("id = items.id");
			loc.rel2 = new().select("id,name", sqlAlias(subject=loc.rel1, alias="lowestPrice")).from("items").order("lowestPrice ASC");
			
			// test that the subquery gets wrapped in parens
			loc.sql = "SELECT id, name, (SELECT MIN(price) FROM prices WHERE id = items.id) AS lowestPrice FROM items ORDER BY lowestPrice ASC";
			assertEquals(loc.sql, loc.rel2.toSql());
		</cfscript>
	</cffunction>
	
	<cffunction name="testEmptySelect" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.pass = false;
			loc.instance = new();
			
			// confirm that exception is thrown
			try {
				loc.instance.select();
			} catch (custom_type e) {
				loc.pass = true;
			}
			
			assertTrue(loc.pass, "Empty parameters to SELECT should throw an error");
		</cfscript>
	</cffunction>
	
	<cffunction name="testSelectCaseStatement" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.s1 = "ISNULL(SUM(CASE WHEN ledger.type = 'debit' THEN -amount ELSE amount END), 0) AS total";
			loc.s2 = "ISNULL(SUM(CASE ledger.type WHEN 'debit' THEN -amount ELSE amount END), 0) AS total";
			loc.s3 = "ISNULL(SUM(CASE ledger.type WHEN 'debit' THEN -amount WHEN 'credit' THEN amount - 200 END), 0) AS total";
			assertEquals("SELECT #loc.s1#", new().select(loc.s1).toSql());
			assertEquals("SELECT #loc.s2#", new().select(loc.s2).toSql());
			assertEquals("SELECT #loc.s3#", new().select(loc.s3).toSql());
		</cfscript>
	</cffunction>
	
	<cffunction name="testSelectDecimals" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.s1 = "0.75";
			loc.s2 = ".75";
			loc.s3 = "75";
			assertEquals("SELECT #loc.s1#", new().select(loc.s1).toSql());
			assertEquals("SELECT #loc.s2#", new().select(loc.s2).toSql());
			assertEquals("SELECT #loc.s3#", new().select(loc.s3).toSql());
		</cfscript>
	</cffunction>
	
	<cffunction name="testDistinct" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.instance = new().distinct().distinct(); // yes, call twice
			assertEquals("DISTINCT", loc.instance.sql.selectFlags[1], "distinct() should set DISTINCT flag");
			assertEquals(1, ArrayLen(loc.instance.sql.selectFlags), "DISTINCT should only be set once");
		</cfscript>
	</cffunction>
	
	<cffunction name="testCountDistinct" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.a = new().select("COUNT(DISTINCT *)").from("a");
			loc.b = new().select("COUNT(DISTINCT a)").from("b");
			loc.c = new().select("COUNT(a)").from("b");
			assertEquals("SELECT COUNT(DISTINCT *) FROM a", loc.a.toSql());
			assertEquals("SELECT COUNT(DISTINCT a) FROM b", loc.b.toSql());
			assertEquals("SELECT COUNT(a) FROM b", loc.c.toSql());
		</cfscript>
	</cffunction>
	
	<cffunction name="testEmptyFrom" returntype="void" access="public">
		<cfscript>
			assertEquals(0, ArrayLen(new().sql.froms), "FROM clause should not be set initially");
		</cfscript>
	</cffunction>
	
	<cffunction name="testFromWithString" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.instance = new().from("users");
			assertEquals("users", loc.instance.sql.froms[1].table, "FROM clause should be set to passed value");
		</cfscript>
	</cffunction>
	
	<cffunction name="testFromWithRelation" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.instance = new();
			loc.instance2 = new().from(loc.instance);
			assertEquals("cfrel.nodes.SubQuery", typeOf(loc.instance2.sql.froms[1]));
			assertSame(loc.instance, loc.instance2.sql.froms[1].subject, "FROM clause should contain passed relation");
		</cfscript>
	</cffunction>
	
	<cffunction name="testFromWithQuery" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.query = QueryNew('');
			loc.instance = new();
			loc.private = loc.instance._inspect();
			assertFalse(loc.private.qoq, "QOQ should be false initially");
			assertIsTypeOf(loc.instance.visitor, "src.visitors.Sql");
			loc.instance.from(loc.query);
			assertSame(loc.query, loc.instance.sql.froms[1], "FROM clause should be set to passed query");
			assertTrue(loc.private.qoq, "QOQ should be true after using from(query)");
			assertIsTypeOf(loc.instance.visitor, "src.visitors.QueryOfQuery");
		</cfscript>
	</cffunction>
	
	<cffunction name="testFromWithInvalidObject" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.pass = false;
			try {
				new().from(StructNew());
			} catch (custom_type e) {
				loc.pass = true;
			}
			assertTrue(loc.pass, "from() should throw exception when given invalid object");
		</cfscript>
	</cffunction>
	
	<cffunction name="testJoinTypes" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.instance = new().from("tableA")
				.join("tableB", "a = b", [], 'inner')
				.join("tableC", "b = c", [], 'outer')
				.join("tableD", false, [], 'cross')
				.join("tableE", false, [], 'natural');
			loc.expected = "SELECT * FROM tableA JOIN tableB ON a = b LEFT JOIN tableC ON b = c CROSS JOIN tableD NATURAL JOIN tableE";
			assertEquals(4, ArrayLen(loc.instance.sql.joins));
			assertEquals(loc.expected, loc.instance.toSql());
		</cfscript>
	</cffunction>
	
	<cffunction name="testSingleWhere" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.instance = new().where("1 = 1");
			assertEquals(1, ArrayLen(loc.instance.sql.wheres));
			assertEquals(0, ArrayLen(loc.instance.sql.whereParameters));
			assertEquals("cfrel.nodes.BinaryOp", typeOf(loc.instance.sql.wheres[1]));
			assertEquals("1 = 1", visit(loc.instance.sql.wheres[1]));
		</cfscript>
	</cffunction>
	
	<cffunction name="testAppendWhere" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.instance = new().where("1 = 1").where("2 = 2");
			assertEquals("1 = 1", visit(loc.instance.sql.wheres[1]));
			assertEquals("2 = 2", visit(loc.instance.sql.wheres[2]));
		</cfscript>
	</cffunction>
	
	<cffunction name="testWhereWithParameters" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.whereClause = "id = ? OR name = '?' OR role IN (?)";
			loc.whereParameters = [50, "admin", [1,2,3]];
			loc.instance = new().where(loc.whereClause, loc.whereParameters);
			assertEquals(loc.whereClause, visit(loc.instance.sql.wheres[1]), "where() should set the passed condition");
			assertEquals(loc.whereParameters, visit(loc.instance.sql.whereParameters), "where() should set parameters in correct order");
		</cfscript>
	</cffunction>
	
	<cffunction name="testWhereParameterCount" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.pass = false;
			loc.instance = new();
			try {
				loc.instance.where("id = ? OR name = '?'", [2]);
			} catch (custom_type e) {
				loc.pass = true;
			}
			assertTrue(loc.pass, "where() should throw an error if wrong count of parameters is passed");
		</cfscript>
	</cffunction>
	
	<cffunction name="testWhereWithNamedArguments" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.instance = new().where(a=45, b="BBB", c=[1,2,3]);
			assertEquals(["a = ?", "b = ?", "c IN (?)"], visit(loc.instance.sql.wheres), "Named arguments should be in WHERE clause");
			assertEquals([45, "BBB", [1,2,3]], loc.instance.sql.whereParameters, "Parameters should be set and in correct order");
		</cfscript>
	</cffunction>
	
	<cffunction name="testWhereNotLike" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.where = "a NOT LIKE '[0-9]%'";
			assertEquals("SELECT * FROM tableA WHERE #loc.where#", new().from("tableA").where(loc.where).toSql());
		</cfscript>
	</cffunction>
	
	<cffunction name="testGroupSyntax" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.testVal = ListToArray("a,b,c");
			
			// run GROUP in various ways
			loc.instance1 = new().group("a,b,c");
			loc.instance2 = new().group("a","b","c");
			
			// make sure the items were added
			assertEquals(loc.testVal, visit(loc.instance1.sql.groups));
			assertEquals(loc.testVal, visit(loc.instance2.sql.groups));
		</cfscript>
	</cffunction>
	
	<cffunction name="testGroupAppend" returntype="void" access="public">
		<cfscript>
			var loc = {};
			
			// run chained groups to confirm appending with both syntaxes
			loc.instance = new().group("a,b").group("c","d").group("e,f");
			
			// make sure items were stacked/appended
			assertEquals(ListToArray("a,b,c,d,e,f"), visit(loc.instance.sql.groups));
		</cfscript>
	</cffunction>
	
	<cffunction name="testEmptyGroup" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.pass = false;
			loc.instance = new();
			
			// confirm that exception is thrown
			try {
				loc.instance.group();
			} catch (custom_type e) {
				loc.pass = true;
			}
			
			assertTrue(loc.pass, "Empty parameters to GROUP should throw an error");
		</cfscript>
	</cffunction>
	
	<cffunction name="testSingleHaving" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.instance = new().having("a > 1");
			assertEquals(1, ArrayLen(loc.instance.sql.havings));
			assertEquals(0, ArrayLen(loc.instance.sql.havingParameters));
			assertEquals("cfrel.nodes.BinaryOp", typeOf(loc.instance.sql.havings[1]));
			assertEquals("a > 1", visit(loc.instance.sql.havings[1]));
		</cfscript>
	</cffunction>
	
	<cffunction name="testAppendHaving" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.instance = new().having("a > 1").having("b < 0");
			assertEquals("cfrel.nodes.BinaryOp", typeOf(loc.instance.sql.havings[2]));
			assertEquals("b < 0", sqlVisitor.visit(loc.instance.sql.havings[2]), "having() should append the second condition");
		</cfscript>
	</cffunction>
	
	<cffunction name="testHavingWithParameters" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.havingClause = "id = ? OR name = '?' OR role IN (?)";
			loc.havingParameters = [50, "admin", [1,2,3]];
			loc.instance = new().having(loc.havingClause, loc.havingParameters);
			assertEquals(loc.havingClause, visit(loc.instance.sql.havings[1]), "having() should set the passed condition");
			assertEquals(loc.havingParameters, visit(loc.instance.sql.havingParameters), "having() should set parameters in correct order");
		</cfscript>
	</cffunction>
	
	<cffunction name="testHavingParameterCount" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.pass = false;
			loc.instance = new();
			try {
				loc.instance.having("id = ? OR name = '?'", [2]);
			} catch (custom_type e) {
				loc.pass = true;
			}
			assertTrue(loc.pass, "having() should throw an error if wrong count of parameters is passed");
		</cfscript>
	</cffunction>
	
	<cffunction name="testHavingWithNamedArguments" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.instance = new().having(a=45, b="BBB", c=[1,2,3]);
			assertEquals(["a = ?", "b = ?", "c IN (?)"], visit(loc.instance.sql.havings), "Named arguments should be in HAVING clause");
			assertEquals([45, "BBB", [1,2,3]], loc.instance.sql.havingParameters, "Parameters should be set and in correct order");
		</cfscript>
	</cffunction>
	
	<cffunction name="testOrderSyntax" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.testVal = ListToArray("a ASC,b DESC,c ASC");
			
			// run ORDER in various ways
			loc.instance1 = new().order("a ASC,b DESC,c");
			loc.instance2 = new().order("a ASC","b DESC","c");
			
			// make sure the items were added
			assertEquals(loc.testVal, visit(loc.instance1.sql.orders), "ORDER BY clause should accept a list of columns");
			assertEquals(loc.testVal, visit(loc.instance2.sql.orders), "ORDER BY clause should accept a columns as multiple arguments");
		</cfscript>
	</cffunction>
	
	<cffunction name="testOrderAppend" returntype="void" access="public">
		<cfscript>
			var loc = {};
			
			// run chained orders to confirm appending with both syntaxes
			loc.instance = new().order("a,b").order("c","d").order("e,f");
			
			// make sure items were stacked/appended
			assertEquals(ListToArray("a ASC,b ASC,c ASC,d ASC,e ASC,f ASC"), visit(loc.instance.sql.orders));
		</cfscript>
	</cffunction>
	
	<cffunction name="testEmptyOrder" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.pass = false;
			loc.instance = new();
			
			// confirm that exception is thrown
			try {
				loc.instance.order();
			} catch (custom_type e) {
				loc.pass = true;
			}
			
			assertTrue(loc.pass, "Empty parameters to ORDER should throw an error");
		</cfscript>
	</cffunction>
	
	<cffunction name="testLimit" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.instance = new().limit(31);
			assertTrue(StructKeyExists(loc.instance.sql, "limit"), "LIMIT should be set in SQL");
			assertEquals(31, loc.instance.sql.limit, "LIMIT should be equal to value set");
		</cfscript>
	</cffunction>
	
	<cffunction name="testOffset" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.instance = new().offset(15);
			assertTrue(StructKeyExists(loc.instance.sql, "offset"), "OFFSET should be set in SQL");
			assertEquals(15, loc.instance.sql.offset, "OFFSET should be equal to value set");
		</cfscript>
	</cffunction>
	
	<cffunction name="testIsPaged" returntype="void" access="public">
		<cfscript>
			var loc = {};
			
			// test that paged flag is off by default
			loc.instance = new();
			assertFalse(loc.instance._inspect().paged);
			assertEquals(loc.instance._inspect().paged, loc.instance.isPaged());
			
			// test that paged flag is off with manual limit and offset
			loc.instance.limit(5).offset(0);
			assertFalse(loc.instance._inspect().paged);
			assertEquals(loc.instance._inspect().paged, loc.instance.isPaged());
			
			// test that flag is set to true once paged
			loc.instance.paginate(1, 1);
			assertTrue(loc.instance._inspect().paged);
			assertEquals(loc.instance._inspect().paged, loc.instance.isPaged());
		</cfscript>
	</cffunction>
	
	<cffunction name="testPaginateSyntax" returntype="void" access="public">
		<cfscript>
			var loc = {};
			
			// an example: 5th page of 10 per page
			loc.instance = new().paginate(5, 10);
			
			// make sure proper values were set in LIMIT and OFFSET clauses
			assertTrue(StructKeyExists(loc.instance.sql, "limit"), "LIMIT should be set in SQL");
			assertTrue(StructKeyExists(loc.instance.sql, "offset"), "OFFSET should be set in SQL");
			assertEquals(10, loc.instance.sql.limit, "LIMIT should be equal to value set");
			assertEquals(40, loc.instance.sql.offset, "OFFSET should equal (page - 1) * per-page");
			assertTrue(loc.instance.isPaged(), "Paged flag should be set");
		</cfscript>
	</cffunction>
	
	<cffunction name="testPaginateBounds" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.instance = new();
			loc.pass1 = false;
			loc.pass2 = false;
			
			// test <1 value for page
			try {
				loc.instance.paginate(0, 5);
			} catch (custom_type e) {
				loc.pass1 = true;
			}
			
			// test <1 value for perPage
			try {
				loc.instance.paginate(1, 0);
			} catch (custom_type e) {
				loc.pass2 = true;
			}
			
			// make sure errors are thrown
			assertTrue(loc.pass1, "paginate() should throw error when page < 1");
			assertTrue(loc.pass1, "paginate() should throw error when perPage < 1");
		</cfscript>
	</cffunction>
	
	<cffunction name="testClearing" returntype="void" access="public">
		<cfscript>
			var loc = {};
			
			// set up options
			loc.r1 = new().select("a,b,c").clearSelect();
			loc.r2 = new().where("a = ?", [5]).clearWhere();
			loc.r3 = new().group("a,b,c").clearGroup();
			loc.r4 = new().having("COUNT(b) < ?", [10]).clearHaving();
			loc.r5 = new().order("a ASC,b ASC,c DESC").clearOrder();
			
			// make sure proper values were set in LIMIT and OFFSET clauses
			assertEquals(0, ArrayLen(loc.r1.sql.select));
			assertEquals(0, ArrayLen(loc.r2.sql.wheres));
			assertEquals(0, ArrayLen(loc.r2.sql.whereParameters));
			assertEquals(0, ArrayLen(loc.r3.sql.groups));
			assertEquals(0, ArrayLen(loc.r4.sql.havings));
			assertEquals(0, ArrayLen(loc.r4.sql.havingParameters));
			assertEquals(0, ArrayLen(loc.r5.sql.orders));
		</cfscript>
	</cffunction>
	
	<cffunction name="testClearPagination" returntype="void" access="public">
		<cfscript>
			var loc = {};
			
			// call paginate
			loc.instance = new().paginate(5, 10);
			
			// and then clear pagination
			loc.instance.clearPagination();
			
			// make sure proper values were set in LIMIT and OFFSET clauses
			assertFalse(StructKeyExists(loc.instance.sql, "limit"), "LIMIT should not be set in SQL");
			assertFalse(StructKeyExists(loc.instance.sql, "offset"), "OFFSET should not be set in SQL");
			assertFalse(loc.instance.isPaged(), "Paged flag should not be set");
		</cfscript>
	</cffunction>
	
	<cffunction name="testColumnEscapeChars" returntype="void" access="public">
		<cfscript>
			var loc = {};
			
			// test variety of escape characters to make sure they are stripped by parse
			loc.instance = new().select("[a]").from("b").where('"a" > 5').order("`a` ASC");
			assertEquals("SELECT a FROM b WHERE a > 5 ORDER BY a ASC", loc.instance.toSql());
		</cfscript>
	</cffunction>
	
	<cffunction name="testSqlGeneration" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.visitor = CreateObject("component", "src.visitors.Sql").init();
			
			// generate a simple relation
			loc.instance = new().select("a").from("b").where("a > 5").order("a ASC").paginate(2, 15);
			
			// make sure visitor is being called
			assertEquals(loc.visitor.visit(loc.instance), loc.instance.toSql(), "toSql() should be calling Sql visitor for SQL generation");
		</cfscript>
	</cffunction>
	
	<cffunction name="testInterpolatedSqlGeneration" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.rel = new().select("'a?' AS a, 'b?' AS b").from("items")
				.where(a=1, b="test").where("c = 'test2'").where("d = ?", [6.523]);
			loc.sql = "SELECT 'a?' AS a, 'b?' AS b FROM items WHERE a = '1' AND b = 'test' AND c = 'test2' AND d = '6.523'";
			assertEquals(loc.sql, loc.rel.toSql(true));
		</cfscript>
	</cffunction>
	
	<cffunction name="testEmptyDatasource" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.pass = false;
			loc.rel = new().select(1);
			try {
				loc.rel.query();
			} catch (custom_type e) {
				loc.pass = true;
			}
			assertEquals("", loc.rel.datasource, "Datasource should be blank");
			assertTrue(loc.pass, "Exception should be thrown if query() is called with empty datasource");
		</cfscript>
	</cffunction>
	
	<cffunction name="testQuery" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.rel = injectInspector(datasourceRel.clone());
			loc.variables = loc.rel._inspect();
			loc.query1 = loc.rel.query();
			loc.query0 = loc.variables.cache.query;
			loc.query2 = loc.rel.query();
			assertTrue(loc.variables.executed, "Calling query() should set executed flag");
			assertTrue(IsQuery(loc.query1), "query() should return a recordset");
			assertSame(loc.query0, loc.query1, "query() should store query inside of the relation");
			assertSame(loc.query1, loc.query2, "Multiple calls to query() should return same recordset object");
		</cfscript>
	</cffunction>
	
	<cffunction name="testResult" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.rel = injectInspector(datasourceRel.clone());
			loc.variables = loc.rel._inspect();
			loc.result1 = loc.rel.result();
			loc.result0 = loc.variables.cache.result;
			loc.result2 = loc.rel.result();
			assertTrue(IsStruct(loc.result1), "result() should return query result data");
			assertSame(loc.result0, loc.result1, "result() should store result inside of the relation");
			assertSame(loc.result1, loc.result2, "Multiple calls to result() should return same result struct");
		</cfscript>
	</cffunction>
	
	<cffunction name="testStructs" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.rel = injectInspector(datasourceRel.clone());
			loc.variables = loc.rel._inspect();
			
			// call struct methods and read from cache
			loc.struct0 = loc.rel.struct(5);
			loc.struct1 = loc.variables.cache.flatStructs[5];
			loc.struct2 = loc.rel.struct(5);
			loc.struct3 = loc.rel.struct(2);
			loc.structs0 = loc.rel.structs();
			loc.structs1 = loc.variables.cache.flatStructs;
			loc.structs2 = loc.rel.structs();
			
			// test that return was created and cached
			assertTrue(loc.variables.executed);
			assertTrue(IsStruct(loc.struct0));
			assertSame(loc.struct0, loc.struct1);
			assertSame(loc.struct1, loc.struct2);
			assertNotSame(loc.struct0, loc.struct3);
			assertTrue(IsArray(loc.structs0));
			assertEquals(loc.structs0, loc.structs1);
			assertEquals(loc.structs1, loc.structs2);
			
			// test first() and last() functions
			assertSame(loc.rel.struct(1), loc.rel.first("struct"));
			assertSame(loc.rel.struct(loc.rel.recordCount()), loc.rel.last("struct"));
			
			// test all() function
			assertEquals(loc.structs1, loc.rel.all("structs"));
			
			// test get() function
			assertSame(loc.rel.struct(5), loc.rel.get(5, "struct"));
		</cfscript>
	</cffunction>
	
	<cffunction name="testObjects" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.rel = injectInspector(datasourceRel.clone());
			loc.variables = loc.rel._inspect();
			
			// call struct methods and read from cache
			loc.obj0 = loc.rel.object(3);
			loc.obj1 = loc.variables.cache.deepObjects[3];
			loc.obj2 = loc.rel.object(3);
			loc.obj3 = loc.rel.object(7);
			loc.objs0 = loc.rel.objects();
			loc.objs1 = loc.variables.cache.deepObjects;
			loc.objs2 = loc.rel.objects();
			
			// test that return was created and cached
			assertTrue(loc.variables.executed);
			assertTrue(IsObject(loc.obj1));
			assertSame(loc.obj0, loc.obj1);
			assertSame(loc.obj1, loc.obj2);
			assertNotSame(loc.obj0, loc.obj3);
			assertTrue(IsArray(loc.objs0));
			assertEquals(loc.objs0, loc.objs1);
			assertEquals(loc.objs1, loc.objs2);
			
			// test get() function
			assertSame(loc.rel.object(5), loc.rel.get(5));
			
			// test first() and last() functions
			assertSame(loc.rel.object(1), loc.rel.first());
			assertSame(loc.rel.object(loc.rel.recordCount()), loc.rel.last());
			
			// test all() function
			assertEquals(loc.objs1, loc.rel.all());
		</cfscript>
	</cffunction>
	
	<cffunction name="testCurr" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.rel = injectInspector(datasourceRel.clone());
			loc.variables = loc.rel._inspect();
			
			// make sure calling curr can load the first object
			// and lazy load execution properly
			loc.curr = loc.rel.curr();
			assertSame(loc.variables.cache.deepObjects[1], loc.curr);
		</cfscript>
	</cffunction>
	
	<cffunction name="testLooping" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.rel = injectInspector(datasourceRel.clone().limit(10));
			loc.variables = loc.rel._inspect();
			
			// test that current row is correctly initialized
			assertEquals(0, loc.variables.currentRow);
			loc.rel.exec();
			assertEquals(0, loc.variables.currentRow);
			
			// loop forwards
			loc.i = 0;
			while (loc.rel.next()) {
				
				// test current row advancement
				loc.i++;
				assertEquals(loc.i, loc.variables.currentRow);
				assertEquals(loc.i, loc.rel.currentRow());
				
				// test curr method against structs
				loc.curr = loc.rel.curr("struct");
				assertSame(loc.curr, loc.variables.cache.flatStructs[loc.i]);
				assertSame(loc.curr, loc.rel.struct(loc.i));
				
				// test curr method against objects
				loc.curr = loc.rel.curr("object");
				assertSame(loc.curr, loc.variables.cache.deepObjects[loc.i]);
				assertSame(loc.curr, loc.rel.object(loc.i));
			}
			
			// test that current row has reached the end
			assertEquals(11, loc.variables.currentRow);
			
			// loop backwards
			loc.i = 11;
			while (loc.rel.prev()) {
				
				// test current row advancement
				loc.i--;
				assertEquals(loc.i, loc.variables.currentRow);
				assertEquals(loc.i, loc.rel.currentRow());
				
				// test curr method against structs
				loc.curr = loc.rel.curr("struct");
				assertSame(loc.curr, loc.variables.cache.flatStructs[loc.i]);
				assertSame(loc.curr, loc.rel.struct(loc.i));
				
				// test curr method against objects
				loc.curr = loc.rel.curr("object");
				assertSame(loc.curr, loc.variables.cache.deepObjects[loc.i]);
				assertSame(loc.curr, loc.rel.object(loc.i));
			}
			
			// test that current row has reached the beginning
			assertEquals(0, loc.variables.currentRow);
			
			// test that accessing currentRow() sets internal counter to 1
			assertEquals(1, loc.rel.currentRow());
			assertEquals(1, loc.variables.currentRow);
		</cfscript>
	</cffunction>
	
	<cffunction name="testExecution" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.rel = injectInspector(datasourceRel.clone()).exec();
			loc.variables = loc.rel._inspect();
			loc.query1 = loc.variables.cache.query;
			assertTrue(IsQuery(loc.query1), "Execute should populate query field");
			loc.query2 = loc.rel.query();
			assertSame(loc.query1, loc.query2, "exec() should run and store the query for calls to query()");
		</cfscript>
	</cffunction>
	
	<cffunction name="testReload" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.rel = injectInspector(datasourceRel.clone());
			loc.query1 = loc.rel.query();
			loc.query2 = loc.rel.reload().query();
			assertTrue(IsQuery(loc.query2), "A query object should be returned");
			assertNotSame(loc.query1, loc.query2, "reload() should cause a new query to be executed");
		</cfscript>
	</cffunction>
	
	<cffunction name="testQueryOfQuery" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.rel = datasourceRel.clone();
			loc.query = loc.rel.query();
			loc.qoq1 = loc.rel.qoq();
			loc.qoq2 = loc.rel.where("1 = 1");
			assertNotSame(loc.rel, loc.qoq1);
			assertNotSame(loc.qoq1, loc.qoq2);
			assertSame(loc.query, loc.qoq1.sql.froms[1]);
			assertSame(loc.query, loc.qoq2.sql.froms[1]);
		</cfscript>
	</cffunction>
	
	<cffunction name="testQueryOfQueryJoins" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.pass = true;
			loc.q1 = QueryNew('id,yourId');
			loc.q2 = QueryNew('id,name');
			try {
				loc.rel = new().from(loc.q1).join(loc.q2, "query1.yourId = query2.id").query();
			} catch (Any e) {
				loc.pass = false;
			}
			assertTrue(loc.pass);
		</cfscript>
	</cffunction>
	
	<cffunction name="testQueryOfQueryModel" returntype="void" access="public">
		<cfscript>
			var loc = {};
			loc.model = {};
			loc.rel = new(datasource="cfrel", model=loc.model).from("users");
			assertSame(loc.model, loc.rel.qoq().model);
		</cfscript>
	</cffunction>
</cfcomponent>