"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[3],{914:e=>{e.exports=JSON.parse('{"functions":[{"name":"insert","desc":"Adds a Phase to the Pipeline, ordering it implicitly.\\r","params":[{"name":"phase","desc":"","lua_type":"Phase"}],"returns":[{"desc":"","lua_type":"Pipeline"}],"function_type":"method","source":{"line":114,"path":"src/Scheduler.luau"}},{"name":"insert","desc":"Adds a Phase to the Pipeline after another Phase, ordering it explicitly.\\r","params":[{"name":"phase","desc":"","lua_type":"Phase"},{"name":"after","desc":"","lua_type":"Phase"}],"returns":[{"desc":"","lua_type":"Pipeline"}],"function_type":"method","source":{"line":126,"path":"src/Scheduler.luau"}},{"name":"new","desc":"Creates a new Pipeline, with an optional name to use for debugging.\\nWhen no name is provided, the script and line number will be used.\\r","params":[{"name":"name","desc":"","lua_type":"string?"}],"returns":[],"function_type":"static","source":{"line":138,"path":"src/Scheduler.luau"}}],"properties":[{"name":"Startup","desc":"A Pipeline containing the `PreStartup`, `Startup`, and `PostStartup` phases.\\r","lua_type":"Pipeline","source":{"line":151,"path":"src/Scheduler.luau"}},{"name":"Main","desc":"A Pipeline containing the `First`, `PreUpdate`, `Update`, `PostUpdate`, and `Last` phases.\\r","lua_type":"Pipeline","source":{"line":160,"path":"src/Scheduler.luau"}}],"types":[],"name":"Pipeline","desc":"Pipelines represent a set of ordered Phases. Systems cannot be\\nassigned to Pipelines themselves, but rather to Phases within\\nthose Pipelines.\\r","source":{"line":101,"path":"src/Scheduler.luau"}}')}}]);