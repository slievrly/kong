local DeclarativeConfig = require "kong.db.declarative_config"
local helpers = require "spec.helpers"

for _, strategy in helpers.each_strategy() do
  describe("declarative config #" .. strategy, function()
    local db
    lazy_setup(function()
      local _
      _, db = helpers.get_db_utils(strategy, {
        "plugins",
        "routes",
        "services"
      })
      assert(helpers.start_kong({
        database   = strategy,
      }))
    end)

    lazy_teardown(function()
      assert(helpers.stop_kong())
    end)

    before_each(function()
      db.plugins:truncate()
      db.routes:truncate()
      db.services:truncate()
    end)

    local service_def = {
      _tags = ngx.null,
      connect_timeout = 60000,
      created_at = 1549025889,
      host = "example.com",
      id = "3b9c2302-a610-4925-a7b9-25942309335d",
      name = "foo",
      path = ngx.null,
      port = 80,
      protocol = "https",
      read_timeout = 60000,
      retries = 5,
      updated_at = 1549025889,
      write_timeout = 60000
    }

    local route_def = {
      _tags = ngx.null,
      created_at = 1549025889,
      id = "eb88ccb8-274d-4e7e-b4cb-0d673a4fa93b",
      name = "bar",
      protocols = { "http", "https" },
      methods = ngx.null,
      hosts = { "example.com" },
      paths = ngx.null,
      regex_priority = 0,
      strip_path = true,
      preserve_host = false,
      snis = ngx.null,
      sources = ngx.null,
      destinations = ngx.null,
      service = { id = service_def.id },
    }


    describe("import", function()
      it("imports Services", function()
        assert(DeclarativeConfig.import(db, {
          services = {
           [service_def.id] = service_def,
          },
        }))

        local foo = assert(db.services:select_by_name("foo"))
        assert.equals(service_def.id, foo.id)
        assert.equals("example.com", foo.host)
        assert.equals("https", foo.protocol)
      end)

      it("imports Routes associated to Services", function()
        assert(DeclarativeConfig.import(db, {
          routes = {
            [route_def.id] = route_def,
          },
          services = {
           [service_def.id] = service_def,
          },
          upstreams = {}, targets = {}, consumers = {}, plugins = {}, acls = {}, keyauth_credentials = {}
        }))

        local bar = assert(db.routes:select_by_name("bar"))
        assert.equals(route_def.id, bar.id)
        assert.equals("example.com", bar.hosts[1])
        assert.same({ "http", "https" }, bar.protocols)
        assert.equals(service_def.id, bar.service.id)
      end)
    end)
  end)
end


