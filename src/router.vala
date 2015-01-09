using Gee;

namespace Valum {

	public const string APP_NAME = "Valum/0.1";

	public class Router {

		/**
		 * Registered types used to match route parameters.
         *
		 * A key is a type identifier (eg. int) and a value is the
		 * corresponding regular expression that matches that type (eg. \d+ for
		 * int).
		 */
		public Map<string, string> types = new HashMap<string, string> ();

		/**
		 * Registered routes by HTTP method.
		 */
		private Map<string, ArrayList<Route>> routes = new HashMap<string, ArrayList> ();

		/**
		 * Stack of scope.
		 */
		private Gee.List<string> scopes = new ArrayList<string> ();

		// signal called before a request execution starts
		public virtual signal void before_request (Request req, Response res) {
			res.status = 200;
			res.mime   = "text/html";
		}

		// signal called after a request has executed
		public virtual signal void after_request (Request req, Response res) {
			res.message.response_body.complete ();
		}

		// signal called if no route has matched the request
		public virtual signal void default_request (Request req, Response res) {
			res.status = 404;
			warning("could not match %s, fallback to default handler", req.path);
		}

		public delegate void NestedRouter(Valum.Router app);

		public Router() {

			// initialize default types
			this.types["int"]    = "\\d+";
			this.types["string"] = "\\w+";

#if (BENCHMARK)
			var timer  = new Timer();

			this.before_request.connect((req, res) => {
				timer.start();
			});

			this.after_request.connect((req, res) => {
				timer.stop();
				var elapsed = timer.elapsed();
				res.headers.append("X-Runtime", "%8.3fms".printf(elapsed * 1000));
				info("%s computed in %8.3fms", req.path, elapsed * 1000);
			});
#endif
		}

		//
		// HTTP Verbs
		//
		public new Route get(string rule, Route.RequestCallback cb) {
			return this.route("GET", rule, cb);
		}

		public Route post(string rule, Route.RequestCallback cb) {
			return this.route("POST", rule, cb);
		}

		public Route put(string rule, Route.RequestCallback cb) {
			return this.route("PUT", rule, cb);
		}

		public Route delete(string rule, Route.RequestCallback cb) {
			return this.route("DELETE", rule, cb);
		}

		public Route head(string rule, Route.RequestCallback cb) {
			return this.route("HEAD", rule, cb);
		}

		public Route options(string rule, Route.RequestCallback cb) {
			return this.route("OPTIONS", rule, cb);
		}

		public Route trace(string rule, Route.RequestCallback cb) {
			return this.route("TRACE", rule, cb);
		}

		public Route connect(string rule, Route.RequestCallback cb) {
			return this.route("CONNECT", rule, cb);
		}

		// http://tools.ietf.org/html/rfc5789
		public Route patch(string rule, Route.RequestCallback cb) {
			return this.route("PATCH", rule, cb);
		}

		/**
		 * Like a scope, but does not push a fragment on the scope stack.
         *
		 * This is useful if you want to isolate a part of your application
		 */
		public void closure (NestedRouter router) {
			router (this);
		}

		//
		// Routing helpers
		//
		public void scope (string fragment, NestedRouter router) {
			this.scopes.add (fragment);
			router (this);
			this.scopes.remove_at (this.scopes.size - 1);
		}

		//
		// Routing and request handling machinery
		//
		private Route route (string method, string rule, Route.RequestCallback cb) {
			var full_rule = new StringBuilder ();

			// scope the route
			foreach (var scope in this.scopes)
			{
				full_rule.append ("/%s".printf (scope));
			}

			full_rule.append ("/%s".printf(rule));

			if (!this.routes.has_key(method)){
				this.routes[method] = new ArrayList<Route> ();
			}

			var route = new Route.from_rule (this, full_rule.str, cb);

			// register the route for the given method
			this.routes[method].add (route);

			return route;
		}

		// Handler code
		public void request_handler (Soup.Server server,
				Soup.Message msg,
				string path,
				GLib.HashTable? query,
				Soup.ClientContext client) {

			var req = new Request(msg);
			var res = new Response(msg);

			this.before_request (req, res);

			var routes = this.routes[msg.method];

			foreach (var route in routes) {
				if (route.matches(path)) {

					// fire the route!
					route.fire(req, res);

					this.after_request (req, res);

					return;
				}
			}

			// No route has matched
			this.default_request (req, res);

			this.after_request (req, res);
		}
	}

}


