/**
 * Builds test suites and launch the GLib test framework.
 */
public int main (string[] args) {

	Test.init (ref args);

	Test.add_func ("/route/from_rule", test_route_from_rule);
	Test.add_func ("/route/from_rule/without_captures", test_route_from_rule_without_captures);
	Test.add_func ("/route/from_regex", test_route_from_regex);
	Test.add_func ("/route/from_regex/without_captures", test_route_from_regex_without_captures);
	Test.add_func ("/route/from_matcher", test_route_from_regex);
	Test.add_func ("/route/match", test_route_match);
	Test.add_func ("/route/match/not_matching", test_route_match_not_matching);
	Test.add_func ("/route/fire", test_route_match_not_matching);

	Test.add_func ("/view/push_string", test_view_push_string);
	Test.add_func ("/view/push_int", test_view_push_int);
	Test.add_func ("/view/push_float", test_view_push_float);

	return Test.run ();
}