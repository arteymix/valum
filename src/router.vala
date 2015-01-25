using Gee;

namespace Valum {

	public const string APP_NAME = "Valum/0.1";

	public class Router {

		/**
		 * Registered types.
		 */
		public Map<string, string> types = new HashMap<string, string> ();

		/**
		 * Registered routes by HTTP method.
		 */
		private Map<string, Gee.List<Route>> routes = new HashMap<string, Gee.List> ();

		/**
		 * Stack of scope.
		 */
		private Gee.List<string> scopes = new ArrayList<string> ();

		public delegate void NestedRouter (Valum.Router app);

		public Router () {

			// initialize default types
			this.types["int"]    = "\\d+";
			this.types["string"] = "\\w+";
			this.types["any"]    = ".+";

			this.handler.connect ((req, res) => {
				res.status = 200;
				res.mime   = "text/html";
			});

			this.handler.connect_after ((req, res) => {
				res.message.response_body.complete ();
			});
		}

		//
		// HTTP Verbs
		//
		public new Route get (string rule, Route.RequestCallback cb) {
			return this.method ("GET", rule, cb);
		}

		public Route post (string rule, Route.RequestCallback cb) {
			return this.method ("POST", rule, cb);
		}

		public Route put (string rule, Route.RequestCallback cb) {
			return this.method ("PUT", rule, cb);
		}

		public Route delete (string rule, Route.RequestCallback cb) {
			return this.method ("DELETE", rule, cb);
		}

		public Route head (string rule, Route.RequestCallback cb) {
			return this.method ("HEAD", rule, cb);
		}

		public Route options(string rule, Route.RequestCallback cb) {
			return this.method ("OPTIONS", rule, cb);
		}

		public Route trace (string rule, Route.RequestCallback cb) {
			return this.method ("TRACE", rule, cb);
		}

		public Route connect (string rule, Route.RequestCallback cb) {
			return this.method ("CONNECT", rule, cb);
		}

		// http://tools.ietf.org/html/rfc5789
		public Route patch (string rule, Route.RequestCallback cb) {
			return this.method ("PATCH", rule, cb);
		}

		/**
		 * Bind a callback with a custom method.
         *
		 * Useful if you need to support a non-standard HTTP method, otherwise you
		 * should use the predefined methods.
		 *
		 * @param method HTTP method
		 * @param rule   rule
		 * @param cb     callback to be called on request matching the method and the
		 *               rule.
		 */
		public Route method (string method, string rule, Route.RequestCallback cb) {
			var full_rule = new StringBuilder ();

			// scope the route
			foreach (var scope in this.scopes) {
				full_rule.append ("/%s".printf (scope));
			}

			full_rule.append ("/%s".printf(rule));

			return this.route (method, new Route.from_rule (this, full_rule.str, cb));
		}

		/**
		 * Bind a callback with a custom method and regular expression.
         *
		 * It is recommended to declare the Regex using the RegexCompileFlags.OPTIMIZE
		 * flag as it will be used *very* often during the application process.
         *
		 * @param method HTTP method
		 * @param regex  regular expression matching the request path.
		 */
		public Route regex (string method, Regex regex, Route.RequestCallback cb) {
			return this.route (method, new Route (this, regex, cb));
		}

		/**
		 * Bind a callback with a custom method and route.
		 *
		 * @param method HTTP method
		 * @param route  an instance of Route defining the matching process and the
		 *               callback.
		 */
		private Route route (string method, Route route) {
			if (!this.routes.has_key(method)){
				this.routes[method] = new ArrayList<Route> ();
			}

			this.routes[method].add (route);

			return route;
		}

		//
		// Routing helpers
		//
		public void scope (string fragment, NestedRouter router) {
			this.scopes.add (fragment);
			router (this);
			this.scopes.remove_at (this.scopes.size - 1);
		}

		// handler code
		public virtual signal void handler (Request req, Response res) {

			message ("%s %s".printf (req.message.method, req.path));

			var routes = this.routes[req.message.method];

			foreach (var route in routes) {
				if (route.matches (req.path)) {

					// fire the route!
					route.fire (req, res);

					return;
				}
			}
		}

		// libsoup-based handler
		public void soup_handler (Soup.Server server,
				Soup.Message msg,
				string path,
				GLib.HashTable? query,
				Soup.ClientContext client) {

			var req = new Request (msg);
			var res = new Response (msg);

			this.handler (req, res);
		}
	}
}


