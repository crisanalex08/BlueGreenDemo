var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

// Root endpoint exposes deployment metadata used during blue/green demos.
app.MapGet("/", () =>
{
	var version = Environment.GetEnvironmentVariable("VERSION") ?? "v1";
	var environment = Environment.GetEnvironmentVariable("ENVIRONMENT") ?? "blue";

	return Results.Ok(new
	{
		version,
		environment,
		status = "healthy",
		timestamp = DateTime.UtcNow.ToString("O")
	});
});

// Health endpoint can be forced to fail to demonstrate automated rollback.
app.MapGet("/health", () =>
{
	var failHealthcheck = Environment.GetEnvironmentVariable("FAIL_HEALTHCHECK") ?? "false";
	var shouldFail = string.Equals(failHealthcheck, "true", StringComparison.OrdinalIgnoreCase);

	return shouldFail
		? Results.Text("Unhealthy", statusCode: StatusCodes.Status500InternalServerError)
		: Results.Text("Healthy", statusCode: StatusCodes.Status200OK);
});

app.Run();
