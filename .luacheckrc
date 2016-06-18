globals = {'ivar2', 'say', 'reply'}
unused_args = false
std = "min"
files["spec"] = {
	std = "+busted";
	new_globals = {
		"TEST_TIMEOUT";
		"assert_loop";
	};
}
