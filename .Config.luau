--!strict

return {
	Logger = {
		IgnoreFramework = false :: boolean;
		Level = "DEBUG" :: ("DEBUG"|"INFO"|"WARN"|"ERROR");
		ShowInGame = false;
	},

	Net = {
		DefaultRateLimit = { maxEntrance = 200, interval = 2 };
	};

	Framework = {
		Debug = "STUDIO" :: (boolean | "STUDIO");
	};

	Errors = {
		HaltOnInitFailure = false;
		HaltOnStartFailure = false;
	};
}
