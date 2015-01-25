using Gee;

namespace Valum {

	/**
	 * Route that matches Request path.
	 */
	public class Route : Object {

		/**
		 * Router that declared this route.
		 */
		private weak Router router;

		/**
		 * Rule that generated the regular expression.
         *
		 * This will be null if the Route has been initialized using a regular
		 * expression.
		 */
		private string? rule;

		/**
		 * Regular expression matching the Request path.
		 */
		private Regex regex;

		/**
		 * Remembers what names have been defined in the regular expression to
		 * build the Request params Map.
		 */
		private Gee.List<string> captures = new ArrayList<string> ();

		private unowned RequestCallback callback;

		public delegate void RequestCallback (Request req, Response res);

		/**
		 * Create a Route for a given callback using a Regex.
		 */
		public Route (Router router, Regex regex, RequestCallback callback) {
			this.router   = router;
			this.regex    = regex;
			this.callback = callback;

			// TODO: extract the capture from the Regex
		}

		/**
		 * Create a Route for a given callback from a rule.
         *
		 * A rule will compile down to Regex.
		 */
		public Route.from_rule (Router router, string rule, RequestCallback callback) {
			this.router   = router;
			this.rule     = rule;
			this.callback = callback;

			try {
				var route = new StringBuilder ("^");
				var param_regex = new Regex ("(<(?:\\w+:)?\\w+>)");
				var params = param_regex.split_full (rule);

				foreach (var p in params) {
					if(p[0] != '<') {
						// regular piece of route
						route.append (Regex.escape_string (p));
					} else {
						// extract parameter
						var cap  = p.slice (1, p.length - 1).split (":", 2);
						var type = cap.length == 1 ? "string" : cap[0];
						var key = cap.length == 1 ? cap[0] : cap[1];

						// TODO: support any type with a HashMap<string, string>
						var types = new HashMap<string, string> ();

						captures.add (key);
						route.append ("(?<%s>%s)".printf (key, this.router.types[type]));
					}
				}

				route.append ("$");
				message ("registered %s", route.str);

				this.regex = new Regex (route.str, RegexCompileFlags.OPTIMIZE);
			} catch(RegexError e) {
				error (e.message);
			}
		}

		private MatchInfo last_matchinfo;

		public bool matches (string path) {
			return this.regex.match (path, 0, out this.last_matchinfo);
		}

		/**
		 * Extract the Request parameters from URI and execute the route callack.
		 *
		 * Calling fire asssumes you have already called matches as it will reuse the
		 * MatchInfo object.
		 */
		public void fire (Request req, Response res) {
			foreach (var cap in captures) {
				req.params[cap] = this.last_matchinfo.fetch_named (cap);
			}

			this.callback (req, res);
		}

		/**
		 * Reverse the path of this route.
         *
		 * TODO: check Regex api if it is supported natively, otherwise use a
		 *       substitution regex.
		 */
		public string path_for (Map<string, string>? params = null) {
			return this.rule;
		}
	}
}
