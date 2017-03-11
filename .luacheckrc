globals = {'ivar2', 'say', 'reply', 'setfenv',}
unused_args = false
std = "lua51"
files["spec"] = {
	std = "+busted";
	new_globals = {
		"TEST_TIMEOUT";
		"assert_loop";
	};
}
